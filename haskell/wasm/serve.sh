#!/usr/bin/env sh
# .wasm and ES modules need a real origin; file:// will not do.
cd "$(dirname "$0")" && exec python3 -m http.server 8000
