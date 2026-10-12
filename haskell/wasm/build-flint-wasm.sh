#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
FLINTELL="${FLINTELL_ROOT:-$HERE/../../../flintell}"
"$FLINTELL/wasm-flint/build.sh" "$HERE"
# The deployed client fetches its assets from web/.
cp "$HERE/flint.mjs" "$HERE/flint.wasm" "$HERE/../web/"

python3 "$HERE/asset-manifest.py"
