/-
§5.2 of the spec: nondegeneracy.

`W ≠ 0` is the one place where the Bézout relation is used *against* itself: if
`W` vanished then `h₀ v = v(0) h`, and substituting that back into
`u h + v h' = ρ` exhibits `h` as a divisor of the constant `C M`, which a
nonconstant `h` cannot be.  The spec runs this argument in `ℚ[X]`; over `ℤ` it
is the same two lines, since multiplying the Bézout relation by `h₀` clears the
only denominator involved.

Everything else follows: `W(0) = 0` and `W ≠ 0` give `deg W ≥ 1`, the product
`h(M·X)·W` then out-degrees the linear term `M·X`, and `deg g ≥ 2` in
characteristic zero gives `g' ≠ 0`.
-/
import CriticalValues.Exists

set_option linter.style.header false

namespace CriticalValues

open Polynomial

namespace Setup

variable {f : ℤ[X]} (S : Setup f)

/-- `h(M·X) ≠ 0`. -/
theorem scale_h_ne_zero : scale S.M S.h ≠ 0 := by
  intro h0
  exact S.hirr.ne_zero (scale_injective S.hM0 (by rw [h0, map_zero]))

/-- `W(0) = 0`: the two constant terms in `ρW = v(0)H - v(M·X)` cancel. -/
theorem W_coeff_zero : S.W.coeff 0 = 0 := by
  have h : S.ρ * S.W.coeff 0 = 0 := by
    have h0 := congrArg (fun p => Polynomial.coeff p 0) S.hW
    simpa [S.hH0] using h0
  exact (mul_eq_zero.mp h).resolve_left S.hρ

/-- **Lemma E**, first half (spec §5.2): `W ≠ 0`.

If `W = 0` then `v(M·X) = v(0)·H`, hence `h₀ v = v(0) h` after undoing the
injective dilation; multiplying the Bézout relation by `h₀` then gives
`h · (h₀ u + v(0) h') = C M`, so `h` divides a nonzero constant — impossible for
`deg h ≥ 1`. -/
theorem W_ne_zero : S.W ≠ 0 := by
  intro hW0
  have hsv : scale S.M S.v = C (S.v.coeff 0) * S.H := by
    have h := S.hW
    rw [hW0, mul_zero] at h
    linear_combination h
  have hv : C S.h₀ * S.v = C (S.v.coeff 0) * S.h := by
    apply scale_injective S.hM0
    simp only [map_mul, scale_C]
    rw [hsv, ← S.hH]
    ring
  have hdvd : S.h ∣ C S.M := by
    refine ⟨C S.h₀ * S.u + C (S.v.coeff 0) * derivative S.h, ?_⟩
    rw [S.hM, map_mul]
    linear_combination (-(C S.h₀)) * S.hbez + (derivative S.h) * hv
  have hle := Polynomial.natDegree_le_of_dvd hdvd (by simpa using S.hM0)
  simp only [natDegree_C] at hle
  have := S.hn
  omega

/-- `deg W ≥ 1`, since `W ≠ 0` has zero constant term. -/
theorem one_le_natDegree_W : 1 ≤ S.W.natDegree := by
  rcases Nat.eq_zero_or_pos S.W.natDegree with h0 | h0
  · have hc := eq_C_of_natDegree_eq_zero h0
    rw [S.W_coeff_zero, map_zero] at hc
    exact absurd hc S.W_ne_zero
  · omega

/-- **Lemma E**, second half: `deg g = deg h + deg W`, so `deg g ≥ 2`.

There is no cancellation: `h(M·X)·W` has degree `n + deg W ≥ 2`, strictly above
the degree `1` of the linear term `M·X`. -/
theorem natDegree_g : S.g.natDegree = S.h.natDegree + S.W.natDegree := by
  have hprod : (scale S.M S.h * S.W).natDegree = S.h.natDegree + S.W.natDegree := by
    rw [natDegree_mul S.scale_h_ne_zero S.W_ne_zero, natDegree_scale S.hM0]
  have hlin : (C S.M * X : ℤ[X]).natDegree = 1 := natDegree_C_mul_X _ S.hM0
  have hlt : (C S.M * X : ℤ[X]).natDegree < (scale S.M S.h * S.W).natDegree := by
    rw [hlin, hprod]
    have := S.hn; have := S.one_le_natDegree_W
    omega
  rw [S.hg, natDegree_add_eq_right_of_natDegree_lt hlt, hprod]

/-- `2 ≤ deg g`. -/
theorem two_le_natDegree_g : 2 ≤ S.g.natDegree := by
  rw [S.natDegree_g]
  have := S.hn; have := S.one_le_natDegree_W
  omega

/-- **Lemma E**, last part: `g' ≠ 0`, by characteristic zero. -/
theorem derivative_g_ne_zero : derivative S.g ≠ 0 := by
  rw [derivative_ne_zero]
  have := S.two_le_natDegree_g
  omega

end Setup

end CriticalValues
