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

## Prior art, and where this differs

`sagemathinc/wasm-flint` was the starting point and is not usable today. Beyond
being unmaintained, **two of its three downloads are dead**: `flintlib.org` no
longer serves `flint-2.7.1.tar.gz`, and it clones MPIR over `git://`, which
GitHub disabled in 2021.

[`fvirdia/wasm-flint`](https://github.com/fvirdia/wasm-flint) is a maintained
fork (last touched October 2025) that reached the same conclusions first, and
independently: drop the abandoned MPIR for **GMP 6.3.0**, use **MPFR 4.2.2**,
move to FLINT 3.x, and configure GMP with `--disable-assembly`, `--host=none`
and an explicit `CC_FOR_BUILD`. Anyone doing this from scratch should start
there rather than from the original.

Two deliberate differences here:

* **FLINT 3.4.0 rather than 3.3.1.** The fork pins 3.3.1. Using 3.4.0 means the
  browser runs the *same* factoriser the native benchmark links against, so the
  two are directly comparable — which is worth one extra patch (below).
* **`CC_FOR_BUILD=/usr/bin/clang` rather than `gcc`.** On this machine `gcc`
  resolves to Alire's GNAT toolchain, whose headers are broken on Darwin 25.

The fork additionally passes `--build i686-pc-linux-gnu ABI=standard` to GMP and
`--host wasm32` to FLINT; `--host=none --disable-assembly` works here, and the
result is verified below.

### The one patch the fork does not need

FLINT 3.4.0 added a BSD branch to `fprint_memory_usage` that calls `sysctl` and
`getpid`, reached whenever the build is neither `__linux__` nor `__APPLE__` —
which is exactly Emscripten. It also enables the whole block on `__unix__`,
which Emscripten defines, while not declaring `getrusage`.

**This is new in 3.4.0**: 3.3.1's `profiler.c` contains no `sysctl` at all,
which is why pinning 3.3.1 sidesteps it. The build script switches the profiler
off at its guard in `profiler.h` rather than patching inside it — it is
diagnostic code and never on the factoring path.

### Verified

`verify.mjs` factors a batch and checks that `content · ∏ factorᵉ` reconstructs
the input exactly, which needs no external oracle:

```
ok    X^12-1                 6 irreducible factor(s)
ok    (X-1)..(X-6)           6 irreducible factor(s)
ok    S3 (deg 8)             1 irreducible factor(s)
ok    big coeffs             1 irreducible factor(s)
ok    12*(X^2+1)^2*(X-3)     2 irreducible factor(s)
ok    huge                   1 irreducible factor(s)      -- 30-digit coefficient
ok    deg 20 sparse          1 irreducible factor(s)
```

## The WASI shim

`wasi-shim.js` rather than an npm dependency. It introspects the module's
declared imports and supplies every `wasi_snapshot_preview1` function GHC's RTS
asks for: `fd_write` (so a Haskell panic reaches the console rather than being
swallowed), `clock_time_get`, `random_get`, `proc_exit`, and the argv/environ
pair; everything else is stubbed to return success and logs when called.
