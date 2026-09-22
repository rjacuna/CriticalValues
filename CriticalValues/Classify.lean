/-
§3 of the paper: the classification of the solutions at a critical point, and
the lower bound on their degree.

**Theorem 1, root-free.**  The paper fixes a nonconstant `P ∈ ℤ[X]`, a root `β`
of `P - α`, writes `m_α ∘ P = m_β · h`, and says that `α` is a critical value
for `β` iff `m_α'(α) ∣ h(β)` in `ℤ[β]`; then `g₀ = P + m_β Q` with
`Q(β) = -h(β)/m_α'(α)` is a solution and the solutions are `g₀ + m_β² ℤ[X]`.

Here everything is said in `ℤ[X]`.  `m_β` is any irreducible factor `F` of
`f ∘ P`, with `f = m_α`; "`g(β) = α` and `g'(β) = 0`" is `F ∣ g - P` and
`F ∣ g'` (`IsSolution`); and "`m_α'(α) ∣ h(β)` in `ℤ[β]`" is
`∃ Q, F ∣ h + f'(P)·Q`, since the elements of `ℤ[β]` are the values `Q(β)` and
`F` divides exactly the polynomials vanishing at `β`.  The two facts the proof
needs, `F ∤ f'(P)` and `F ∤ F'`, are both degree arguments: the first through
the Bézout relation `u f + v f' = ρ`, the second because `deg F' < deg F`.

**Proposition 1** is about `deg α`, so it is stated with an actual `α` and `β`
in a field containing `ℚ`, `deg α` being the degree of `minpoly ℚ α`.
-/
import CriticalValues.Basic
import CriticalValues.Exists
import Mathlib.FieldTheory.IntermediateField.Adjoin.Basic
import Mathlib.FieldTheory.Minpoly.Field
import Mathlib.FieldTheory.Minpoly.Finite

set_option linter.style.header false

namespace CriticalValues

open Polynomial

/-! ### Solutions at a critical point -/

/-- `g` is a **solution for `β`**, a root of `F`, with critical value
`α = P(β)`: `g(β) = α` and `g'(β) = 0`, stated in `ℤ[X]` as `F ∣ g - P` and
`F ∣ g'`. -/
def IsSolution (F P g : ℤ[X]) : Prop := F ∣ g - P ∧ F ∣ derivative g

section Classification

variable {f P F h : ℤ[X]}

/-- Differentiating `f ∘ P = F h`: `f'(P) P' = F' h + F h'`. -/
theorem key_identity (hfP : f.comp P = F * h) :
    (derivative f).comp P * derivative P = derivative F * h + F * derivative h := by
  have := congrArg derivative hfP
  rw [derivative_comp, derivative_mul] at this
  linear_combination this

/-- `F ∤ f'(P)`: the Bézout relation composed with `P` reads
`u(P) f(P) + v(P) f'(P) = ρ`, and `F ∣ f(P)`, so `F ∣ f'(P)` would make the
nonconstant `F` divide the nonzero constant `ρ`. -/
theorem not_dvd_derivative_comp {u v : ℤ[X]} {ρ : ℤ} (hρ : ρ ≠ 0)
    (hbez : u * f + v * derivative f = C ρ) (hF : 1 ≤ F.natDegree)
    (hfP : f.comp P = F * h) : ¬ F ∣ (derivative f).comp P := by
  intro hd
  have hcomp : u.comp P * (F * h) + v.comp P * (derivative f).comp P = C ρ := by
    have := congrArg (fun p => p.comp P) hbez
    simpa [add_comp, mul_comp, C_comp, hfP] using this
  have hFC : F ∣ C ρ := by
    rw [← hcomp]
    exact dvd_add ((dvd_mul_right F h).mul_left _) (hd.mul_left _)
  have hne : (C ρ : ℤ[X]) ≠ 0 := by simpa using hρ
  have hle := Polynomial.natDegree_le_of_dvd hFC hne
  simp only [natDegree_C] at hle
  omega

/-- `F ∤ F'`, since `F' ≠ 0` has smaller degree. -/
theorem not_dvd_derivative_self (hF : 1 ≤ F.natDegree) : ¬ F ∣ derivative F := by
  intro hd
  have hF0 : F.natDegree ≠ 0 := by omega
  have h1 := Polynomial.natDegree_le_of_dvd hd (derivative_ne_zero.mpr hF0)
  have h2 := Polynomial.natDegree_derivative_lt hF0
  omega

/-- For `g = P + F q`, the identity
`f'(P) g' = F' (h + f'(P) q) + F (h' + f'(P) q')`. -/
theorem derivative_identity (hfP : f.comp P = F * h) (q : ℤ[X]) :
    (derivative f).comp P * derivative (P + F * q)
      = derivative F * (h + (derivative f).comp P * q)
        + F * (derivative h + (derivative f).comp P * derivative q) := by
  rw [derivative_add, derivative_mul]
  linear_combination key_identity hfP

/-- **Necessity.**  If `P + F q` is a solution then `F ∣ h + f'(P) q`: the
identity above makes `F ∣ F' (h + f'(P) q)`, and `F ∤ F'`. -/
theorem dvd_of_isSolution (hirr : Irreducible F) (hF : 1 ≤ F.natDegree)
    (hfP : f.comp P = F * h) {q : ℤ[X]} (hg' : F ∣ derivative (P + F * q)) :
    F ∣ h + (derivative f).comp P * q := by
  have h1 : F ∣ derivative F * (h + (derivative f).comp P * q) := by
    have h2 : F ∣ (derivative f).comp P * derivative (P + F * q) := hg'.mul_left _
    rw [derivative_identity hfP q] at h2
    exact (dvd_add_left (dvd_mul_right F _)).mp h2
  exact (hirr.prime.dvd_or_dvd h1).resolve_left (not_dvd_derivative_self hF)

/-- **Sufficiency.**  If `F ∣ h + f'(P) Q` then `g₀ = P + F Q` is a solution:
the identity makes `F ∣ f'(P) g₀'`, and `F ∤ f'(P)`. -/
theorem isSolution_of_dvd (hirr : Irreducible F) (hF : 1 ≤ F.natDegree)
    (hfP : f.comp P = F * h) {u v : ℤ[X]} {ρ : ℤ} (hρ : ρ ≠ 0)
    (hbez : u * f + v * derivative f = C ρ) {Q : ℤ[X]}
    (hQ : F ∣ h + (derivative f).comp P * Q) : IsSolution F P (P + F * Q) := by
  refine ⟨⟨Q, by ring⟩, ?_⟩
  have h1 : F ∣ (derivative f).comp P * derivative (P + F * Q) := by
    rw [derivative_identity hfP Q]
    exact dvd_add (hQ.mul_left _) (dvd_mul_right F _)
  exact (hirr.prime.dvd_or_dvd h1).resolve_left (not_dvd_derivative_comp hρ hbez hF hfP)

/-- **Theorem 1, the criterion.**  There is a solution for `β` iff
`m_α'(α) ∣ h(β)` in `ℤ[β]`, i.e. iff `F ∣ h + f'(P) Q` for some `Q ∈ ℤ[X]`. -/
theorem isSolution_iff (hirr : Irreducible F) (hF : 1 ≤ F.natDegree)
    (hfP : f.comp P = F * h) {u v : ℤ[X]} {ρ : ℤ} (hρ : ρ ≠ 0)
    (hbez : u * f + v * derivative f = C ρ) :
    (∃ g, IsSolution F P g) ↔ ∃ Q, F ∣ h + (derivative f).comp P * Q := by
  constructor
  · rintro ⟨g, ⟨q, hq⟩, hg'⟩
    have hg : g = P + F * q := by linear_combination hq
    rw [hg] at hg'
    exact ⟨q, dvd_of_isSolution hirr hF hfP hg'⟩
  · rintro ⟨Q, hQ⟩
    exact ⟨_, isSolution_of_dvd hirr hF hfP hρ hbez hQ⟩

/-- **Theorem 1, the coset.**  Once `F ∣ h + f'(P) Q`, the solutions for `β`
are exactly `P + F Q + F² ℤ[X]`. -/
theorem isSolution_iff_coset (hirr : Irreducible F) (hF : 1 ≤ F.natDegree)
    (hfP : f.comp P = F * h) {u v : ℤ[X]} {ρ : ℤ} (hρ : ρ ≠ 0)
    (hbez : u * f + v * derivative f = C ρ) {Q : ℤ[X]}
    (hQ : F ∣ h + (derivative f).comp P * Q) (g : ℤ[X]) :
    IsSolution F P g ↔ ∃ r, g = P + F * Q + F ^ 2 * r := by
  constructor
  · rintro ⟨⟨q, hq⟩, hg'⟩
    have hg : g = P + F * q := by linear_combination hq
    rw [hg] at hg'
    have hq' : F ∣ h + (derivative f).comp P * q := dvd_of_isSolution hirr hF hfP hg'
    have hdiff : F ∣ (derivative f).comp P * (q - Q) := by
      have := dvd_sub hq' hQ
      convert this using 1
      ring
    obtain ⟨r, hr⟩ :=
      (hirr.prime.dvd_or_dvd hdiff).resolve_left (not_dvd_derivative_comp hρ hbez hF hfP)
    exact ⟨r, by rw [hg]; linear_combination F * hr⟩
  · rintro ⟨r, rfl⟩
    obtain ⟨-, hg₀'⟩ := isSolution_of_dvd hirr hF hfP hρ hbez hQ
    refine ⟨⟨Q + F * r, by ring⟩, ?_⟩
    have hd : derivative (P + F * Q + F ^ 2 * r)
        = derivative (P + F * Q) + F * (C 2 * derivative F * r + F * derivative r) := by
      simp only [derivative_add, derivative_mul, derivative_sq]
      ring
    rw [hd]
    exact dvd_add hg₀' (dvd_mul_right F _)

/-- A solution satisfies Petrov's two conditions: `F ∣ g'` by definition, and
`F² ∣ f ∘ g` by Taylor expansion at `P`. -/
theorem sq_dvd_comp_of_isSolution (hirr : Irreducible F) (hF : 1 ≤ F.natDegree)
    (hfP : f.comp P = F * h) {g : ℤ[X]} (hg : IsSolution F P g) :
    F ∣ derivative g ∧ F ^ 2 ∣ f.comp g := by
  obtain ⟨⟨q, hq⟩, hg'⟩ := hg
  refine ⟨hg', ?_⟩
  have hgeq : g = P + F * q := by linear_combination hq
  rw [hgeq] at hg' ⊢
  obtain ⟨c, hc⟩ := dvd_of_isSolution hirr hF hfP hg'
  obtain ⟨k, hk⟩ := comp_add_sq f P (F * q)
  rw [hk, hfP]
  exact ⟨c + k * q ^ 2, by linear_combination F * hc⟩

/-- **Theorem 1**, in one statement, with the Bézout data produced from the
irreducibility of `f`: for `f` primitive irreducible nonconstant, `P ∈ ℤ[X]`,
and `F` a nonconstant irreducible factor of `f ∘ P` with cofactor `h`,
a solution for `β` exists iff `F ∣ h + f'(P) Q` for some `Q`, and then the
solutions are exactly `P + F Q + F² ℤ[X]`. -/
theorem classification (hfirr : Irreducible f) (hfprim : f.IsPrimitive)
    (hfn : 1 ≤ f.natDegree) (hirr : Irreducible F) (hF : 1 ≤ F.natDegree)
    (hfP : f.comp P = F * h) :
    ((∃ g, IsSolution F P g) ↔ ∃ Q, F ∣ h + (derivative f).comp P * Q) ∧
      ∀ Q, F ∣ h + (derivative f).comp P * Q →
        ∀ g, IsSolution F P g ↔ ∃ r, g = P + F * Q + F ^ 2 * r := by
  obtain ⟨u, v, ρ, hρ, hbez⟩ := exists_bezout hfirr hfprim hfn
  exact ⟨isSolution_iff hirr hF hfP hρ hbez,
    fun Q hQ g => isSolution_iff_coset hirr hF hfP hρ hbez hQ g⟩

end Classification

/-! ### The same, with roots

The root-free statements above are the paper's once a root `β` of `F` is
named: by Gauss's lemma an irreducible primitive `F` with `F(β) = 0` divides
exactly the integer polynomials vanishing at `β`, so `F ∣ g - P` is
`g(β) = P(β) = α`, `F ∣ g'` is `g'(β) = 0`, and `F ∣ h + f'(P) Q` is
`h(β) + f'(α) Q(β) = 0`, which is `f'(α) ∣ h(β)` in `ℤ[β]`. -/

section Roots

variable {K : Type*} [Field K] [Algebra ℚ K]

/-- **Gauss.**  For `F` irreducible primitive with `F(β) = 0`, `F ∣ p` in
`ℤ[X]` iff `p(β) = 0`.  Over `ℚ`, `F` is a unit multiple of `minpoly ℚ β`, so
it divides `p` there, and Gauss's lemma brings the divisibility back to `ℤ[X]`. -/
theorem dvd_iff_aeval_eq_zero {F : ℤ[X]} (hirr : Irreducible F) (hprim : F.IsPrimitive)
    {β : K} (hβ : aeval β F = 0) (p : ℤ[X]) : F ∣ p ↔ aeval β p = 0 := by
  constructor
  · rintro ⟨c, rfl⟩
    simp [hβ]
  · intro hp
    have hirrQ : Irreducible (F.map (algebraMap ℤ ℚ)) := by
      rw [algebraMap_int_eq]
      exact (IsPrimitive.Int.irreducible_iff_irreducible_map_cast hprim).mp hirr
    have hβQ : aeval β (F.map (algebraMap ℤ ℚ)) = 0 := by
      rw [aeval_map_algebraMap]; exact hβ
    have hpQ : aeval β (p.map (algebraMap ℤ ℚ)) = 0 := by
      rw [aeval_map_algebraMap]; exact hp
    have hmin := minpoly.eq_of_irreducible hirrQ hβQ
    have hdvdQ : F.map (algebraMap ℤ ℚ) ∣ p.map (algebraMap ℤ ℚ) := by
      have h1 := minpoly.dvd ℚ β hpQ
      rw [← hmin] at h1
      exact (dvd_mul_right _ _).trans h1
    exact hprim.dvd_of_fraction_map_dvd_fraction_map hdvdQ

/-- `IsSolution` is "`g(β) = P(β)` and `g'(β) = 0`" at any root `β` of `F`. -/
theorem isSolution_iff_aeval {F P g : ℤ[X]} (hirr : Irreducible F) (hprim : F.IsPrimitive)
    {β : K} (hβ : aeval β F = 0) :
    IsSolution F P g ↔ aeval β g = aeval β P ∧ aeval β (derivative g) = 0 := by
  unfold IsSolution
  rw [dvd_iff_aeval_eq_zero hirr hprim hβ, dvd_iff_aeval_eq_zero hirr hprim hβ, map_sub,
    sub_eq_zero]

/-- **Theorem 1, as in the paper.**  Let `β` be a root of `F`, `α = P(β)`, and
`f ∘ P = F h`.  Then `α` is a critical value for `β` iff
`h(β) + f'(α) Q(β) = 0` for some `Q ∈ ℤ[X]`, that is, iff `f'(α) ∣ h(β)` in
`ℤ[β]`. -/
theorem critical_value_iff {f P F h : ℤ[X]} (hirr : Irreducible F) (hprim : F.IsPrimitive)
    (hF : 1 ≤ F.natDegree) {β : K} (hβ : aeval β F = 0) (hfP : f.comp P = F * h)
    {u v : ℤ[X]} {ρ : ℤ} (hρ : ρ ≠ 0) (hbez : u * f + v * derivative f = C ρ) :
    (∃ g : ℤ[X], aeval β g = aeval β P ∧ aeval β (derivative g) = 0) ↔
      ∃ Q : ℤ[X], aeval β h + aeval (aeval β P) (derivative f) * aeval β Q = 0 := by
  constructor
  · rintro ⟨g, hg⟩
    obtain ⟨Q, hQ⟩ := (isSolution_iff hirr hF hfP hρ hbez).mp
      ⟨g, (isSolution_iff_aeval hirr hprim hβ).mpr hg⟩
    refine ⟨Q, ?_⟩
    have := (dvd_iff_aeval_eq_zero hirr hprim hβ _).mp hQ
    simpa [aeval_comp] using this
  · rintro ⟨Q, hQ⟩
    have hQ' : F ∣ h + (derivative f).comp P * Q :=
      (dvd_iff_aeval_eq_zero hirr hprim hβ _).mpr (by simpa [aeval_comp] using hQ)
    obtain ⟨g, hg⟩ := (isSolution_iff hirr hF hfP hρ hbez).mpr ⟨Q, hQ'⟩
    exact ⟨g, (isSolution_iff_aeval hirr hprim hβ).mp hg⟩

end Roots

/-! ### Proposition 1: the degree of a solution exceeds the degree of `α` -/

section Degree

variable {K : Type*} [Field K] [Algebra ℚ K]

open scoped IntermediateField

/-- **Proposition 1.**  If `g ∈ ℤ[X]` is nonconstant with `g(β) = α` and
`g'(β) = 0`, then `deg g > deg α`.

`β` is a root of `g' ≠ 0`, so `minpoly ℚ β ∣ g'` and `deg β ≤ deg g' = deg g - 1`;
and `α = g(β)` lies in `ℚ(β)`, so `deg α ≤ deg β`. -/
theorem natDegree_minpoly_lt {g : ℤ[X]} {α β : K} (hg : 1 ≤ g.natDegree)
    (hgβ : aeval β g = α) (hg' : aeval β (derivative g) = 0) :
    (minpoly ℚ α).natDegree < g.natDegree := by
  have hinj : Function.Injective (algebraMap ℤ ℚ) := (algebraMap ℤ ℚ).injective_int
  have hg'0 : derivative g ≠ 0 := derivative_ne_zero.mpr (by omega)
  have hg'Q : (derivative g).map (algebraMap ℤ ℚ) ≠ 0 :=
    (Polynomial.map_ne_zero_iff hinj).mpr hg'0
  have hg'β : aeval β ((derivative g).map (algebraMap ℤ ℚ)) = 0 := by
    rw [aeval_map_algebraMap]; exact hg'
  -- `deg β ≤ deg g' < deg g`
  have hβ : IsIntegral ℚ β := isAlgebraic_iff_isIntegral.mp ⟨_, hg'Q, hg'β⟩
  have h1 : (minpoly ℚ β).natDegree ≤ (derivative g).natDegree := by
    have := Polynomial.natDegree_le_of_dvd (minpoly.dvd ℚ β hg'β) hg'Q
    rwa [natDegree_map_eq_of_injective hinj] at this
  have h2 : (derivative g).natDegree < g.natDegree := natDegree_derivative_lt (by omega)
  -- `deg α ≤ deg β`, since `α = g(β) ∈ ℚ(β)`
  have h3 : (minpoly ℚ α).natDegree ≤ (minpoly ℚ β).natDegree := by
    haveI : FiniteDimensional ℚ ℚ⟮β⟯ := IntermediateField.adjoin.finiteDimensional hβ
    set α' : ℚ⟮β⟯ := aeval (IntermediateField.AdjoinSimple.gen ℚ β) (g.map (algebraMap ℤ ℚ))
      with hα'
    have hα'K : algebraMap ℚ⟮β⟯ K α' = α := by
      rw [hα', ← aeval_algebraMap_apply, IntermediateField.AdjoinSimple.algebraMap_gen,
        aeval_map_algebraMap, hgβ]
    have hmin : minpoly ℚ α = minpoly ℚ α' := by
      rw [← hα'K, minpoly.algebraMap_eq (algebraMap ℚ⟮β⟯ K).injective]
    rw [hmin, ← IntermediateField.adjoin.finrank hβ]
    exact minpoly.natDegree_le α'
  omega

end Degree

end CriticalValues
