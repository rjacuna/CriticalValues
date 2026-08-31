/-
The audit: the test vectors of §8, and non-vacuity.

Every identity here is closed and `ring`-checkable, so it tests the *arithmetic*
of the construction independently of the proofs above.  All four vectors of §8
are as the spec states them; the two cofactors the spec leaves unstated (8.3,
and the degree-9 one at 8.4) are recorded here explicitly.

`nonempty_Setup_X_sq_add_one` and `main_X_sq_add_one` matter for the same reason
`nonempty_HirzebruchHyp` does in the HNCI development: `Setup` is a structure
with sixteen fields, and a theorem quantified over it says nothing at all if no
instance exists.
-/
import CriticalValues.Main
import Mathlib.Tactic.ComputeDegree

set_option linter.style.header false

namespace CriticalValues

open Polynomial

/-- `simp` normalizes `C n` to `(n : ℤ[X])` for an integer `n`, and Mathlib's
`derivative_natCast` does not cover that form. -/
@[local simp] theorem derivative_intCast' (n : ℤ) : derivative ((n : ℤ[X])) = 0 := by
  rw [← C_eq_intCast]
  exact derivative_C

/-! ## 1. Test vector 8.1: `f = qX - p`

`u = 0`, `v = 1`, `ρ = q`, `h₀ = -p`, `M = -pq`, `H = q²X + 1`, `W = qX`.
Stated for all `p, q`; the construction additionally wants `p, q ≠ 0`, but the
identities themselves are unconditional. -/

theorem test81_bezout (p q : ℤ) :
    (0 : ℤ[X]) * (C q * X - C p) + 1 * derivative (C q * X - C p) = C q := by
  simp

theorem test81_derivative (p q : ℤ) :
    derivative (-(C p * C q ^ 3) * X ^ 2 - 2 * (C p * C q) * X)
      = -(2 * (C p * C q)) * (C q ^ 2 * X + 1) := by
  simp [derivative_sub, derivative_mul, derivative_pow]
  ring

theorem test81_comp (p q : ℤ) :
    (C q * X - C p).comp (-(C p * C q ^ 3) * X ^ 2 - 2 * (C p * C q) * X)
      = -C p * (C q ^ 2 * X + 1) ^ 2 := by
  simp [sub_comp, mul_comp, X_comp]
  ring

/-! ## 2. Test vector 8.2: `f = X² + 1`

`u = 2`, `v = -X`, `ρ = 2`, `h₀ = 1`, `M = 2`, `H = 4X² + 1`, `W = X`.
Note `ρ = 2` where the resultant is `4`: §10's remark that any nonzero element
of `(h, h') ∩ ℤ` will do, and that smaller is better, is live here. -/

theorem test82_bezout :
    (2 : ℤ[X]) * (X ^ 2 + 1) + (-X) * derivative (X ^ 2 + 1) = 2 := by
  simp [derivative_add]
  ring

theorem test82_derivative :
    derivative (4 * X ^ 3 + 3 * X : ℤ[X]) = 3 * (4 * X ^ 2 + 1) := by
  simp [derivative_add]
  ring

theorem test82_comp :
    (X ^ 2 + 1 : ℤ[X]).comp (4 * X ^ 3 + 3 * X) = (4 * X ^ 2 + 1) ^ 2 * (X ^ 2 + 1) := by
  simp [add_comp, pow_comp, X_comp, one_comp]
  ring

/-- `deg g = 3 = n + 1` meets the lower bound of §5.2, which `H ∣ g'` forces. -/
theorem test82_natDegree : (4 * X ^ 3 + 3 * X : ℤ[X]).natDegree = 3 := by
  compute_degree!

/-! ## 3. Test vector 8.3: `f = X³ - 2`

`u = 3`, `v = -X`, `ρ = -6`, `h₀ = -2`, `M = 12`, `H = 1 - 864X³`, `W = -2X`.
The spec stops at `g'`; the cofactor of `H²` is recorded here. -/

theorem test83_bezout :
    (3 : ℤ[X]) * (X ^ 3 - 2) + (-X) * derivative (X ^ 3 - 2) = -6 := by
  simp [derivative_sub]
  ring

theorem test83_derivative :
    derivative (-3456 * X ^ 4 + 16 * X : ℤ[X]) = 16 * (1 - 864 * X ^ 3) := by
  simp [derivative_add]
  ring

set_option maxHeartbeats 400000 in
-- `ring` expands a degree-12 composite; the default budget is not enough.
theorem test83_comp :
    (X ^ 3 - 2 : ℤ[X]).comp (-3456 * X ^ 4 + 16 * X)
      = (1 - 864 * X ^ 3) ^ 2 * (-55296 * X ^ 6 + 640 * X ^ 3 - 2) := by
  simp [sub_comp, pow_comp, X_comp]
  ring

/-! ## 4. Test vector 8.4: `f = X³ - X - 1`

A hand-tuned quintic, not the output of the construction (which gives `M = 23`
and a sextic).  It is therefore a check of the *statement* of Theorem 1, not of
the construction: an independent `g` for which some irreducible `H ∣ g'` has
`H² ∣ f ∘ g`. -/

/-- The quintic of 8.4. -/
noncomputable def g84 : ℤ[X] :=
  -24334 * X ^ 5 + 39675 * X ^ 4 - 26450 * X ^ 3 + 9085 * X ^ 2 - 1610 * X + 118

/-- The cubic of 8.4. -/
noncomputable def H84 : ℤ[X] := 23 * X ^ 3 - 23 * X ^ 2 + 8 * X - 1

set_option maxHeartbeats 1000000 in
-- `ring` works with five-digit coefficients here.
theorem test84_derivative : derivative g84 = -230 * (23 * X - 7) * H84 := by
  simp [g84, H84, derivative_add, derivative_sub]
  ring

set_option maxHeartbeats 1000000 in
-- `ring` expands the cube of a quintic against ten-digit coefficients.
/-- `H² ∣ f ∘ g`, with the degree-9 cofactor the spec mentions but does not
write out. -/
theorem test84_comp :
    (X ^ 3 - X - 1 : ℤ[X]).comp g84 = H84 ^ 2 *
      (-27238603576 * X ^ 9 + 78755092948 * X ^ 8 - 102350726386 * X ^ 7
        + 78641757343 * X ^ 6 - 39417843578 * X ^ 5 + 13374307076 * X ^ 4
        - 3072654180 * X ^ 3 + 460937273 * X ^ 2 - 40964702 * X + 1642913) := by
  simp [g84, H84, sub_comp, pow_comp, X_comp, one_comp]
  ring

/-! ## 5. §8.5 of the spec is wrong

The spec says the construction runs on Dedekind's cubic `X³ - X² - 2X - 8`
"unchanged with `M = 4024`".  Since `M = ρ h₀` and `h₀ = -8`, that needs
`ρ = -503`.  But every Bézout constant for this `h` is even, so `ρ` is never
`±503`, and `|M|` is never `4024`.  (The elimination ideal `(h, h') ∩ ℤ` is in
fact generated by `1006`, so the smallest attainable `|M|` is `8048`; only the
evenness is needed to refute `4024`, and only it is proved here.)

`503` is the discriminant of the field.  `disc(h) = -2012` and the index is `2`,
and it is the reduced resultant, not `disc(K)`, that controls `ρ`. -/

/-- Dedekind's non-monogenic cubic, the `f` of spec §8.5. -/
noncomputable def h85 : ℤ[X] := X ^ 3 - X ^ 2 - 2 * X - 8

/-- The derivative of Dedekind's cubic. -/
theorem h85_derivative : derivative h85 = 3 * X ^ 2 - 2 * X - 2 := by
  simp [h85]

/-- `1006` *is* in the elimination ideal `(h, h') ∩ ℤ`, with an explicit
certificate — so the bound below is attained. -/
theorem test85_bezout :
    (125 - 21 * X) * h85 + (3 - 44 * X + 7 * X ^ 2) * derivative h85 = -1006 := by
  rw [h85_derivative, h85]; ring

/-- **Every** Bézout constant for `h85` is even — so `ρ = ±503` never occurs.

No reduction mod `2` is needed.  Writing `h = X²(X - 1) - 2(X + 4)` and
`h' = 3X² - 2(X + 1)` puts the relation in the shape `X² · A = C c + 2 · B`,
and reading off the constant coefficient gives `0 = c + 2·B(0)`. -/
theorem test85_even {u v : ℤ[X]} {c : ℤ}
    (hc : u * h85 + v * derivative h85 = C c) : (2 : ℤ) ∣ c := by
  have key : X ^ 2 * (u * (X - 1) + 3 * v)
      = C c + 2 * (u * (X + 4) + v * (X + 1)) := by
    rw [← hc, h85_derivative, h85]; ring
  have h0 := congrArg (fun p => Polynomial.coeff p 0) key
  simp at h0
  omega

/-- Hence the spec's `M = 4024` is unattainable: it would need `ρ = -503`. -/
theorem test85_not_4024 {u v : ℤ[X]}
    (hc : u * h85 + v * derivative h85 = C (-503)) : False := by
  have := test85_even hc
  omega

/-! ## 6. Non-vacuity -/

theorem natDegree_X_sq_add_one : (X ^ 2 + 1 : ℤ[X]).natDegree = 2 := by
  compute_degree!

theorem not_X_dvd_X_sq_add_one : ¬ (X ∣ (X ^ 2 + 1 : ℤ[X])) := by
  intro hd
  have := X_dvd_iff.mp hd
  simp at this

/-- A `Setup` exists: the structure is satisfiable, so nothing quantified over
it is vacuously true. -/
theorem nonempty_Setup_X_sq_add_one : Nonempty (Setup (X ^ 2 + 1 : ℤ[X])) :=
  setup_exists _ (by rw [natDegree_X_sq_add_one]; omega) not_X_dvd_X_sq_add_one

/-- Theorem 1 applied to `X² + 1`. -/
theorem main_X_sq_add_one :
    ∃ g H : ℤ[X], Irreducible H ∧ H ∣ derivative g ∧ H ^ 2 ∣ (X ^ 2 + 1 : ℤ[X]).comp g :=
  main _ (by rw [natDegree_X_sq_add_one]; omega)

end CriticalValues
