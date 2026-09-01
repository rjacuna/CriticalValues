# The browser build

Two independent WebAssembly modules, talking through JavaScript:

* **`flint.wasm`** — GMP 6.3.0 + MPFR 4.2.2 + FLINT 3.4.0, built with
  Emscripten. Factors `f`. `build-flint-wasm.sh`. 4.9 MB.
* **`crit.wasm`** — the construction and all 22 checks, built with GHC's
  `wasm32-wasi` backend as a reactor module. `build-web.sh`.

```sh
./build-flint-wasm.sh     # long: builds three C libraries
./build-web.sh            # short: the library is base-only
./serve.sh                # http://localhost:8000
```

## Measured

FLINT in wasm, under node, factoring four polynomials:

```
X^2 - 2               irreducible
X^4 - 1               (X-1)(X+1)(X^2+1)
X^12 - 1              six cyclotomic factors
Swinnerton-Dyer S3    irreducible
total: 9.9 ms
```

`X^12 - 1` is the input that times out the pure-Haskell Kronecker search at a
ten-second budget (`OPTIMIZATION.md` §5c). In the browser runtime it is part of
a ten-millisecond batch.

## Why two modules, and why it costs nothing

They use different ABIs — Emscripten and `wasm32-wasi` — so they are two
instances with two linear memories and no shared pointers. That would matter if
they exchanged pointers per operation. They don't: the boundary is one round
trip per request, with polynomials as decimal strings, so the marshalling is
amortised over an entire factorisation.

**Direction is the part that matters.** The orchestrator (`worker.js`) calls
*in* to Haskell, never the reverse. A Haskell-to-JS call would need an async
JSFFI import, which would turn `chooseFactor` into `IO` and propagate through
`setupOfFactor`, `setupExists` and `theorem1` — the whole verified path. Calling
in keeps all of it pure and synchronous, and `setupOfFactor` already takes `h`
as a parameter because it mirrors Lean's `setup_of_factor`. The split built to
follow the proof is exactly the delegation seam.

## Decimal strings, never JavaScript numbers

`g`'s coefficients routinely exceed `2^53` — 460 digits in one benchmark case.
A numeric boundary would round *silently*, with no exception and no `NaN`, and
would corrupt the inputs to the checks along with the answer, so the 22 booleans
would come back green on a wrong result. Every coefficient crosses as a decimal
string; the page parses to `BigInt` only for display.

## This is not `sagemathinc/wasm-flint`

That repo was the starting point and is not usable. Beyond being unmaintained
(three commits, no releases), **two of its three downloads are dead**:
`flintlib.org` no longer serves `flint-2.7.1.tar.gz`, and it clones MPIR over
`git://`, which GitHub disabled in 2021. Only its MPFR URL still resolves.

`build-flint-wasm.sh` therefore builds current sources, and GMP rather than the
abandoned MPIR. Using FLINT 3.4.0 has a side benefit: it is the same FLINT the
native benchmark links against, so the browser and the CLI run the same
factoriser and can be compared directly.

Two build notes, both host quirks rather than anything about wasm:

* GMP's `configure` refuses to run under a path containing an apostrophe, and
  this checkout lives under `Tomorrow's Talk`. The build tree therefore defaults
  to `~/.cache/crit-wasm`; override with `CRIT_WASM_BUILD`.
* GMP needs a *build-machine* compiler as well as the cross compiler.
  `emconfigure` points it at emsdk's clang, which cannot produce host binaries,
  so it is set to `/usr/bin/clang` explicitly — not `gcc`, which on this machine
  is Alire's GNAT toolchain with headers broken on Darwin 25 (see `../WEB.md`).

## The WASI shim

`wasi-shim.js` rather than an npm dependency. It introspects the module's
declared imports and supplies every `wasi_snapshot_preview1` function GHC's RTS
asks for: `fd_write` (so a Haskell panic reaches the console rather than being
swallowed), `clock_time_get`, `random_get`, `proc_exit`, and the argv/environ
pair; everything else is stubbed to return success and logs when called.
