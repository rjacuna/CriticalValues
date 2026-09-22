/-
Example 3 of the paper: no rational quartic has a root of `x³ - x - 1` as a
critical value.  With Proposition 1 and test vector 8.4 this makes `5` the
least degree of a solution for `x³ - x - 1`.

The argument is the paper's.  A quartic `g ∈ ℚ[X]` with `g(β) = θ`, `g'(β) = 0`
is depressed by the rational translation `x ↦ x + b/(4a)`: with `β₁ = β + b/(4a)`
and explicit `u, w, r ∈ ℚ`, `β₁³ + uβ₁ + w = 0` and `θ = a(uβ₁² + 3wβ₁) + r`.
The element `s₀ = uβ₁² + 3wβ₁` satisfies the cubic
`s(z) = z³ + 2u²z² + (u⁴ + 18uw²)z + 2u³w² + 27w⁴`, its characteristic
polynomial over `ℚ[β₁]/(β₁³ + uβ₁ + w)`; here that is checked as the explicit
identity `s(uX² + 3wX) = (X³ + uX + w)·R(X)`, so no linear algebra is needed.
Substituting `s₀ = (θ - r)/a`, clearing `a³` and reducing `θ³ = θ + 1` gives
`A₀ + A₁θ + A₂θ² = 0` with `A_i ∈ ℚ`, and `1, θ, θ²` are linearly independent
because `x³ - x - 1` is irreducible over `ℚ`.  The three equations `A_i = 0`
are the paper's, and with `σ = 27w²/u³` they collapse to
`σ⁴ + 196σ³ - 228σ² + 202σ - 23 = 0`, which has no rational root.

Both "no rational root" facts are the rational root theorem for a monic
integer polynomial (`isInteger_of_is_root_of_monic`) followed by a finite
check on the integers dividing the constant term.
-/
import CriticalValues.Classify
import Mathlib.Algebra.Polynomial.SpecificDegree
import Mathlib.RingTheory.Polynomial.RationalRoot
import Mathlib.Tactic.ComputeDegree
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.FieldSimp

set_option linter.style.header false

namespace CriticalValues

open Polynomial

/-! ### Two rational-root computations -/

/-- `x³ - x - 1` has no rational root: a rational root of a monic integer
polynomial is an integer `n`, and `n(n² - 1) = 1` forces `n = ±1`, neither of
which is a root. -/
theorem cubic_no_rat_root (q : ℚ) : q ^ 3 - q - 1 ≠ 0 := by
  intro hq
  have hmonic : (X ^ 3 - X - 1 : ℤ[X]).Monic := by monicity!
  have hroot : aeval q (X ^ 3 - X - 1 : ℤ[X]) = 0 := by simp [hq]
  obtain ⟨n, hn⟩ := isInteger_of_is_root_of_monic hmonic hroot
  have hnq : (n : ℚ) = q := by simpa using hn
  rw [← hnq] at hq
  have h : n ^ 3 - n - 1 = 0 := by exact_mod_cast hq
  have h1 : n * (n ^ 2 - 1) = 1 := by linear_combination h
  rcases Int.eq_one_or_neg_one_of_mul_eq_one h1 with rfl | rfl <;> norm_num at h

/-- The quartic of Example 3 has no rational root: an integer root divides `23`,
and none of `±1, ±23` works. -/
theorem quartic_no_rat_root (σ : ℚ) :
    σ ^ 4 + 196 * σ ^ 3 - 228 * σ ^ 2 + 202 * σ - 23 ≠ 0 := by
  intro hσ
  have hmonic : (X ^ 4 + 196 * X ^ 3 - 228 * X ^ 2 + 202 * X - 23 : ℤ[X]).Monic := by
    monicity!
  have hroot : aeval σ (X ^ 4 + 196 * X ^ 3 - 228 * X ^ 2 + 202 * X - 23 : ℤ[X]) = 0 := by
    simp only [map_add, map_sub, map_mul, map_pow, aeval_X, map_ofNat]
    linear_combination hσ
  obtain ⟨n, hn⟩ := isInteger_of_is_root_of_monic hmonic hroot
  have hnσ : (n : ℚ) = σ := by simpa using hn
  rw [← hnσ] at hσ
  have h : n ^ 4 + 196 * n ^ 3 - 228 * n ^ 2 + 202 * n - 23 = 0 := by exact_mod_cast hσ
  have hdvd : n ∣ 23 := ⟨n ^ 3 + 196 * n ^ 2 - 228 * n + 202, by linear_combination -h⟩
  have h1 : n ≤ 23 := Int.le_of_dvd (by norm_num) hdvd
  have h2 : -n ≤ 23 := Int.le_of_dvd (by norm_num) (Int.neg_dvd.mpr hdvd)
  have h3 : -23 ≤ n := by omega
  interval_cases n <;> norm_num at h

/-! ### `x³ - x - 1` over `ℚ` -/

/-- `x³ - x - 1` is irreducible over `ℚ`: a cubic with no root. -/
theorem irreducible_cubic : Irreducible (X ^ 3 - X - 1 : ℚ[X]) := by
  have hdeg : (X ^ 3 - X - 1 : ℚ[X]).natDegree = 3 := by compute_degree!
  have hp0 : (X ^ 3 - X - 1 : ℚ[X]) ≠ 0 := by
    intro h
    rw [h, natDegree_zero] at hdeg
    exact absurd hdeg (by norm_num)
  rw [irreducible_iff_roots_eq_zero_of_degree_le_three (by omega) (by omega)]
  refine Multiset.eq_zero_of_forall_notMem fun q hq => ?_
  rw [mem_roots hp0, IsRoot.def] at hq
  simp only [eval_sub, eval_pow, eval_X, eval_one] at hq
  exact cubic_no_rat_root q hq

section Cubic

variable {K : Type*} [Field K] [Algebra ℚ K]

/-- The minimal polynomial of a root `θ` of `x³ - x - 1`. -/
theorem minpoly_cubic {θ : K} (hθ : θ ^ 3 = θ + 1) : minpoly ℚ θ = X ^ 3 - X - 1 := by
  have hroot : aeval θ (X ^ 3 - X - 1 : ℚ[X]) = 0 := by
    simp only [map_sub, map_pow, aeval_X, map_one, hθ]
    ring
  exact (minpoly.eq_of_irreducible_of_monic irreducible_cubic hroot (by monicity!)).symm

/-- `deg θ = 3`. -/
theorem natDegree_minpoly_cubic {θ : K} (hθ : θ ^ 3 = θ + 1) :
    (minpoly ℚ θ).natDegree = 3 := by
  rw [minpoly_cubic hθ]
  compute_degree!

/-- `1, θ, θ²` are linearly independent over `ℚ`: a rational quadratic
vanishing at `θ` is divisible by the cubic `minpoly ℚ θ`, hence zero. -/
theorem coeffs_eq_zero {θ : K} (hθ : θ ^ 3 = θ + 1) {A₀ A₁ A₂ : ℚ}
    (h : algebraMap ℚ K A₀ + algebraMap ℚ K A₁ * θ + algebraMap ℚ K A₂ * θ ^ 2 = 0) :
    A₀ = 0 ∧ A₁ = 0 ∧ A₂ = 0 := by
  obtain ⟨U, hU⟩ : ∃ U : ℚ[X], U = C A₀ + C A₁ * X + C A₂ * X ^ 2 := ⟨_, rfl⟩
  have hUθ : aeval θ U = 0 := by
    rw [hU]
    simp only [map_add, map_mul, map_pow, aeval_C, aeval_X]
    exact h
  have hdvd : minpoly ℚ θ ∣ U := minpoly.dvd ℚ θ hUθ
  have hU0 : U = 0 := by
    by_contra hne
    have h1 := Polynomial.natDegree_le_of_dvd hdvd hne
    have h2 : U.natDegree ≤ 2 := by rw [hU]; compute_degree
    rw [natDegree_minpoly_cubic hθ] at h1
    omega
  refine ⟨?_, ?_, ?_⟩
  · have := congrArg (fun p => Polynomial.coeff p 0) hU0
    simpa [hU] using this
  · have := congrArg (fun p => Polynomial.coeff p 1) hU0
    simpa [hU] using this
  · have := congrArg (fun p => Polynomial.coeff p 2) hU0
    simpa [hU] using this

end Cubic

/-! ### No quartic -/

section Quartic

variable {K : Type*} [Field K] [Algebra ℚ K]

/-- **Example 3.**  No `g ∈ ℚ[X]` of degree `4` has a root of `x³ - x - 1` as
a critical value. -/
theorem no_quartic {θ : K} (hθ : θ ^ 3 = θ + 1) {g : ℚ[X]} (hg : g.natDegree = 4)
    {β : K} (hgβ : aeval β g = θ) (hg' : aeval β (derivative g) = 0) : False := by
  haveI : CharZero K := charZero_of_injective_algebraMap (algebraMap ℚ K).injective
  -- the coefficients of `g`
  obtain ⟨a, ha_def⟩ : ∃ a : ℚ, a = g.coeff 4 := ⟨_, rfl⟩
  obtain ⟨b, hb_def⟩ : ∃ b : ℚ, b = g.coeff 3 := ⟨_, rfl⟩
  obtain ⟨c, hc_def⟩ : ∃ c : ℚ, c = g.coeff 2 := ⟨_, rfl⟩
  obtain ⟨d, hd_def⟩ : ∃ d : ℚ, d = g.coeff 1 := ⟨_, rfl⟩
  obtain ⟨e, he_def⟩ : ∃ e : ℚ, e = g.coeff 0 := ⟨_, rfl⟩
  have hg0 : g ≠ 0 := by
    rintro rfl
    simp at hg
  have ha : a ≠ 0 := by
    have : g.coeff g.natDegree ≠ 0 := leadingCoeff_ne_zero.mpr hg0
    rw [hg] at this
    rwa [ha_def]
  have hgeq : g = C a * X ^ 4 + C b * X ^ 3 + C c * X ^ 2 + C d * X + C e := by
    conv_lhs => rw [as_sum_range_C_mul_X_pow g, hg]
    simp only [Finset.sum_range_succ, Finset.sum_range_zero, ha_def, hb_def, hc_def, hd_def,
      he_def]
    ring
  have haK : (a : K) ≠ 0 := Rat.cast_ne_zero.mpr ha
  -- the two scalar equations `g(β) = θ` and `g'(β) = 0`
  have h1 : (a : K) * β ^ 4 + b * β ^ 3 + c * β ^ 2 + d * β + e = θ := by
    have h := hgβ
    rw [hgeq] at h
    simp only [map_add, map_mul, map_pow, aeval_C, aeval_X, eq_ratCast] at h
    linear_combination h
  have h2 : 4 * (a : K) * β ^ 3 + 3 * b * β ^ 2 + 2 * c * β + d = 0 := by
    have h := hg'
    rw [hgeq] at h
    simp [derivative_add, derivative_mul, derivative_pow] at h
    linear_combination h
  -- depress: `β₁ = β + b/(4a)`
  obtain ⟨t, ht⟩ : ∃ t : ℚ, t = b / (4 * a) := ⟨_, rfl⟩
  obtain ⟨u, hu⟩ : ∃ u : ℚ, u = (c - 3 * b ^ 2 / (8 * a)) / (2 * a) := ⟨_, rfl⟩
  obtain ⟨w, hw⟩ : ∃ w : ℚ, w = (d - b * c / (2 * a) + b ^ 3 / (8 * a ^ 2)) / (4 * a) := ⟨_, rfl⟩
  obtain ⟨r, hr⟩ : ∃ r : ℚ,
      r = e - b * d / (4 * a) + b ^ 2 * c / (16 * a ^ 2) - 3 * b ^ 4 / (256 * a ^ 3) := ⟨_, rfl⟩
  obtain ⟨β₁, hβ₁def⟩ : ∃ β₁ : K, β₁ = β + (t : K) := ⟨_, rfl⟩
  have hβ₁ : β₁ ^ 3 + u * β₁ + w = 0 := by
    have key : (4 * (a : K)) * (β₁ ^ 3 + u * β₁ + w)
        = 4 * (a : K) * β ^ 3 + 3 * b * β ^ 2 + 2 * c * β + d := by
      rw [hβ₁def, hu, hw, ht]
      push_cast
      field_simp
      ring
    rw [h2] at key
    exact (mul_eq_zero.mp key).resolve_left (mul_ne_zero (by norm_num) haK)
  have hθ₁ : θ = a * (β₁ ^ 4 + 2 * u * β₁ ^ 2 + 4 * w * β₁) + r := by
    rw [← h1, hβ₁def, hu, hw, hr, ht]
    push_cast
    field_simp
    ring
  -- `θ = a s₀ + r` with `s₀ = uβ₁² + 3wβ₁`, and `s(s₀) = 0` by Cayley–Hamilton, made explicit
  obtain ⟨s₀, hs₀⟩ : ∃ s₀ : K, s₀ = u * β₁ ^ 2 + 3 * w * β₁ := ⟨_, rfl⟩
  have hs : θ = a * s₀ + r := by
    rw [hs₀]
    linear_combination hθ₁ + (a : K) * β₁ * hβ₁
  have hCH : s₀ ^ 3 + 2 * u ^ 2 * s₀ ^ 2 + (u ^ 4 + 18 * u * w ^ 2) * s₀
      + 2 * u ^ 3 * w ^ 2 + 27 * w ^ 4 = 0 := by
    rw [hs₀]
    linear_combination (u ^ 3 * β₁ ^ 3 + 9 * u ^ 2 * w * β₁ ^ 2 + (u ^ 4 + 27 * u * w ^ 2) * β₁
      + 2 * u ^ 3 * w + 27 * w ^ 3) * hβ₁
  -- clear `a³` and reduce `θ³ = θ + 1`
  have hE : (θ - r) ^ 3 + 2 * u ^ 2 * a * (θ - r) ^ 2 + (u ^ 4 + 18 * u * w ^ 2) * a ^ 2 * (θ - r)
      + (2 * u ^ 3 * w ^ 2 + 27 * w ^ 4) * a ^ 3 = 0 := by
    have hθr : θ - r = a * s₀ := by linear_combination hs
    rw [hθr]
    linear_combination (a : K) ^ 3 * hCH
  have hlin : algebraMap ℚ K (2 * a ^ 3 * u ^ 3 * w ^ 2 + 27 * a ^ 3 * w ^ 4 - a ^ 2 * r * u ^ 4
        - 18 * a ^ 2 * r * u * w ^ 2 + 2 * a * r ^ 2 * u ^ 2 - r ^ 3 + 1)
      + algebraMap ℚ K (a ^ 2 * u ^ 4 + 18 * a ^ 2 * u * w ^ 2 - 4 * a * r * u ^ 2 + 3 * r ^ 2 + 1)
        * θ
      + algebraMap ℚ K (2 * a * u ^ 2 - 3 * r) * θ ^ 2 = 0 := by
    simp only [eq_ratCast]
    push_cast
    linear_combination hE - hθ
  obtain ⟨hA0, hA1, hA2⟩ := coeffs_eq_zero hθ hlin
  -- the paper's two equations, after `r = 2au²/3`
  have E1 : 3 - a ^ 2 * u ^ 4 + 54 * a ^ 2 * u * w ^ 2 = 0 := by
    linear_combination 3 * hA1 - (2 * a * u ^ 2 - 3 * r) * hA2
  have E2 : 27 - 2 * a ^ 3 * u ^ 6 - 270 * a ^ 3 * u ^ 3 * w ^ 2 + 729 * a ^ 3 * w ^ 4 = 0 := by
    linear_combination 27 * hA0
      - (a ^ 2 * u ^ 4 + 162 * a ^ 2 * u * w ^ 2 - 12 * a * r * u ^ 2 + 9 * r ^ 2) * hA2
  have hu0 : u ≠ 0 := by
    rintro rfl
    norm_num at E1
  -- `σ = 27w²/u³`
  obtain ⟨σ, hσ⟩ : ∃ σ : ℚ, σ = 27 * w ^ 2 / u ^ 3 := ⟨_, rfl⟩
  have hσu : σ * u ^ 3 = 27 * w ^ 2 := by
    rw [hσ]
    field_simp
  have E1' : a ^ 2 * u ^ 4 * (2 * σ - 1) = -3 := by
    linear_combination E1 + 2 * a ^ 2 * u * hσu
  have E2' : a ^ 3 * u ^ 6 * (σ ^ 2 - 10 * σ - 2) = -27 := by
    linear_combination E2 + a ^ 3 * (σ * u ^ 3 + 27 * w ^ 2 - 10 * u ^ 3) * hσu
  have key : a ^ 6 * u ^ 12 * ((σ ^ 2 - 10 * σ - 2) ^ 2 + 27 * (2 * σ - 1) ^ 3) = 0 := by
    linear_combination (a ^ 3 * u ^ 6 * (σ ^ 2 - 10 * σ - 2) - 27) * E2'
      + 27 * (a ^ 4 * u ^ 8 * (2 * σ - 1) ^ 2 - 3 * a ^ 2 * u ^ 4 * (2 * σ - 1) + 9) * E1'
  have hq : (σ ^ 2 - 10 * σ - 2) ^ 2 + 27 * (2 * σ - 1) ^ 3 = 0 :=
    (mul_eq_zero.mp key).resolve_left (mul_ne_zero (pow_ne_zero _ ha) (pow_ne_zero _ hu0))
  exact quartic_no_rat_root σ (by linear_combination hq)

/-- The same for `g ∈ ℤ[X]`. -/
theorem no_quartic_int {θ : K} (hθ : θ ^ 3 = θ + 1) {g : ℤ[X]} (hg : g.natDegree = 4)
    {β : K} (hgβ : aeval β g = θ) (hg' : aeval β (derivative g) = 0) : False := by
  refine no_quartic hθ (g := g.map (algebraMap ℤ ℚ)) ?_ (β := β) ?_ ?_
  · rw [natDegree_map_eq_of_injective (algebraMap ℤ ℚ).injective_int, hg]
  · rw [aeval_map_algebraMap]; exact hgβ
  · rw [derivative_map, aeval_map_algebraMap]; exact hg'

/-- **Example 3, the least degree.**  Every nonconstant solution for a root of
`x³ - x - 1` has degree at least `5`: Proposition 1 gives `deg g > 3`, and
degree `4` is excluded.  Test vector 8.4 shows that `5` is attained. -/
theorem five_le_natDegree {θ : K} (hθ : θ ^ 3 = θ + 1) {g : ℤ[X]} (hg : 1 ≤ g.natDegree)
    {β : K} (hgβ : aeval β g = θ) (hg' : aeval β (derivative g) = 0) : 5 ≤ g.natDegree := by
  have h := natDegree_minpoly_lt hg hgβ hg'
  rw [natDegree_minpoly_cubic hθ] at h
  by_contra hlt
  exact no_quartic_int hθ (by omega) hgβ hg'

end Quartic

end CriticalValues
