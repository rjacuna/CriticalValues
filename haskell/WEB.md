# Compiling `crit` for the web — options and trade-offs

Written as a decision document, not a plan of record. Nothing here has been
built or installed; see "Toolchain cost", which is the only part that is
genuinely expensive.

**Short version.** Target `wasm32-wasi`, export a pure function through the
wasm JSFFI, and keep the UI in plain HTML. Both GHC web backends are tech
previews, so this is a "when you want it" recommendation rather than a
"production is waiting" one.

---

## 1. The landscape

Two backends now live *inside* GHC, both since 9.6:

| target | origin | state |
|---|---|---|
| `javascript-unknown-ghcjs` | GHCJS, absorbed in-tree | tech preview; **not** in the official bindist, needs a cross-compiler build and Emscripten |
| `wasm32-wasi` | Tweag's work, absorbed in-tree | tech preview; installed via `ghc-wasm-meta`'s own ghcup channel; Template Haskell and GHCi work since the 9.10 era |

The predecessors are dead ends and should not be started from:

* **GHCJS** standalone — stuck on GHC 8.10, superseded by the in-tree backend.
* **Asterius** — deprecated in favour of the in-tree wasm backend.

Frontend frameworks, if a framework is wanted at all:

* **Miso** (1.13, actively maintained) — Elm-style, virtual DOM, event
  delegation, servant-style typed routing. Its official examples are now
  wasm-based, so it is the least surprising choice.
* **Reflex** — heavyweight FRP, also has wasm examples. More power, much more
  build surface.
* **jsaddle-wasm** — a bridge for existing JSaddle code. Not relevant here.
* **PureScript** — the outside option. Not Haskell, but Haskell-shaped, with a
  mature native JS compiler and no cross-toolchain pain. Would mean a rewrite,
  and its numeric tower is a different problem (see §2).

## 2. What actually matters for this program

`crit` is close to the best case for a port:

* pure computation, `stdout` only, and **no dependency outside `base`** — no C
  FFI, no GMP linkage, nothing to vendor;
* the pure API is already separated from the CLI. `Poly`, `QPoly`, `Bezout`,
  `Factor`, `Construct` and `Verify` contain no `IO` at all; only `Main` does.
  A web entry point is a new module beside `Main`, not a refactor.

The one substantive question is **`Integer`**.

The JavaScript backend has no GMP, so `ghc-bignum` falls back to its `native`
backend — a pure-Haskell bignum, correct but slower than GMP. (Note that the
JS backend marshalling `Int64`/`Word64` to JavaScript `BigInt` is a *different*
path and does not help `Integer`.) Whether the wasm backend also uses `native`
or can be built against a GMP compiled with `wasi-sdk` is worth checking before
relying on either answer.

**This probably does not matter.** The construction's coefficients grow like
`ρ^j h₀^{j-1}`, and the worst case seen so far is §8.5's

```
101288722414414331904
```

— 21 digits, which is nothing for any bignum implementation. The real bottleneck
is elsewhere: `Factor.properFactor` is Kronecker's method, exponential in the
number of divisors of the sampled values, and that is equally exponential on
every backend. If a web build ever feels slow, the fix is `--squarefree`, which
skips factoring entirely and still gives `H ∣ g'` and `H² ∣ f ∘ g` — everything
except the irreducibility of `H`.

So: **wasm rather than JS**, because this is compute rather than DOM work, and
because it is the backend with more momentum.

## 3. The architecture

Decided: **a `wasm32-wasi` reactor module holding the numerics, called from a
conventional JS/TS SPA.** No Haskell rendering framework. Haskell is a
high-assurance numerical engine behind a WebAssembly boundary; React/Vue/Svelte
or plain TS does the UI.

Miso and Reflex are therefore out of scope — they solve a problem this project
does not have. JSFFI still allows calls in both directions if some interop is
ever wanted, but nothing about the UI has to be Haskell.

### Shape of the build

* `-no-hs-main -optl-mexec-model=reactor -optl-Wl,--export=…` produces a reactor
  module rather than a command module (the default is a one-shot executable with
  a single entry point, which is the wrong shape).
* A post-link script parses the wasm and emits a JS module supplying the imports
  the instance needs; instantiation requires knot-tying, because the JSFFI
  imports and the wasm exports are mutually dependent.
* `_initialize` is auto-generated and **must be called exactly once** before any
  other export — via `wasi.initialize(instance)`.
* WASI itself comes from a small browser shim; `browser_wasi_shim` is the usual
  choice. The GHC docs do not endorse one.

### Two entry points over one pure core

`Main.hs` stays the native CLI. A new `Web.hs` carries the reactor exports.
Nothing else changes: `Poly`, `QPoly`, `Bezout`, `Factor`, `Construct` and
`Verify` are already `IO`-free, so both entry points sit on the same pure core.
This is the payoff of the existing module split, and it means the web work adds
a module rather than perturbing the verified path.

### The boundary must be decimal strings, not JS numbers

This is the one place where a careless API silently destroys the point of the
program.

Coefficients here are unbounded. §8.5 already produces

```
101288722414414331904
```

which exceeds `Number.MAX_SAFE_INTEGER` (`2^53 - 1 ≈ 9.007e15`) by five orders
of magnitude. Marshalling coefficients as JavaScript `number` would round them
*silently* — no exception, no NaN, just a wrong answer from a program whose
entire purpose is exact arithmetic. And it would corrupt the checks along with
the output, so the failure would not even be visible in the 22 booleans.

So the boundary is:

* **in** — `f` as a JSON array of decimal strings, low to high;
* **out** — a JSON object carrying `h, u, v, ρ, M, H, W, g` as decimal strings,
  plus the 22 named checks as booleans.

`BigInt` is the alternative and is exact, but strings are unambiguous across the
JSFFI and `BigInt("101…")` is one call on the JS side. Either is fine; `number`
is not.

Encode the JSON by hand. The output shape is fixed and small (~30 lines), and
`aeson` would drag a large dependency closure into a cross-compiled build,
forfeiting the zero-dependency property that makes this port cheap in the first
place.

### Run it off the main thread, and keep cancellation

`Factor.properFactor` is Kronecker, the one super-polynomial step, and it can
run away on a high-degree `f`. Two options, not exclusive:

* put the module in a **Web Worker**, so a long factorisation never freezes the
  page; and/or
* use an **async JSFFI export**, which returns a `Promise` carrying a
  `promise.throwTo()` callback — the value passed is wrapped as a `JSException`
  and raised as an async exception in the Haskell thread.

The second is genuinely attractive here: it gives the UI a cancel button for
precisely the step that can blow up. `--squarefree` remains the cheap escape
hatch, and should be exposed as a flag in the request object.

### Keep all arithmetic inside the module

The 22 checks run in wasm, on the exact integers, and JS renders booleans. No
arithmetic should be reimplemented on the JS side — not for display, not for
validation. The moment a coefficient is parsed into a `number` for convenience,
the assurance argument is gone.

## 4. Toolchain cost

### Host versus target

Worth stating plainly, because it is the source of most confusion here: the
*output* of these backends is platform-independent — a `.wasm` or a `.js` that
runs in any browser on any OS. The *compiler* is not. A cross-compiler is a
native program, so "GHC targeting wasm" means a GHC binary built for
`aarch64-darwin` that emits wasm, and somebody has to build and publish that
binary for each host. GHC's wasm backend additionally shells out to `wasi-sdk`,
a clang/LLVM toolchain, which is likewise a host-native binary.

So the question is never "will it run on the web" — it will. The question is
only whether a compiler that runs *on this Mac* is a download or a build.

### Where that currently lands

Better than it used to be. `ghc-wasm-meta` maintains its own ghcup channel and
ships binary artifacts for `{x86_64,aarch64}-{linux,darwin}`, so Apple Silicon
is covered; a manual build is supported on all four host combinations as a
fallback. Older write-ups (including, briefly, an earlier draft of this file)
say there is no prebuilt `wasm32-wasi-ghc` for macOS — that describes a
previous state and should be re-checked rather than believed.

Budget the `wasi-sdk` download regardless, and expect a multi-megabyte `.wasm`
before `-Os` and `wasm-opt`.

### A local gotcha

Already hit once on this machine: `gcc` on `PATH` resolves to
Alire's GNAT toolchain (`~/.local/share/alire/toolchains/gnat_native_*`), whose
`include-fixed/stdio.h` is broken on Darwin 25 — `#include <stdio.h>` fails with
`unknown type name 'FILE'`. Any `configure` that probes for a C compiler will
fail confusingly. Put `/usr/bin` first and set `CC=/usr/bin/clang`.

## 5. What the artifact should be

Not a prettier type signature — the Haskell is already typed about as well as
this problem wants. `newtype Poly` with a normalising smart constructor is the
right invariant, and the guarantee lives in `Verify.checks`.

The thing worth building is a page where you enter `f`, get `g` and `H`, and
watch all 22 checks verify *live, on your own input*: every propositional field
of the Lean `Setup`, plus Lemmas A, B, D, E and Corollary C'. That is the Lean
development made touchable, which is a much better demo than a number.

Worth being clear about what such a page would and would not prove. It re-checks
the theorem's hypotheses and conclusions for the input you typed, by exact
integer arithmetic. It does not transport the Lean proof to the browser — and it
could not, since `Setup` is `noncomputable` in Lean, for the two reasons in
`README.md`.

---

## Sources

* [GHC User's Guide — Backends](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/codegens.html)
* [GHC User's Guide — Using the WebAssembly backend](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/wasm.html)
* [JavaScript backend merged into GHC (IOG)](https://engineering.iog.io/2022-12-13-ghc-js-backend-merged/)
* [GHC's wasm backend now supports Template Haskell and ghci (Tweag)](https://www.tweag.io/blog/2024-11-21-ghc-wasm-th-ghci/)
* [ghc-wasm-meta](https://github.com/haskell-wasm/ghc-wasm-meta)
* [A detailed guide to using GHC's WebAssembly backend (Finley McIlwaine)](https://finley.dev/blog/2024-08-24-ghc-wasm.html)
* [miso on Hackage](https://hackage.haskell.org/package/miso)
* [ghc-wasm-miso-examples](https://github.com/haskell-wasm/ghc-wasm-miso-examples)
* [Improving Haskell's big numbers support (ghc-bignum)](https://iohk.io/en/blog/posts/2020/07/28/improving-haskells-big-numbers-support/)
