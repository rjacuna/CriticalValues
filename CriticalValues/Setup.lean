/-
§2 and §3 of the spec: the construction, bundled, and the two exact identities.

`Setup f` carries the construction of §2 as *data together with its defining
equations*.  In particular `H` and `W` are fields, constrained by `hH` and `hW`,
rather than being defined by the divisions `h(M·X)/h₀` and `(v(0)H - v(M·X))/ρ`.
That is deliberate: it keeps every division out of `ℤ[X]`, so §3 below is pure
`linear_combination`, and defers the integrality argument of §2.1 to
`setup_exists`, which is the only place it is needed.

Only six of the fields are used here — `hH`, `hW`, `hbez`, `hfac`, `hg`, and the
product rule.  In particular **irreducibility of `h` plays no role in §3**; it is
needed only to produce the Bézout data in the first place, and again for
`Lemma D`.  Neither does `hM : M = ρ * h₀`: the definition of `M` as a product
is what makes §2.1 integral, and nothing in §3 asks for it.
-/
import CriticalValues.Basic
import Mathlib.RingTheory.Polynomial.Content

set_option linter.style.header false

namespace CriticalValues

open Polynomial

/-- The construction of §2, as data with its defining equations.  `f` is the
polynomial whose critical values are being produced; everything else is the
output of the construction applied to a chosen irreducible factor `h` of `f`
with `h(0) ≠ 0`. -/
structure Setup (f : ℤ[X]) where
  /-- a primitive irreducible factor of `f` with nonzero constant term -/
  h : ℤ[X]
  /-- the cofactor, `f = h * f₁` -/
  f₁ : ℤ[X]
  /-- first Bézout coefficient, `u * h + v * h' = ρ` -/
  u : ℤ[X]
  /-- second Bézout coefficient, `u * h + v * h' = ρ` -/
  v : ℤ[X]
  /-- the Bézout constant, any nonzero element of `(h, h') ∩ ℤ` -/
  ρ : ℤ
  /-- the dilation factor, `M = ρ * h₀` -/
  M : ℤ
  /-- the constant term of `h` -/
  h₀ : ℤ
  /-- `H = h(M·X)/h₀`, the irreducible factor whose square divides `f ∘ g` -/
  H : ℤ[X]
  /-- `W = (v(0)·H - v(M·X))/ρ` -/
  W : ℤ[X]
  /-- the polynomial of Theorem 1 -/
  g : ℤ[X]
  hρ : ρ ≠ 0
  hh₀ : h.coeff 0 = h₀
  hh₀0 : h₀ ≠ 0
  hn : 1 ≤ h.natDegree
  hirr : Irreducible h
  hprim : h.IsPrimitive
  hfac : f = h * f₁
  hbez : u * h + v * derivative h = C ρ
  hM : M = ρ * h₀
  hH : C h₀ * H = scale M h
  hH0 : H.coeff 0 = 1
  hW : C ρ * W = C (v.coeff 0) * H - scale M v
  hg : g = C M * X + scale M h * W

namespace Setup

variable {f : ℤ[X]} (S : Setup f)

/-- The Bézout relation dilated, `ũ h̃ + ṽ h̃' = ρ`.  `scale M` is a ring hom and
fixes constants, so this is just `congrArg`. -/
theorem hbezM :
    scale S.M S.u * scale S.M S.h + scale S.M S.v * scale S.M (derivative S.h) = C S.ρ := by
  have := congrArg (scale S.M) S.hbez
  simpa using this

/-- The factorization dilated, `f̃ = h̃ f̃₁`. -/
theorem hfacM : scale S.M f = scale S.M S.h * scale S.M S.f₁ := by
  have := congrArg (scale S.M) S.hfac
  simpa using this

/-- The product rule dilated, `f̃' = h̃' f̃₁ + h̃ f̃₁'`. -/
theorem hderivM : scale S.M (derivative f)
    = scale S.M (derivative S.h) * scale S.M S.f₁
      + scale S.M S.h * scale S.M (derivative S.f₁) := by
  have hd : derivative f = derivative S.h * S.f₁ + S.h * derivative S.f₁ := by
    conv_lhs => rw [S.hfac]
    exact derivative_mul
  rw [hd]
  simp

/-- The derivative of `g`, by the chain rule:
`g' = M + M·h̃'·W + h̃·W'`. -/
theorem derivative_g : derivative S.g
    = C S.M + C S.M * scale S.M (derivative S.h) * S.W + scale S.M S.h * derivative S.W := by
  rw [S.hg]
  simp only [derivative_add, derivative_mul, derivative_C, derivative_X, derivative_scale,
    zero_mul, mul_one, zero_add]
  ring

/-! ### Lemma A -/

/-- **Lemma A** (spec §3): `ρ · g' = H · A`, with `A` explicit.

The whole content is that the dilated Bézout relation lets `h̃' ṽ` be traded for
`ρ - ũ h₀ H`, which is what puts the leftover `ρM` inside the multiple of `H`. -/
theorem lemA : C S.ρ * derivative S.g
    = S.H * (C S.M * C S.h₀ * scale S.M S.u
      + C S.M * C (S.v.coeff 0) * scale S.M (derivative S.h)
      + C S.ρ * C S.h₀ * derivative S.W) := by
  rw [S.derivative_g]
  linear_combination
    (-(C S.ρ * derivative S.W) - C S.M * scale S.M S.u) * S.hH
    + (C S.M * scale S.M (derivative S.h)) * S.hW
    + (-(C S.M)) * S.hbezM

/-! ### Lemma B -/

/-- The inner identity of Lemma B: `ρ (f̃₁ + f̃' W) = H · C`.  Same trade as in
Lemma A, now applied to `f̃' ṽ` through the product rule. -/
theorem lemB_inner : C S.ρ * (scale S.M S.f₁ + scale S.M (derivative f) * S.W)
    = S.H * (C S.h₀ * (scale S.M S.u * scale S.M S.f₁
        - scale S.M S.v * scale S.M (derivative S.f₁))
      + C (S.v.coeff 0) * scale S.M (derivative f)) := by
  linear_combination
    (scale S.M (derivative f)) * S.hW
    + (scale S.M S.v * scale S.M (derivative S.f₁) - scale S.M S.u * scale S.M S.f₁) * S.hH
    - (scale S.M S.f₁) * S.hbezM
    - (scale S.M S.v) * S.hderivM

/-- **Lemma B** (spec §3): `ρ · (f ∘ g) = H² · D`.

Taylor to second order at `A = M·X` splits `f ∘ g` into a part divisible by
`h̃ = h₀ H` and a part divisible by `H²`; `lemB_inner` supplies the second factor
of `H` in the first part. -/
theorem lemB : ∃ D : ℤ[X], C S.ρ * (f.comp S.g) = S.H ^ 2 * D := by
  obtain ⟨k, hk⟩ := comp_add_sq f (C S.M * X) (scale S.M S.h * S.W)
  rw [← S.hg, ← scale_apply, ← scale_apply] at hk
  -- (∗): `f ∘ g = h₀ H (f̃₁ + f̃' W) + H² (h₀² W² k)`
  have hstar : f.comp S.g
      = C S.h₀ * S.H * (scale S.M S.f₁ + scale S.M (derivative f) * S.W)
        + S.H ^ 2 * (C S.h₀ ^ 2 * S.W ^ 2 * k) := by
    rw [hk, S.hfacM, ← S.hH]; ring
  refine ⟨C S.h₀ * (C S.h₀ * (scale S.M S.u * scale S.M S.f₁
      - scale S.M S.v * scale S.M (derivative S.f₁))
    + C (S.v.coeff 0) * scale S.M (derivative f))
    + C S.ρ * C S.h₀ ^ 2 * S.W ^ 2 * k, ?_⟩
  linear_combination C S.ρ * hstar + (C S.h₀ * S.H) * S.lemB_inner

end Setup

end CriticalValues
