/-
§2 of the spec, existence: every nonconstant `f` not divisible by `X` admits a
`Setup`.

Two things have to be produced.  The **Bézout data** comes from `ℚ[X]`: `h` is
primitive irreducible, hence irreducible over `ℚ`, and `h ∤ h'` there for degree
reasons, so `h` and `h'` are coprime in the PID `ℚ[X]`; clearing the
denominators of the two cofactors returns the relation to `ℤ[X]` with a nonzero
constant `ρ` on the right.  No resultant is needed — the spec is explicit that
any nonzero element of `(h, h') ∩ ℤ` will do, and `integerNormalization`
produces one.

The **integrality** of §2.1 is the divisibilities `C h₀ ∣ h(M·X)` and
`C ρ ∣ v(0)·H - v(M·X)`, both read off `coeff_scale` from the single fact that
`M = ρ h₀` is divisible by each of `ρ` and `h₀`.  Taking `H` and `W` to be the
cofactors of those divisibilities is what discharges the `Setup` fields `hH`
and `hW` without ever dividing in `ℤ[X]`.
-/
import CriticalValues.Irred
import Mathlib.RingTheory.Localization.Integral
import Mathlib.RingTheory.PrincipalIdealDomain

set_option linter.style.header false

namespace CriticalValues

open Polynomial

/-! ### Bézout data -/

/-- Bézout for `h` and `h'` in `ℤ[X]`, up to a nonzero constant `ρ`. -/
theorem exists_bezout {h : ℤ[X]} (hirr : Irreducible h) (hprim : h.IsPrimitive)
    (hn : 1 ≤ h.natDegree) :
    ∃ (u v : ℤ[X]) (ρ : ℤ), ρ ≠ 0 ∧ u * h + v * derivative h = C ρ := by
  have hmapinj : Function.Injective (Polynomial.map (Int.castRingHom ℚ)) :=
    Polynomial.map_injective _ Int.cast_injective
  have hQ : Irreducible (h.map (Int.castRingHom ℚ)) :=
    (IsPrimitive.Int.irreducible_iff_irreducible_map_cast hprim).mp hirr
  have hdegQ : (h.map (Int.castRingHom ℚ)).natDegree = h.natDegree :=
    natDegree_map_eq_of_injective Int.cast_injective h
  have hnd0 : (h.map (Int.castRingHom ℚ)).natDegree ≠ 0 := by omega
  have hd0 : derivative (h.map (Int.castRingHom ℚ)) ≠ 0 := derivative_ne_zero.mpr hnd0
  have hnotdvd :
      ¬ (h.map (Int.castRingHom ℚ) ∣ derivative (h.map (Int.castRingHom ℚ))) := by
    intro hdvd
    have h1 := Polynomial.natDegree_le_of_dvd hdvd hd0
    have h2 := Polynomial.natDegree_derivative_lt hnd0
    omega
  obtain ⟨a, b, hab⟩ := hQ.coprime_iff_not_dvd.mpr hnotdvd
  obtain ⟨c₁, hc₁M, hc₁⟩ := IsLocalization.integerNormalization_spec (nonZeroDivisors ℤ) a
  obtain ⟨c₂, hc₂M, hc₂⟩ := IsLocalization.integerNormalization_spec (nonZeroDivisors ℤ) b
  have hsmul : ∀ (c : ℤ) (p : ℚ[X]), c • p = (c : ℚ[X]) * p := by
    intro c p; simp [zsmul_eq_mul]
  rw [hsmul] at hc₁ hc₂
  refine ⟨C c₂ * IsLocalization.integerNormalization (nonZeroDivisors ℤ) a,
    C c₁ * IsLocalization.integerNormalization (nonZeroDivisors ℤ) b, c₁ * c₂,
    mul_ne_zero (nonZeroDivisors.ne_zero hc₁M) (nonZeroDivisors.ne_zero hc₂M), ?_⟩
  apply hmapinj
  simp only [Polynomial.map_add, Polynomial.map_mul, Polynomial.map_intCast,
    ← derivative_map, algebraMap_int_eq, eq_intCast, Int.cast_mul] at hc₁ hc₂ ⊢
  rw [hc₁, hc₂]
  linear_combination ((c₁ : ℚ[X]) * (c₂ : ℚ[X])) * hab

/-! ### Existence of a `Setup` -/

/-- A primitive irreducible polynomial is nonconstant: a constant primitive
polynomial has unit constant term, hence is a unit. -/
theorem one_le_natDegree_of_irreducible_primitive {h : ℤ[X]} (hirr : Irreducible h)
    (hprim : h.IsPrimitive) : 1 ≤ h.natDegree := by
  rcases Nat.eq_zero_or_pos h.natDegree with h0 | h0
  · exfalso
    have hc : h = C (h.coeff 0) := eq_C_of_natDegree_eq_zero h0
    have hu : IsUnit (h.coeff 0) := hprim _ ⟨1, by rw [mul_one, ← hc]⟩
    exact hirr.not_isUnit (by rw [hc]; exact isUnit_C.mpr hu)
  · omega

/-- The construction of §2 run on a *chosen* factor `h` of `f`.  The conclusion
records `S.h = h`, which §7 needs in order to evaluate at a root of `h`. -/
theorem setup_of_factor {f h f₁ : ℤ[X]} (hirr : Irreducible h) (hprim : h.IsPrimitive)
    (hn : 1 ≤ h.natDegree) (hh₀0 : h.coeff 0 ≠ 0) (hfac : f = h * f₁) :
    ∃ S : Setup f, S.h = h := by
  obtain ⟨u, v, ρ, hρ, hbez⟩ := exists_bezout hirr hprim hn
  set M : ℤ := ρ * h.coeff 0 with hMdef
  have hρM : ρ ∣ M := ⟨h.coeff 0, hMdef⟩
  have hh₀M : h.coeff 0 ∣ M := ⟨ρ, by rw [hMdef]; ring⟩
  -- §2.1, first divisibility: `h₀ ∣ h(M·X)`
  have hHdvd : C (h.coeff 0) ∣ scale M h := by
    rw [C_dvd_iff_dvd_coeff]
    intro j
    rw [coeff_scale]
    rcases Nat.eq_zero_or_pos j with rfl | hj
    · simp
    · exact (hh₀M.trans (dvd_pow_self M (by omega))).mul_left _
  obtain ⟨H, hH⟩ := hHdvd
  have hH0 : H.coeff 0 = 1 := by
    have hc : h.coeff 0 * 1 = h.coeff 0 * H.coeff 0 := by
      have := congrArg (fun p => Polynomial.coeff p 0) hH
      simpa using this
    exact (mul_left_cancel₀ hh₀0 hc).symm
  -- the coefficients of `H` above the constant one are divisible by `ρ`
  have hHcoeff : ∀ j, 1 ≤ j → ρ ∣ H.coeff j := by
    intro j hj
    obtain ⟨k, rfl⟩ : ∃ k, j = k + 1 := ⟨j - 1, by omega⟩
    have hcj : h.coeff (k + 1) * M ^ (k + 1) = h.coeff 0 * H.coeff (k + 1) := by
      have := congrArg (fun p => Polynomial.coeff p (k + 1)) hH
      simpa [coeff_scale] using this
    have hexp : H.coeff (k + 1) = h.coeff (k + 1) * (ρ ^ (k + 1) * h.coeff 0 ^ k) := by
      apply mul_left_cancel₀ hh₀0
      rw [← hcj, hMdef]; ring
    rw [hexp]
    exact ((dvd_pow_self ρ (Nat.succ_ne_zero k)).mul_right _).mul_left _
  -- §2.1, second divisibility: `ρ ∣ v(0)·H - v(M·X)`
  have hWdvd : C ρ ∣ C (v.coeff 0) * H - scale M v := by
    rw [C_dvd_iff_dvd_coeff]
    intro j
    rw [coeff_sub, coeff_C_mul, coeff_scale]
    rcases Nat.eq_zero_or_pos j with rfl | hj
    · simp [hH0]
    · exact dvd_sub ((hHcoeff j hj).mul_left _)
        ((hρM.trans (dvd_pow_self M (by omega))).mul_left _)
  obtain ⟨W, hW⟩ := hWdvd
  exact ⟨{ h := h, f₁ := f₁, u := u, v := v, ρ := ρ, M := M, h₀ := h.coeff 0,
           H := H, W := W, g := C M * X + scale M h * W,
           hρ := hρ, hh₀ := rfl, hh₀0 := hh₀0, hn := hn, hirr := hirr, hprim := hprim,
           hfac := hfac, hbez := hbez, hM := hMdef, hH := hH.symm, hH0 := hH0,
           hW := hW.symm, hg := rfl }, rfl⟩

/-- **Existence** (spec §2).  A nonconstant `f` with `X ∤ f` admits a `Setup`:
take an irreducible factor of `f.primPart`, which is automatically primitive and
nonconstant, and has nonzero constant term because `X ∤ f`. -/
theorem setup_exists (f : ℤ[X]) (hf : 1 ≤ f.natDegree) (hX : ¬ (X ∣ f)) :
    Nonempty (Setup f) := by
  have hpp : f.primPart.IsPrimitive := isPrimitive_primPart f
  have hppdeg : f.primPart.natDegree = f.natDegree := natDegree_primPart f
  have hppu : ¬ IsUnit f.primPart := fun hu => by
    have := Polynomial.natDegree_eq_zero_of_isUnit hu
    omega
  obtain ⟨h, hirr, hdvd⟩ :=
    WfDvdMonoid.exists_irreducible_factor hppu hpp.ne_zero
  have hprim : h.IsPrimitive := isPrimitive_of_dvd hpp hdvd
  have hn : 1 ≤ h.natDegree := one_le_natDegree_of_irreducible_primitive hirr hprim
  obtain ⟨f₁, hfac⟩ := hdvd.trans (primPart_dvd f)
  have hh₀0 : h.coeff 0 ≠ 0 := fun h0 => hX (dvd_trans (X_dvd_iff.mpr h0) ⟨f₁, hfac⟩)
  obtain ⟨S, -⟩ := setup_of_factor hirr hprim hn hh₀0 hfac
  exact ⟨S⟩

end CriticalValues
