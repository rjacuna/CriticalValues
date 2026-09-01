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
    const { default: ghcJsffi } = await import("./crit.js");
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
    return JSON.parse(hs.solve(wire));
  },
};

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
