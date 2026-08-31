/-
§5.3 of the spec: `H` is irreducible in `ℤ[X]`.

This is the only place Gauss's lemma is used, in both directions:
`h` primitive irreducible over `ℤ` gives `h` irreducible over `ℚ`, and `H`
primitive plus irreducible over `ℚ` gives `H` irreducible over `ℤ`.  In between,
the dilation has to be seen as an automorphism of `ℚ[X]`.

Mathlib has the *translation* `X ↦ X + C t` as `Polynomial.algEquivAevalXAddC`,
but not the dilation `X ↦ a·X`, so `scaleAlgEquiv` builds it — the inverse is
dilation by `a⁻¹`, which is why this works over `ℚ` and not over `ℤ`.
-/
import CriticalValues.Descent
import Mathlib.RingTheory.Polynomial.GaussLemma

set_option linter.style.header false

namespace CriticalValues

open Polynomial

/-! ### The dilation as an automorphism over a field -/

section Field

variable {K : Type*} [Field K]

/-- The dilation `X ↦ a·X` as a `K`-algebra automorphism of `K[X]`, for `a ≠ 0`.
Its inverse is dilation by `a⁻¹`; over `ℤ` there is no such inverse, which is
exactly why §5.3 has to pass through `ℚ`. -/
noncomputable def scaleAlgEquiv {a : K} (ha : a ≠ 0) : K[X] ≃ₐ[K] K[X] :=
  AlgEquiv.ofAlgHom (aeval (C a * X)) (aeval (C a⁻¹ * X))
    (by
      apply Polynomial.algHom_ext
      simp only [AlgHom.coe_comp, Function.comp_apply, aeval_X, map_mul, aeval_C, algebraMap_eq,
        AlgHom.coe_id, id_eq]
      rw [← mul_assoc, ← C_mul, inv_mul_cancel₀ ha, map_one, one_mul])
    (by
      apply Polynomial.algHom_ext
      simp only [AlgHom.coe_comp, Function.comp_apply, aeval_X, map_mul, aeval_C, algebraMap_eq,
        AlgHom.coe_id, id_eq]
      rw [← mul_assoc, ← C_mul, mul_inv_cancel₀ ha, map_one, one_mul])

@[simp] theorem scaleAlgEquiv_apply {a : K} (ha : a ≠ 0) (p : K[X]) :
    scaleAlgEquiv ha p = p.comp (C a * X) := rfl

/-- Dilation by a nonzero scalar preserves irreducibility in `K[X]`. -/
theorem irreducible_comp_C_mul_X {a : K} (ha : a ≠ 0) (p : K[X]) :
    Irreducible (p.comp (C a * X)) ↔ Irreducible p := by
  rw [← scaleAlgEquiv_apply ha p]
  exact MulEquiv.irreducible_iff (scaleAlgEquiv ha)

end Field

namespace Setup

variable {f : ℤ[X]} (S : Setup f)

/-- `M ≠ 0`, being the product of the nonzero integers `ρ` and `h₀`. -/
theorem hM0 : S.M ≠ 0 := by
  rw [S.hM]; exact mul_ne_zero S.hρ S.hh₀0

/-- `H` is primitive, because its constant term is `1`. -/
theorem hHprim : S.H.IsPrimitive :=
  isPrimitive_of_isUnit_coeff_zero (S.hH0 ▸ isUnit_one)

/-- The defining equation of `H`, over `ℚ`. -/
theorem hH_map : C ((S.h₀ : ℚ)) * S.H.map (Int.castRingHom ℚ)
    = (S.h.map (Int.castRingHom ℚ)).comp (C ((S.M : ℚ)) * X) := by
  have h := congrArg (Polynomial.map (Int.castRingHom ℚ)) S.hH
  simpa [scale_apply, Polynomial.map_comp] using h

/-- **Lemma D** (spec §5.3): `H` is irreducible in `ℤ[X]`.

`h` is primitive irreducible, hence irreducible over `ℚ`; the dilation is an
automorphism of `ℚ[X]` since `M ≠ 0`, so `h(M·X)` is irreducible over `ℚ`;
dividing by the unit `h₀` leaves `H` irreducible over `ℚ`; and `H` is primitive,
so Gauss returns it to `ℤ[X]`. -/
theorem lemD : Irreducible S.H := by
  rw [IsPrimitive.Int.irreducible_iff_irreducible_map_cast S.hHprim]
  have hM : ((S.M : ℚ)) ≠ 0 := Int.cast_ne_zero.mpr S.hM0
  have h0 : ((S.h₀ : ℚ)) ≠ 0 := Int.cast_ne_zero.mpr S.hh₀0
  have hh : Irreducible (S.h.map (Int.castRingHom ℚ)) :=
    (IsPrimitive.Int.irreducible_iff_irreducible_map_cast S.hprim).mp S.hirr
  have hmul : Irreducible (C ((S.h₀ : ℚ)) * S.H.map (Int.castRingHom ℚ)) := by
    rw [S.hH_map, irreducible_comp_C_mul_X hM]
    exact hh
  exact (irreducible_isUnit_mul (isUnit_C.mpr (isUnit_iff_ne_zero.mpr h0))).mp hmul

end Setup

end CriticalValues
