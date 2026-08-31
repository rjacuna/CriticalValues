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

/-- `H` has the degree of `h`, so in particular it is nonconstant.  This is what
stops `H` from hiding inside the content `c` of `g'` in Corollary 2. -/
theorem Setup.natDegree_H {f : ℤ[X]} (S : Setup f) : S.H.natDegree = S.h.natDegree := by
  have h1 : (C S.h₀ * S.H).natDegree = S.H.natDegree := by
    rw [natDegree_C_mul S.hh₀0]
  rw [← h1, S.hH, natDegree_scale S.hM0]

/-- Theorem 1 for a given `Setup`, with the degree bounds of Lemma E carried
along: `deg g ≥ 2` and `deg H = deg h ≥ 1`. -/
theorem Setup.main {f : ℤ[X]} (S : Setup f) :
    ∃ g H : ℤ[X], 2 ≤ g.natDegree ∧ Irreducible H ∧ 1 ≤ H.natDegree ∧
      H ∣ derivative g ∧ H ^ 2 ∣ f.comp g :=
  ⟨S.g, S.H, S.two_le_natDegree_g, S.lemD, S.natDegree_H ▸ S.hn,
    S.H_dvd_derivative, S.sq_dvd_comp⟩

/-- The degenerate case (spec §6): if `X ∣ f`, take `g = X²` and `H = X`. -/
theorem main_of_X_dvd {f : ℤ[X]} (hX : X ∣ f) :
    ∃ g H : ℤ[X], 2 ≤ g.natDegree ∧ Irreducible H ∧ 1 ≤ H.natDegree ∧
      H ∣ derivative g ∧ H ^ 2 ∣ f.comp g := by
  obtain ⟨f₂, rfl⟩ := hX
  refine ⟨X ^ 2, X, by simp, irreducible_X, by simp, ⟨C 2, ?_⟩, ⟨f₂.comp (X ^ 2), ?_⟩⟩
  · rw [derivative_X_pow]; push_cast; ring
  · rw [mul_comp, X_comp]

/-- **Theorem 1, strengthened.**  The `g` produced always has `deg g ≥ 2` and
the `H` always has `deg H ≥ 1` — in the main case by Lemma E, in the degenerate
case because `g = X²` and `H = X`.  Neither needs `deg f > 1`: `deg f ≥ 1` is
enough, and `deg g = deg h + deg W ≥ 2` never looks at `deg f` at all. -/
theorem main_strong (f : ℤ[X]) (hf : 1 ≤ f.natDegree) :
    ∃ g H : ℤ[X], 2 ≤ g.natDegree ∧ Irreducible H ∧ 1 ≤ H.natDegree ∧
      H ∣ derivative g ∧ H ^ 2 ∣ f.comp g := by
  by_cases hX : X ∣ f
  · exact main_of_X_dvd hX
  · obtain ⟨S⟩ := setup_exists f hf hX
    exact S.main

/-- **Theorem 1** (spec §1.1).  For every nonconstant `f ∈ ℤ[X]` there are
`g, H ∈ ℤ[X]` with `H` irreducible, `H ∣ g'` and `H² ∣ f ∘ g`. -/
theorem main (f : ℤ[X]) (hf : 1 ≤ f.natDegree) :
    ∃ g H : ℤ[X], Irreducible H ∧ H ∣ derivative g ∧ H ^ 2 ∣ f.comp g := by
  obtain ⟨g, H, -, hirr, -, h1, h2⟩ := main_strong f hf
  exact ⟨g, H, hirr, h1, h2⟩

/-! ### Corollary 2 -/

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

/-- **Corollary 2 with no side condition.**  The `g' ≠ 0` hypothesis of `cor2`
is never a real restriction: the construction always returns `deg g ≥ 2`, so in
characteristic zero `g' ≠ 0` comes for free.  Hence for every nonconstant `f`
there is a `g` whose derivative is nonzero and for which *every* factorization
of `g'` into irreducibles has a factor whose square divides `f ∘ g`. -/
theorem main_cor2 (f : ℤ[X]) (hf : 1 ≤ f.natDegree) (ι : Type*) :
    ∃ g : ℤ[X], derivative g ≠ 0 ∧
      ∀ (s : Finset ι) (G : ι → ℤ[X]) (c : ℤ), (∀ i ∈ s, Irreducible (G i)) →
        derivative g = C c * ∏ i ∈ s, G i → ∃ i ∈ s, G i ^ 2 ∣ f.comp g := by
  obtain ⟨g, H, hdeg, hirr, hHdeg, h1, h2⟩ := main_strong f hf
  have hg' : derivative g ≠ 0 := derivative_ne_zero.mpr (by omega)
  exact ⟨g, hg', fun s G c hGirr hfact => cor2 hirr hHdeg hg' h1 h2 hGirr hfact⟩

end CriticalValues
