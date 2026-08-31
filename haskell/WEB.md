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
| `wasm32-wasi` | Tweag's work, absorbed in-tree | tech preview; ghcup installs it on Linux, otherwise `ghc-wasm-meta`; Template Haskell and GHCi work since the 9.10 era |

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

## 3. The three routes

### (a) wasm + JSFFI export — recommended

Add one module exporting a pure `String -> String` (or a JSON-shaped
equivalent) that runs `setupExists` and `Verify.checks` and renders the result.
GHC's wasm backend supports `foreign export javascript`, so the browser calls
the Haskell function directly; no CLI round-trip, no argv marshalling.

* *Pros:* smallest diff, best compute, no framework, no Haskell UI code.
* *Cons:* JSFFI needs the post-link shim step, so the build is a little more
  than `ghc -o`.

### (b) wasm + WASI shim — the lazy variant of (a)

Compile the existing `Main` unchanged and run it in the browser under a WASI
polyfill, passing argv and capturing stdout.

* *Pros:* essentially zero code change; `crit --demo` runs in a page as-is.
* *Cons:* a string-in/string-out CLI is an awkward thing to build a UI around,
  and you inherit `exitFailure` as a control-flow mechanism.

### (c) JavaScript backend + Miso

* *Pros:* better DOM interop, easier JS FFI, an all-Haskell typed UI.
* *Cons:* weaker on compute, needs Emscripten, and adds Miso plus its
  dependency closure to a project that currently depends on nothing.

## 4. Toolchain cost — the real cost

The code is the cheap part. The cross-compiler is not in any bindist, and
ghcup's prebuilt wasm cross-compiler is Linux-oriented; on macOS ARM this
likely means bootstrapping through `ghc-wasm-meta`, which pulls `wasi-sdk`.
Budget a long download and some yak-shaving.

One local gotcha, already hit once on this machine: `gcc` on `PATH` resolves to
Alire's GNAT toolchain (`~/.local/share/alire/toolchains/gnat_native_*`), whose
`include-fixed/stdio.h` is broken on Darwin 25 — `#include <stdio.h>` fails with
`unknown type name 'FILE'`. Any `configure` that probes for a C compiler will
fail confusingly. Put `/usr/bin` first and set `CC=/usr/bin/clang`.

Also expect a multi-megabyte `.wasm` before `-Os` and `wasm-opt`.

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
