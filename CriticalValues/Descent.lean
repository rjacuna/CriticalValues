/-
§4 of the spec: removing the Bézout constant `ρ`.

The spec proposes an induction on the prime factors of `|ρ|`, reducing mod each
prime in turn.  That is not necessary: the hypothesis `K.coeff 0` is a unit says
exactly that `K` is primitive, and Mathlib's content/primitive-part machinery
(`IsPrimitive.dvd_primPart_iff_dvd`, `primPart_mul`, `isUnit_primPart_C`) already
contains the cancellation.  `C ρ` contributes only content, so it disappears on
passing to primitive parts.

This is why the construction normalizes `H(0) = 1` rather than making `H` monic:
a monic `H` need not be primitive after the dilation, and primitivity is the
only thing `descent` uses.
-/
import CriticalValues.Setup
import Mathlib.RingTheory.Polynomial.Content

set_option linter.style.header false

namespace CriticalValues

open Polynomial

/-- A polynomial whose constant term is a unit is primitive: any constant
dividing it divides its constant term. -/
theorem isPrimitive_of_isUnit_coeff_zero {K : ℤ[X]} (hK : IsUnit (K.coeff 0)) :
    K.IsPrimitive :=
  fun _ hr => isUnit_of_dvd_unit ((C_dvd_iff_dvd_coeff _ _).mp hr 0) hK

/-- **Lemma C** (spec §4).  A primitive `K` dividing `ρ · P` divides `P`. -/
theorem descent {P K : ℤ[X]} {ρ : ℤ} (hρ : ρ ≠ 0) (hK : IsUnit (K.coeff 0))
    (hd : K ∣ C ρ * P) : K ∣ P := by
  rcases eq_or_ne P 0 with rfl | hP
  · simp
  have hKprim : K.IsPrimitive := isPrimitive_of_isUnit_coeff_zero hK
  have h0 : C ρ * P ≠ 0 := mul_ne_zero (by simpa using hρ) hP
  obtain ⟨w, hw⟩ := isUnit_primPart_C (R := ℤ) ρ
  refine (hKprim.dvd_primPart_iff_dvd hP).mp ?_
  have h1 : K ∣ (C ρ).primPart * P.primPart := by
    rw [← primPart_mul h0]
    exact (hKprim.dvd_primPart_iff_dvd h0).mpr hd
  have h2 : P.primPart = (↑w⁻¹ : ℤ[X]) * ((C ρ).primPart * P.primPart) := by
    rw [← hw, ← mul_assoc, Units.inv_mul, one_mul]
  rw [h2]
  exact h1.mul_left _

namespace Setup

variable {f : ℤ[X]} (S : Setup f)

/-- `H²` also has constant term `1`, which is what lets `descent` be applied to
Lemma B as well as to Lemma A. -/
theorem sq_coeff_zero : (S.H ^ 2).coeff 0 = 1 := by
  rw [sq, mul_coeff_zero, S.hH0, mul_one]

/-- **Corollary C'**, first half: `H ∣ g'` in `ℤ[X]`. -/
theorem H_dvd_derivative : S.H ∣ derivative S.g :=
  descent S.hρ (S.hH0 ▸ isUnit_one) ⟨_, S.lemA⟩

/-- **Corollary C'**, second half: `H² ∣ f ∘ g` in `ℤ[X]`. -/
theorem sq_dvd_comp : S.H ^ 2 ∣ f.comp S.g := by
  obtain ⟨D, hD⟩ := S.lemB
  exact descent S.hρ (S.sq_coeff_zero ▸ isUnit_one) ⟨D, hD⟩

end Setup

end CriticalValues
