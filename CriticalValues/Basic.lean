/-
The two pieces of infrastructure that §3 of the spec rests on: the dilation
`X ↦ M·X` as a ring hom, and Taylor expansion to second order for `comp`.

Neither is quite in Mathlib in the form needed.

* The dilation *is* a Mathlib construct — `Polynomial.compRingHom (C M * X)` —
  but its interaction with `derivative` (the chain-rule factor `C M` that shows
  up in every line of §3) has to be recorded once.

* `Polynomial.binomExpansion` is Taylor to second order for `eval` in a
  commutative ring.  What §3 needs is the same statement for `comp` in `ℤ[X]`.
  Rather than reprove it by induction on `f`, `comp_add_sq` transports it along
  `f.comp q = (f.map C).eval q`, which is `eval₂_eq_eval_map` unfolded; the
  derivative then comes back through `derivative_map`.
-/
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Algebra.Polynomial.Identities
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.Polynomial.Degree.Lemmas

set_option linter.style.header false

namespace CriticalValues

open Polynomial

/-! ### The dilation `X ↦ M·X` -/

/-- `scale M p` is `p(M·X)`, written `p̃` in the spec.  Packaged as the Mathlib
ring hom `compRingHom (C M * X)` so that `map_add`, `map_mul`, `map_one` and
`map_pow` are available without any hand-rolled substitute. -/
noncomputable def scale (M : ℤ) : ℤ[X] →+* ℤ[X] :=
  compRingHom (C M * X)

theorem scale_apply (M : ℤ) (p : ℤ[X]) : scale M p = p.comp (C M * X) := rfl

@[simp] theorem scale_X (M : ℤ) : scale M X = C M * X := by
  simp [scale_apply]

@[simp] theorem scale_C (M : ℤ) (a : ℤ) : scale M (C a) = C a := by
  simp

/-- **The chain rule for the dilation.**  This is the source of every stray `M`
in §3: `derivative (h(M·X)) = M · h'(M·X)`. -/
theorem derivative_scale (M : ℤ) (p : ℤ[X]) :
    derivative (scale M p) = C M * scale M (derivative p) := by
  rw [scale_apply, derivative_comp, scale_apply]
  simp

/-- The coefficients of a dilation, `(p(M·X))ⱼ = pⱼ Mʲ`.  Not needed for
Theorem 1 — where `H` and `W` are carried as data — but it is what makes the
integrality of §2.1 a calculation rather than a division. -/
theorem coeff_scale (M : ℤ) (p : ℤ[X]) (j : ℕ) :
    (scale M p).coeff j = p.coeff j * M ^ j := by
  induction p using Polynomial.induction_on' with
  | add p q hp hq => simp [hp, hq, add_mul]
  | monomial n a =>
      rw [scale_apply, monomial_comp, mul_pow, ← C_pow, ← mul_assoc, ← C_mul,
        C_mul_X_pow_eq_monomial, coeff_monomial, coeff_monomial]
      split <;> simp_all

/-- Dilation by a nonzero scalar is injective, since it multiplies the `j`-th
coefficient by `Mʲ ≠ 0`. -/
theorem scale_injective {M : ℤ} (hM : M ≠ 0) : Function.Injective (scale M) := by
  intro p q hpq
  ext j
  have h := congrArg (fun r => Polynomial.coeff r j) hpq
  simp only [coeff_scale] at h
  exact mul_right_cancel₀ (pow_ne_zero j hM) h

/-- Dilation by a nonzero scalar preserves degree: `X ↦ M·X` has degree `1`. -/
theorem natDegree_scale {M : ℤ} (hM : M ≠ 0) (p : ℤ[X]) :
    (scale M p).natDegree = p.natDegree := by
  rw [scale_apply, natDegree_comp, natDegree_C_mul_X _ hM, mul_one]

@[simp] theorem scale_coeff_zero (M : ℤ) (p : ℤ[X]) :
    (scale M p).coeff 0 = p.coeff 0 := by
  simp [coeff_scale]

/-! ### Taylor to second order -/

/-- **Taylor to second order for `comp`** (spec §5.1):
`f(A + B) = f(A) + f'(A)·B + B²·k`.

Transported from `Polynomial.binomExpansion`, which says this for `eval` in a
commutative ring, applied in the ring `ℤ[X]` to `f.map C`. -/
theorem eval_map_C (p q : ℤ[X]) : (p.map (C : ℤ →+* ℤ[X])).eval q = p.comp q := by
  rw [eval_map]; rfl

theorem comp_add_sq (f A B : ℤ[X]) :
    ∃ k : ℤ[X], f.comp (A + B)
      = f.comp A + (derivative f).comp A * B + k * B ^ 2 := by
  obtain ⟨k, hk⟩ := binomExpansion (f.map (C : ℤ →+* ℤ[X])) A B
  refine ⟨k, ?_⟩
  rw [derivative_map, eval_map_C, eval_map_C, eval_map_C] at hk
  exact hk

end CriticalValues
