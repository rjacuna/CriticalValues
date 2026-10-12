import { asset } from "../assets.js?v=engine-ready-1";

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
  _loading: null,
  _load(priority = "auto") {
    if (!this._loading) this._loading = this._instantiate(priority).catch(e => { this._loading = null; throw e; });
    return this._loading;
  },
  async _instantiate(priority) {
    const [shim, response] = await Promise.all([
      import("./wasi-shim.js"), asset("crit.wasm", undefined, priority),
    ]);
    const { wasiImports } = shim;
    if (!response.ok) throw new Error(`construction download: HTTP ${response.status}`);
    const mod = WebAssembly.compileStreaming && response.headers.get("Content-Type")?.split(";")[0] === "application/wasm"
      ? await WebAssembly.compileStreaming(response)
      : await WebAssembly.compile(await response.arrayBuffer());
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
const backendDevelopment = () => !location.hostname.endsWith(".github.io");
let flintLoading = null;
export function loadFlint(priority = "auto") {
  if (!flintLoading) flintLoading = instantiateFlint(priority);
  return flintLoading;
}
async function instantiateFlint(priority) {
  if (new URLSearchParams(location.search).has("dev")) return null;
  try {
    const [module, response] = await Promise.all([import("../flint.mjs"), asset("flint.wasm", undefined, priority)]);
    if (response.status === 404 && backendDevelopment()) return null;
    if (!response.ok) throw new Error(`FLINT download: HTTP ${response.status}`);
    const compiled = WebAssembly.compileStreaming && response.headers.get("Content-Type")?.split(";")[0] === "application/wasm"
      ? await WebAssembly.compileStreaming(response)
      : await WebAssembly.compile(await response.arrayBuffer());
    // This Emscripten build accepts instantiateWasm, but strips wasmBinary from
    // its incoming API. Supplying wasmBinary would silently download it twice.
    const m = await module.default({ instantiateWasm(imports, receive) {
      const instance = new WebAssembly.Instance(compiled, imports);
      receive(instance);
      return instance.exports;
    } });
    return {
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
  } catch (e) { flintLoading = null; throw e; }
}

// Prefer wasm when the module is present; fall back to the dev server.
// ?backend=server or ?backend=wasm forces one.
export async function pickBackend() {
  const forced = new URLSearchParams(location.search).get("backend");
  if (forced === "server") return serverBackend;
  if (forced === "wasm" || (!forced && location.hostname.endsWith(".github.io"))) return wasmBackend;
  try {
    const head = await fetch("./crit.wasm", { method: "HEAD" });
    if (head.ok) return wasmBackend;
  } catch { /* not built yet */ }
  return serverBackend;
}

// Shared by the UI and the build-time example generator. Start both downloads
// together; never publish a result without the same factorisation checks.
export async function solveWithFlint(backend, wire, report = () => {}) {
  report("loading the calculation engine…");
  const [, fl] = backend.name === "wasm"
    ? await warmup(backend)
    : await Promise.all([null, loadFlint("high")]);
  report("computing…");
  // Let the status paint before entering the synchronous Haskell calculation.
  await new Promise(resolve => setTimeout(resolve, 0));
  let d = await backend.solve(`${wire}|`);
  if (!d.ok) return d;
  if (fl && d.f && !d.degenerate) {
    report("factoring with FLINT…");
    const factors = fl.factor(d.f).filter(h => h.length > 1 && h[0] !== "0");
    if (factors.length) {
      const next = await backend.solve(`${d.f.join(",")}|${factors.map(h => h.join(",")).join(";")}`);
      if (!next.ok) throw new Error(next.error || "factor reconstruction failed");
      d = next;
    }
    report("verifying H is irreducible…");
    for (const s of d.setups || []) s.HIrred = fl.factor(s.H).length === 1;
  }
  return d;
}

let warmupPromise = null;
let engineStatus = "idle";
const engineListeners = new Set();
export function watchEngineStatus(listener) {
  engineListeners.add(listener);
  listener(engineStatus);
  return () => engineListeners.delete(listener);
}
function setEngineStatus(status) {
  engineStatus = status;
  for (const listener of engineListeners) listener(status);
}
export function warmup(backend) {
  if (backend.name !== "wasm") return Promise.resolve();
  if (!warmupPromise) {
    setEngineStatus("loading");
    // The initial view has already finished. There is no reason to give these
    // large transfers low priority while the visitor explores the examples.
    warmupPromise = Promise.all([backend._load("high"), loadFlint("high")])
      .then(modules => { setEngineStatus("ready"); return modules; })
      .catch(e => { warmupPromise = null; setEngineStatus("error"); throw e; });
  }
  return warmupPromise;
}
