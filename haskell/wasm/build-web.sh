#!/usr/bin/env bash
# Build the construction as a wasm32-wasi reactor module.
#
# The library is base-only, so this is a plain ghc invocation -- no cabal, no
# dependency resolution, and no FLINT: factoring happens in the *other* wasm
# module, and the orchestrator hands the chosen h in. See app/Web.hs.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"

. ~/.ghc-wasm/env

wasm32-wasi-ghc -O2 -no-hs-main -optl-mexec-model=reactor \
  -i"$ROOT/src" -i"$ROOT/app" \
  -outputdir "${CRIT_WASM_BUILD:-$HOME/.cache/crit-wasm}/hs" \
  "$ROOT/app/Web.hs" -o "$HERE/crit.wasm"

# The post-link script parses the module and emits the JS side of the JSFFI.
"$(wasm32-wasi-ghc --print-libdir)/post-link.mjs" -i "$HERE/crit.wasm" -o "$HERE/crit.js"

echo "built $HERE/crit.wasm and crit.js"
