// The one place that knows how the construction is reached.
//
// Two implementations behind the same call. `server` pipes to a native binary
// during development; `wasm` calls the compiled module in-page. Both take and
// return the identical wire format, because both are the same Haskell — see
// src/WebCore.hs. Swapping is the one-line change at the bottom of this file.

const serverBackend = {
  name: "server",
  async solve(wire) {
    const r = await fetch("/solve", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ wire }),
    });
    if (!r.ok) throw new Error(`backend HTTP ${r.status}`);
    return r.json();
  },
};

const wasmBackend = {
  name: "wasm",
  _hs: null,
  async _load() {
    if (this._hs) return this._hs;
    const { wasiImports } = await import("./wasi-shim.js");
    const bytes = await (await fetch("./crit.wasm")).arrayBuffer();
    const mod = await WebAssembly.compile(bytes);
    const { wasi, setMemory } = wasiImports(mod);
    const { default: ghcJsffi } = await import("../crit.js");
    const jsffi = {};
    const inst = await WebAssembly.instantiate(mod, {
      wasi_snapshot_preview1: wasi,
      ghc_wasm_jsffi: ghcJsffi(jsffi),
    });
    Object.assign(jsffi, inst.exports);
    setMemory(inst.exports.memory);
    inst.exports._initialize();          // reactor ABI: exactly once
    this._hs = inst.exports;
    return this._hs;
  },
  async solve(wire) {
    const hs = await this._load();
    // exported `sync`, so this is a string rather than a Promise
    return JSON.parse(hs.solve(wire));
  },
};

// FLINT, compiled to wasm by Emscripten. Separate module, separate memory: the
// boundary is decimal strings, one round trip per factorisation, which is why
// the split costs nothing. `?dev` skips it — the construction then runs on the
// squarefree part, which still satisfies both divisibilities but makes H
// irreducible only when f already is.
let flint = null;
export async function loadFlint() {
  if (new URLSearchParams(location.search).has("dev")) return null;
  if (flint !== null) return flint || null;
  try {
    const head = await fetch("./flint.wasm", { method: "HEAD" });
    if (!head.ok) { flint = false; return null; }
    const { default: createFlintModule } = await import("../flint.mjs");
    const m = await createFlintModule();
    flint = {
      // coefficients (decimal strings, low to high) -> irreducible factors
      factor(coeffs) {
        const inPtr = m.stringToNewUTF8(`${coeffs.length}  ${coeffs.join(" ")}`);
        const outPtr = m.ccall("crit_flint_factor", "number", ["number"], [inPtr]);
        m._free(inPtr);
        if (!outPtr) return [];
        const s = m.UTF8ToString(outPtr);
        m.ccall("crit_flint_free", null, ["number"], [outPtr]);
        const out = [];
        for (const line of s.split("\n")) {
          const w = line.trim().split(/\s+/).filter(Boolean);
          if (!w.length || w[0] === "c") continue;
          out.push(w.slice(2));          // drop exponent and length
        }
        return out;
      },
    };
    return flint;
  } catch { flint = false; return null; }
}

// Prefer wasm when the module is present; fall back to the dev server.
// ?backend=server or ?backend=wasm forces one.
export async function pickBackend() {
  const forced = new URLSearchParams(location.search).get("backend");
  if (forced === "server") return serverBackend;
  if (forced === "wasm") return wasmBackend;
  try {
    const head = await fetch("./crit.wasm", { method: "HEAD" });
    if (head.ok) return wasmBackend;
  } catch { /* not built yet */ }
  return serverBackend;
}
