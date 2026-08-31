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
| §5.3 | Lemma D, `H` irreducible | `Setup.lemD` | proved |
| §5.2 | Lemma E, `W ≠ 0` | `Setup.W_ne_zero` | proved |
| §5.2 | Lemma E, `deg g = n + deg W ≥ 2` | `Setup.natDegree_g` | proved |
| §5.2 | Lemma E, `g' ≠ 0` | `Setup.derivative_g_ne_zero` | proved |
| §2 | Bézout data over `ℤ` | `exists_bezout` | proved |
| §2.1 | existence of a `Setup` | `setup_of_factor`, `setup_exists` | proved |
| §6 | the degenerate case `X ∣ f` | `main_of_X_dvd` | proved |
| §1.1 | **Theorem 1** | `main` | proved |
| §1.1 | Theorem 1 with `deg g ≥ 2`, `deg H ≥ 1` | `main_strong` | proved |
| §1.2 | Corollary 2 | `cor2` | proved |
| §1.2 | Corollary 2, no side condition | `main_cor2` | proved |
| §7 | `β = α/M` is a critical point | `Setup.critical_point` | proved |
| §1.3 | Corollary 3, forward | `exists_critical_point_of_isAlgebraic` | proved |
| §1.3 | Corollary 3, converse | `isAlgebraic_critical_value` | proved |
| §8 | test vectors 8.1–8.4 | `test81_*` … `test84_*` | proved |
| §8 | non-vacuity of `Setup` | `nonempty_Setup_X_sq_add_one` | proved |

**The spec is formalized in full: no `sorry`**, and `#print axioms` on every
theorem gives only `propext, Classical.choice, Quot.sound`.

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

### `CriticalValues/Irred.lean`

§5.3, the one place Gauss's lemma is used — in both directions. In between, the
dilation has to be an automorphism of `ℚ[X]`; Mathlib has the *translation*
`X ↦ X + C t` as `algEquivAevalXAddC` but not the dilation, so `scaleAlgEquiv`
builds it. Its inverse is dilation by `a⁻¹`, which is exactly why §5.3 must pass
through `ℚ`.

### `CriticalValues/Exists.lean`

§2, existence. The Bézout data comes from coprimality of `h` and `h'` in the PID
`ℚ[X]`, with `IsLocalization.integerNormalization` clearing the denominators of
the two cofactors. **No resultant**, as §10 allows.

The integrality of §2.1 is the two divisibilities `C h₀ ∣ h(M·X)` and
`C ρ ∣ v(0)H - v(M·X)`, both read off `coeff_scale` from the single fact that
`M = ρ h₀` is divisible by each of `ρ` and `h₀`. Taking `H` and `W` to be the
cofactors of those divisibilities discharges `hH` and `hW` with no division in
`ℤ[X]` anywhere.

`setup_of_factor` records `S.h = h` for the chosen factor, which is what §7
needs in order to evaluate at a root of `h`.

### `CriticalValues/Nondeg.lean`

§5.2. The spec argues `W ≠ 0` in `ℚ[X]`; over `ℤ` it is the same two lines,
since multiplying the Bézout relation by `h₀` clears the only denominator
involved, exhibiting `h ∣ C M` — impossible for a nonconstant `h`.

### `CriticalValues/Main.lean`

Theorem 1 and Corollary 2. The case split is only on whether `X ∣ f`; §6's
`g = X²`, `H = X` covers `f = X·(X²+1)` as well as `f = c·Xᵏ`, so the split is
on divisibility by `X`, not on `f` being a monomial.

**`g' ≠ 0` is automatic.** `cor2` takes it as a hypothesis because it is stated
for an arbitrary `g`, but the construction never returns a `g` without it:
`main_strong` records `deg g ≥ 2` in both branches — by Lemma E
(`deg g = deg h + deg W`, both summands `≥ 1`) in the main case, and because
`g = X²` in the degenerate one — and characteristic zero does the rest. Note
this never inspects `deg f`: `deg f ≥ 1` suffices, and `deg f = 1` really does
occur (test 8.1 produces a quadratic `g`). `main_cor2` is Corollary 2 with the
hypothesis discharged.

### `CriticalValues/Critical.lean`

§7, the only place roots appear. The computation is shorter than §7 makes it
look: `g(β) = Mβ + h(α)W(β) = α` needs only `h(α) = 0` — `W(β)` is never
computed — and `g'(β) = 0` is not a computation at all, since `H ∣ g'` is
already Corollary C' and `H(β) = 0` because `h₀H = h(M·X)` vanishes at `β`.

Corollary 3 is packaged without `minpoly`: an algebraic `α` is a root of some
`p ∈ ℤ[X]`, and factoring `p.primPart` in the UFD `ℤ[X]` gives an irreducible
primitive factor that already kills `α`, since `K` is a domain.

### `CriticalValues/Ledger.lean`

The audit. All four test vectors of §8 hold exactly as the spec states them; the
two cofactors the spec leaves unwritten (at 8.3, and the degree-9 one at 8.4)
are recorded here. `nonempty_Setup_X_sq_add_one` matters because `Setup` has
twenty fields: a theorem quantified over it says nothing if no instance exists.
