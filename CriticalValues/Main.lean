/-
§1 and §6 of the spec: Theorem 1 and Corollary 2.

The case split is only on whether `X ∣ f`.  If it does, §6's `g = X²`, `H = X`
settles it outright — note this covers `f = X·(X²+1)` as well as `f = c·Xᵏ`, so
the split is on divisibility by `X`, not on `f` being a monomial.  If it does
not, every irreducible factor of `f` has nonzero constant term and `setup_exists`
applies.
-/
import CriticalValues.Nondeg

set_option linter.style.header false

namespace CriticalValues

open Polynomial

/-- Theorem 1 for a given `Setup`: the three conclusions are `lemD` and the two
halves of Corollary C'. -/
theorem Setup.main {f : ℤ[X]} (S : Setup f) :
    ∃ g H : ℤ[X], Irreducible H ∧ H ∣ derivative g ∧ H ^ 2 ∣ f.comp g :=
  ⟨S.g, S.H, S.lemD, S.H_dvd_derivative, S.sq_dvd_comp⟩

/-- The degenerate case (spec §6): if `X ∣ f`, take `g = X²` and `H = X`. -/
theorem main_of_X_dvd {f : ℤ[X]} (hX : X ∣ f) :
    ∃ g H : ℤ[X], Irreducible H ∧ H ∣ derivative g ∧ H ^ 2 ∣ f.comp g := by
  obtain ⟨f₂, rfl⟩ := hX
  refine ⟨X ^ 2, X, irreducible_X, ⟨C 2, ?_⟩, ⟨f₂.comp (X ^ 2), ?_⟩⟩
  · rw [derivative_X_pow]; push_cast; ring
  · rw [mul_comp, X_comp]

/-- **Theorem 1** (spec §1.1).  For every nonconstant `f ∈ ℤ[X]` there are
`g, H ∈ ℤ[X]` with `H` irreducible, `H ∣ g'` and `H² ∣ f ∘ g`. -/
theorem main (f : ℤ[X]) (hf : 1 ≤ f.natDegree) :
    ∃ g H : ℤ[X], Irreducible H ∧ H ∣ derivative g ∧ H ^ 2 ∣ f.comp g := by
  by_cases hX : X ∣ f
  · exact main_of_X_dvd hX
  · obtain ⟨S⟩ := setup_exists f hf hX
    exact S.main

/-! ### Corollary 2 -/

/-- `H` has the degree of `h`, so in particular it is nonconstant.  This is what
stops `H` from hiding inside the content `c` of `g'` in Corollary 2. -/
theorem Setup.natDegree_H {f : ℤ[X]} (S : Setup f) : S.H.natDegree = S.h.natDegree := by
  have h1 : (C S.h₀ * S.H).natDegree = S.H.natDegree := by
    rw [natDegree_C_mul S.hh₀0]
  rw [← h1, S.hH, natDegree_scale S.hM0]

/-- **Corollary 2** (spec §1.2).  In any factorization `g' = c · ∏ gᵢ` into
nonconstant irreducibles, some `gᵢ² ∣ f ∘ g`.

`H` is irreducible, hence prime in the UFD `ℤ[X]`, and nonconstant, so it cannot
divide the constant `C c`; it therefore divides some `gᵢ`, and two irreducibles
with one dividing the other are associates, which have the same square. -/
theorem cor2 {f g H : ℤ[X]} {ι : Type*} {s : Finset ι} {G : ι → ℤ[X]} {c : ℤ}
    (hH : Irreducible H) (hHdeg : 1 ≤ H.natDegree) (hg' : derivative g ≠ 0)
    (hHd : H ∣ derivative g) (hH2 : H ^ 2 ∣ f.comp g)
    (hGirr : ∀ i ∈ s, Irreducible (G i))
    (hfact : derivative g = C c * ∏ i ∈ s, G i) :
    ∃ i ∈ s, G i ^ 2 ∣ f.comp g := by
  have hprime : Prime H := hH.prime
  rw [hfact] at hHd
  have hc : c ≠ 0 := by
    rintro rfl
    exact hg' (by rw [hfact]; simp)
  -- `H` is nonconstant, so it does not divide the constant `C c`
  have hnotC : ¬ H ∣ C c := by
    intro hdvd
    have hne : (C c : ℤ[X]) ≠ 0 := by simpa using hc
    have hle := Polynomial.natDegree_le_of_dvd hdvd hne
    simp only [natDegree_C] at hle
    omega
  obtain ⟨i, hi, hHi⟩ :=
    (hprime.dvd_finsetProd_iff G).mp ((hprime.dvd_mul.mp hHd).resolve_left hnotC)
  refine ⟨i, hi, ?_⟩
  have hassoc : Associated H (G i) := hH.associated_of_dvd (hGirr i hi) hHi
  exact dvd_trans (Associated.dvd (Associated.symm (Associated.pow_pow hassoc))) hH2

end CriticalValues
