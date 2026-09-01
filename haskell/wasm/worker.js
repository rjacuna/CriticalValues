// The orchestrator.
//
// Two independent wasm instances with two linear memories:
//   * FLINT, built with Emscripten, factors f;
//   * the construction, built with GHC's wasm32-wasi backend, runs §2 and the
//     22 checks.
// They never share a pointer. Everything crosses as decimal strings, once per
// request, which is why the split costs nothing.
//
// Direction matters: the orchestrator calls *in* to Haskell, so no Haskell
// function has to await a JS promise, and the whole verified path stays pure
// and synchronous.
import { wasiImports } from "./wasi-shim.js";

let flint = null;     // Emscripten module
let hs = null;        // { solve }

async function loadFlint() {
  const { default: createFlintModule } = await import("./flint.mjs");
  const m = await createFlintModule();
  return {
    factor(polyStr) {
      const inPtr = m.stringToNewUTF8(polyStr);
      const outPtr = m.ccall("crit_flint_factor", "number", ["number"], [inPtr]);
      m._free(inPtr);
      if (!outPtr) return null;
      const s = m.UTF8ToString(outPtr);
      m.ccall("crit_flint_free", null, ["number"], [outPtr]);
      return s;
    },
  };
}

async function loadHaskell() {
  const bytes = await (await fetch("./crit.wasm")).arrayBuffer();
  const module = await WebAssembly.compile(bytes);
  const { wasi, setMemory } = wasiImports(module, {
    onStdout: (s) => postMessage({ type: "log", text: s }),
  });
  // The JSFFI imports are supplied by the post-link-generated module.
  const { default: ghcJsffi } = await import("./crit.js");
  const jsffi = {};
  const inst = await WebAssembly.instantiate(module, {
    wasi_snapshot_preview1: wasi,
    ghc_wasm_jsffi: ghcJsffi(jsffi),
  });
  Object.assign(jsffi, inst.exports);
  setMemory(inst.exports.memory);
  inst.exports._initialize();          // reactor ABI: exactly once, before anything
  return { solve: inst.exports.solve, exports: inst.exports };
}

// FLINT's wire format -> arrays of decimal strings
function parseFactors(s) {
  const out = [];
  for (const line of s.split("\n")) {
    const w = line.trim().split(/\s+/).filter(Boolean);
    if (!w.length || w[0] === "c") continue;
    out.push(w.slice(2));            // drop exponent and length
  }
  return out;
}

const toFlint = (cs) => `${cs.length}  ${cs.join(" ")}`;

self.onmessage = async (e) => {
  const { coeffs } = e.data;
  try {
    if (!hs) { postMessage({ type: "status", text: "loading construction…" }); hs = await loadHaskell(); }
    if (!flint) { postMessage({ type: "status", text: "loading FLINT…" }); flint = await loadFlint(); }

    postMessage({ type: "status", text: "factoring with FLINT…" });
    let hPart = "";
    const raw = flint.factor(toFlint(coeffs));
    if (raw) {
      // usable: nonconstant, nonzero constant term. Prefer the one FLINT lists
      // first among those, which is the lowest degree.
      const usable = parseFactors(raw).filter((f) => f.length > 1 && f[0] !== "0");
      if (usable.length) hPart = usable[0].join(",");
    }

    postMessage({ type: "status", text: "running the construction…" });
    const out = hs.solve(`${coeffs.join(",")}|${hPart}`);
    postMessage({ type: "result", data: JSON.parse(out), usedFlint: !!hPart });
  } catch (err) {
    postMessage({ type: "error", text: String(err && err.stack || err) });
  }
};
