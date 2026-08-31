# CriticalValues

A Lean 4 / Mathlib formalization of

> Every algebraic number is a critical value of some `f ∈ ℤ[X]`.

Precisely (`critical-values-spec.md`, Theorem 1): for every nonconstant
`f ∈ ℤ[X]` there are `g, H ∈ ℤ[X]` with `H` irreducible, `H ∣ g'` and
`H² ∣ f ∘ g`.

Build with `lake exe cache get && lake build` (Lean 4.32.2).

## Status

| spec | statement | here | status |
|---|---|---|---|
| §5.1 | Taylor to second order, for `comp` | `comp_add_sq` | proved |
| §2 | the construction, as data | `Setup` | defined |
| §3 | Lemma A, `ρ g' = H·A` | `Setup.lemA` | proved |
| §3 | Lemma B, `ρ (f ∘ g) = H²·D` | `Setup.lemB` | proved |
| §4 | Lemma C, descent past `ρ` | `descent` | proved |
| §4 | Corollary C', `H ∣ g'` | `Setup.H_dvd_derivative` | proved |
| §4 | Corollary C', `H² ∣ f ∘ g` | `Setup.sq_dvd_comp` | proved |
| §5.3 | Lemma D, `H` irreducible | `Setup.lemD` | todo |
| §5.2 | Lemma E, nondegeneracy | `Setup.lemE` | todo |
| §2, §6 | existence of a `Setup` | `setup_exists` | todo |
| §1.1 | Theorem 1 | `main` | todo |
| §1.2 | Corollary 2 | — | todo |
| §1.3 | Corollary 3, critical values | — | todo |
| §8 | test vectors | — | todo |

`#print axioms` on each proved declaration gives only
`propext, Classical.choice, Quot.sound`.

## The files

### `CriticalValues/Basic.lean`

The dilation `X ↦ M·X` and Taylor to second order.

`scale M` is Mathlib's `Polynomial.compRingHom (C M * X)`, so `map_add`,
`map_mul` and `map_pow` come for free; what has to be recorded is
`derivative_scale`, the chain-rule factor `C M` that appears in every line of
§3, and `coeff_scale` for the integrality of §2.1.

`comp_add_sq` is `f(A + B) = f(A) + f'(A)·B + k·B²` for `comp` in `ℤ[X]`.
Mathlib's `Polynomial.binomExpansion` is the same statement for `eval` in a
commutative ring; the transport is along `f.comp q = (f.map C).eval q`
(`eval_map_C`), with the derivative coming back through `derivative_map`. So
§5.1 costs two lines rather than an induction on `f`.

### `CriticalValues/Setup.lean`

`Setup f` bundles §2 as data with its defining equations: `H` and `W` are
fields constrained by `hH` and `hW`, not quotients. That keeps division out of
`ℤ[X]` entirely, so both identities of §3 are one `linear_combination` each
from the structure fields.

`lemA` and `lemB` use only `hH`, `hW`, `hbez`, `hfac`, `hg` and the product
rule. In particular **`hirr`, `hprim`, `hH0` and `hM` are not used in §3** —
irreducibility is needed only to produce the Bézout data and again for Lemma D,
and `M = ρ h₀` is what makes §2.1 integral, not what makes §3 true.

### `CriticalValues/Descent.lean`

§4, and the one place the spec's proposed argument was replaced.

The spec proves Lemma C by strong induction on the prime factors of `|ρ|`,
reducing mod `p` at each step. That is not needed: `K.coeff 0` a unit says
exactly that `K` is primitive, and `C ρ` contributes only content, so
`IsPrimitive.dvd_primPart_iff_dvd`, `primPart_mul` and `isUnit_primPart_C`
already do the cancellation. The proof is six lines and uses no prime.

This is also the reason the construction normalizes `H(0) = 1` instead of
making `H` monic: primitivity of `H` is the only property `descent` consumes.
