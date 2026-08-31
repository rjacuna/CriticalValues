/-
§7 of the spec: the critical-value corollary.

This is the only place roots appear.  Everything above lives in `ℤ[X]`; here a
root `α` of `h` in a characteristic-zero field is given, and `β = α/M` is shown
to be a critical point of `g` with critical value `α`.

The computation is shorter than §7 makes it look.  `g = M·X + h(M·X)·W`, so
`g(β) = Mβ + h(α)·W(β) = α` needs only `h(α) = 0` — the value of `W(β)` never
has to be computed.  And `g'(β) = 0` is not a computation at all: `H ∣ g'` is
already Corollary C', and `H(β) = 0` because `h₀ H = h(M·X)` vanishes at `β`
while `h₀ ≠ 0`.

Dividing by `M` is what the whole construction was arranged to permit: `M` is
invertible in a field of characteristic zero, and `H(0) = 1` is what made `H`
integral after the dilation.
-/
import CriticalValues.Nondeg
import Mathlib.RingTheory.Algebraic.Integral

set_option linter.style.header false

namespace CriticalValues

open Polynomial

namespace Setup

variable {f : ℤ[X]} (S : Setup f) {K : Type*} [Field K] [CharZero K]

/-- Evaluating a dilated polynomial at `α/M` is evaluating it at `α`. -/
theorem aeval_scale (α : K) (p : ℤ[X]) :
    aeval (α / ((S.M : ℤ) : K)) (scale S.M p) = aeval α p := by
  have hM : ((S.M : ℤ) : K) ≠ 0 := Int.cast_ne_zero.mpr S.hM0
  have hx : aeval (α / ((S.M : ℤ) : K)) (C S.M * X : ℤ[X]) = α := by
    simp only [map_mul, aeval_X, eq_intCast, map_intCast]
    field_simp
  rw [scale_apply, aeval_comp, hx]

/-- `H(α/M) = 0` whenever `h(α) = 0`. -/
theorem aeval_H_eq_zero {α : K} (hα : aeval α S.h = 0) :
    aeval (α / ((S.M : ℤ) : K)) S.H = 0 := by
  have hh0 : ((S.h₀ : ℤ) : K) ≠ 0 := Int.cast_ne_zero.mpr S.hh₀0
  have hsh : aeval (α / ((S.M : ℤ) : K)) (scale S.M S.h) = 0 := by
    rw [S.aeval_scale, hα]
  have h1 := congrArg (aeval (α / ((S.M : ℤ) : K))) S.hH
  rw [map_mul, hsh] at h1
  simp only [eq_intCast, map_intCast] at h1
  exact (mul_eq_zero.mp h1).resolve_left hh0

/-- **§7.**  `β = α/M` is a critical point of `g`, with critical value `α`. -/
theorem critical_point {α : K} (hα : aeval α S.h = 0) :
    aeval (α / ((S.M : ℤ) : K)) S.g = α ∧
      aeval (α / ((S.M : ℤ) : K)) (derivative S.g) = 0 := by
  have hM : ((S.M : ℤ) : K) ≠ 0 := Int.cast_ne_zero.mpr S.hM0
  have hsh : aeval (α / ((S.M : ℤ) : K)) (scale S.M S.h) = 0 := by
    rw [S.aeval_scale, hα]
  refine ⟨?_, ?_⟩
  · rw [S.hg]
    simp only [map_add, map_mul, aeval_X, eq_intCast, map_intCast, hsh, zero_mul, add_zero]
    field_simp
  · obtain ⟨A, hA⟩ := S.H_dvd_derivative
    rw [hA, map_mul, S.aeval_H_eq_zero hα, zero_mul]

end Setup

/-- **Corollary 3**, forward direction (spec §1.3).  Every root of a nonconstant
primitive irreducible `h ∈ ℤ[X]` with `h(0) ≠ 0` is a critical value of some
`g ∈ ℤ[X]`, of degree at least `2`. -/
theorem exists_critical_point {K : Type*} [Field K] [CharZero K] {h : ℤ[X]}
    (hirr : Irreducible h) (hprim : h.IsPrimitive) (hn : 1 ≤ h.natDegree)
    (hh0 : h.coeff 0 ≠ 0) {α : K} (hα : aeval α h = 0) :
    ∃ (g : ℤ[X]) (β : K), 2 ≤ g.natDegree ∧ aeval β g = α ∧ aeval β (derivative g) = 0 := by
  obtain ⟨S, hSh⟩ := setup_of_factor (f := h) (f₁ := 1) hirr hprim hn hh0 (by ring)
  obtain ⟨h1, h2⟩ := S.critical_point (α := α) (by rw [hSh]; exact hα)
  exact ⟨S.g, _, S.two_le_natDegree_g, h1, h2⟩

/-! ### Corollary 3 -/

/-- An algebraic number is a root of some *irreducible primitive* `h ∈ ℤ[X]`.
Factor a witness in the UFD `ℤ[X]`: the product of its irreducible factors
vanishes at `α`, and `K` is a domain, so one factor already does. -/
theorem exists_irreducible_aeval_eq_zero {K : Type*} [Field K] [CharZero K] {α : K}
    (hα : IsAlgebraic ℤ α) :
    ∃ h : ℤ[X], Irreducible h ∧ h.IsPrimitive ∧ 1 ≤ h.natDegree ∧ aeval α h = 0 := by
  obtain ⟨p, hp0, hpα⟩ := hα
  have hPprim : p.primPart.IsPrimitive := isPrimitive_primPart p
  have hP0 : p.primPart ≠ 0 := hPprim.ne_zero
  have hcont : ((p.content : ℤ) : K) ≠ 0 :=
    Int.cast_ne_zero.mpr (by simpa [Polynomial.content_eq_zero_iff] using hp0)
  have hPα : aeval α p.primPart = 0 := by
    have h1 := congrArg (aeval α) p.eq_C_content_mul_primPart
    rw [hpα, map_mul] at h1
    simp only [eq_intCast, map_intCast] at h1
    exact (mul_eq_zero.mp h1.symm).resolve_left hcont
  obtain ⟨w, hw⟩ := UniqueFactorizationMonoid.factors_prod hP0
  have hwu : aeval α (w : ℤ[X]) ≠ 0 := (w.isUnit.map (aeval α)).ne_zero
  have hprod : aeval α (UniqueFactorizationMonoid.factors p.primPart).prod = 0 := by
    have hz : aeval α ((UniqueFactorizationMonoid.factors p.primPart).prod * (w : ℤ[X])) = 0 := by
      rw [hw]; exact hPα
    rw [map_mul] at hz
    exact (mul_eq_zero.mp hz).resolve_right hwu
  rw [map_multiset_prod] at hprod
  obtain ⟨h, hmem, hh0⟩ := Multiset.mem_map.mp (Multiset.prod_eq_zero_iff.mp hprod)
  have hirr : Irreducible h := UniqueFactorizationMonoid.irreducible_of_factor h hmem
  have hprim : h.IsPrimitive :=
    isPrimitive_of_dvd hPprim (UniqueFactorizationMonoid.dvd_of_mem_factors hmem)
  exact ⟨h, hirr, hprim, one_le_natDegree_of_irreducible_primitive hirr hprim, hh0⟩

/-- **Corollary 3** (spec §1.3), forward direction: every algebraic number is a
critical value of some `g ∈ ℤ[X]` of degree at least `2`.  `α = 0` is the
degenerate case `g = X²`, `β = 0` of §7. -/
theorem exists_critical_point_of_isAlgebraic {K : Type*} [Field K] [CharZero K] {α : K}
    (hα : IsAlgebraic ℤ α) :
    ∃ (g : ℤ[X]) (β : K), 2 ≤ g.natDegree ∧ aeval β g = α ∧ aeval β (derivative g) = 0 := by
  rcases eq_or_ne α 0 with rfl | hα0
  · exact ⟨X ^ 2, 0, by simp, by simp, by simp⟩
  · obtain ⟨h, hirr, hprim, hn, hh⟩ := exists_irreducible_aeval_eq_zero hα
    have hh0 : h.coeff 0 ≠ 0 := by
      intro hc
      obtain ⟨k, hk⟩ := X_dvd_iff.mpr hc
      rcases hirr.isUnit_or_isUnit hk with hu | hu
      · exact Polynomial.not_isUnit_X hu
      · rw [hk, map_mul, aeval_X] at hh
        exact hα0 ((mul_eq_zero.mp hh).resolve_right (hu.map (aeval α)).ne_zero)
    exact exists_critical_point hirr hprim hn hh0 hh

/-- **Corollary 3**, converse.  A critical point of a `g` with `g' ≠ 0` is
algebraic for the trivial reason: it is a root of `g'`, a nonzero integer
polynomial. -/
theorem isAlgebraic_of_critical_point {K : Type*} [Field K] {g : ℤ[X]}
    (hg : derivative g ≠ 0) {β : K} (hβ : aeval β (derivative g) = 0) : IsAlgebraic ℤ β :=
  ⟨derivative g, hg, hβ⟩

/-- And so is the critical value, `g` mapping algebraic to algebraic. -/
theorem isAlgebraic_critical_value {K : Type*} [Field K] [Algebra ℚ K] {g : ℤ[X]}
    (hg : derivative g ≠ 0) {β : K} (hβ : aeval β (derivative g) = 0) :
    IsAlgebraic ℚ (aeval β g) := by
  have hβQ : IsAlgebraic ℚ β := by
    refine ⟨(derivative g).map (algebraMap ℤ ℚ), ?_, ?_⟩
    · rw [Polynomial.map_ne_zero_iff (algebraMap ℤ ℚ).injective_int]
      exact hg
    · rw [aeval_map_algebraMap]; exact hβ
  rw [← aeval_map_algebraMap (A := ℚ) β g]
  rw [isAlgebraic_iff_isIntegral] at hβQ ⊢
  exact IsIntegral.of_mem_of_fg _ hβQ.fg_adjoin_singleton _ (aeval_mem_adjoin_singleton _ _)

end CriticalValues
