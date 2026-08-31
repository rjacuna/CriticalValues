# Critical values of integer polynomials — a formalization spec

**Target.** For every nonconstant `f ∈ ℤ[X]` there is `g ∈ ℤ[X]` and an irreducible `H ∈ ℤ[X]`
with `H ∣ g'` and `H² ∣ f(g)`. Equivalently: every algebraic number is a critical value of
some integer polynomial.

The proof below is deliberately **root-free**: no algebraic closure, no minimal polynomials,
no splitting fields. Everything reduces to two exact polynomial identities plus an induction
on the prime factors of an integer. Algebraic number theory appears only in the *statement*
of the corollary, never in the proof of the main theorem.

---

## 1. Statement

### 1.1 Main theorem (the form to formalize)

> **Theorem 1.** Let `f ∈ ℤ[X]`, `f` nonconstant. Then there exist `g, H ∈ ℤ[X]` with
> `H` irreducible in `ℤ[X]`, `1 ≤ deg H`, such that
>
> - `H ∣ derivative g` in `ℤ[X]`, and
> - `H^2 ∣ f.comp g` in `ℤ[X]`.

### 1.2 Headline corollary (the original problem)

> **Corollary 2.** With `g` as above, write `derivative g = c · ∏ gᵢ` with `gᵢ` irreducible in
> `ℤ[X]`. Then `gᵢ² ∣ f.comp g` for at least one `i`.

Immediate from Theorem 1: `H` is irreducible and divides `derivative g`, so `H` is an
associate of some `gᵢ`, and associates have the same square.

### 1.3 Critical-value corollary

> **Corollary 3.** For every `α ∈ ℚ̄` there are `g ∈ ℤ[X]` and `β ∈ ℚ̄` with
> `g(β) = α` and `g'(β) = 0`. Conversely every critical value of a nonconstant `g ∈ ℤ[X]`
> is algebraic. Hence `{critical values of ℤ[X]} = ℚ̄` exactly.

The converse direction is trivial (`g' ≠ 0` in characteristic zero, so its roots are algebraic,
and `g` maps algebraic to algebraic). The forward direction is Theorem 1's construction
evaluated at `β = α/M`; see §7.

**Formalization order.** Theorem 1 → Corollary 2 → Corollary 3. Corollary 3 needs
`ℚ̄`/`IsAlgClosed` API and is the only place roots appear; Theorem 1 and Corollary 2 do not.

---

## 2. Construction

Fix the following data. All of it is explicit and computable.

| Symbol | Definition | Lives in |
|---|---|---|
| `h` | a primitive irreducible factor of `f` in `ℤ[X]` with `h(0) ≠ 0` | `ℤ[X]` |
| `f₁` | the cofactor, `f = h * f₁` | `ℤ[X]` |
| `n` | `deg h ≥ 1` | `ℕ` |
| `h₀` | `h(0) ≠ 0` | `ℤ` |
| `u, v, ρ` | any Bézout data: `u*h + v*h' = C ρ` with `ρ ≠ 0` | `ℤ[X], ℤ[X], ℤ` |
| `M` | `ρ * h₀` (note `M ≠ 0`) | `ℤ` |
| `H` | `h(M·X) / h₀` | `ℤ[X]` |
| `W` | `(v(0) * H − v(M·X)) / ρ` | `ℤ[X]` |
| `g` | `M·X + h(M·X) * W` `= M·X + h₀ * H * W` | `ℤ[X]` |

Here `h'` denotes `derivative h`, and `p(M·X)` is `p.comp (C M * X)` (a ring hom in `p`,
which is worth having as a local abbreviation in Lean — call it `scale M`).

**Existence of the Bézout data.** `h` is irreducible in `ℤ[X]` and primitive, hence irreducible
in `ℚ[X]` (Gauss). Char 0 gives `h' ≠ 0` and `deg h' < deg h`, so `h ∤ h'`, so `gcd(h,h') = 1`
in `ℚ[X]`. Bézout in `ℚ[X]` and clearing denominators gives `u, v ∈ ℤ[X]` and `ρ ∈ ℤ \ {0}`.
One canonical choice is `ρ = Res(h, h')`, but **any** nonzero `ρ` in the elimination ideal works,
and the smaller `ρ` is, the smaller the output. Nothing below needs `ρ` to be the resultant.

**Existence of `h`.** `f` nonconstant ⇒ `f` has an irreducible factor. If that factor is `±X`,
we are in the degenerate case of §6; otherwise it is primitive after dividing by its content
(irreducible factors in `ℤ[X]` of positive degree are automatically primitive) and `h(0) ≠ 0`
because `h(0) = 0` would force `X ∣ h`.

### 2.1 Integrality (Lemma I)

> `H ∈ ℤ[X]` with `H(0) = 1` and `deg H = n`; `W ∈ ℤ[X]` with `W(0) = 0`.

Coefficientwise, writing `h = Σ hⱼ Xʲ` and `v = Σ vⱼ Xʲ`:

- `H` has coefficients `H₀ = 1` and, for `j ≥ 1`, `Hⱼ = hⱼ Mʲ / h₀ = hⱼ ρʲ h₀^{j-1} ∈ ℤ`.
- `W` has coefficient `0` at `j = 0` (the two constant terms cancel: `v(0)·1 − v(0)`), and for
  `j ≥ 1` its coefficient is `(v₀ Hⱼ − vⱼ Mʲ)/ρ ∈ ℤ`, since `ρ ∣ Hⱼ` (visible in the formula
  `Hⱼ = hⱼ ρʲ h₀^{j-1}`, `j ≥ 1`) and `ρ ∣ Mʲ`.

The two facts doing the work are `h₀ ∣ M` and `ρ ∣ M`, which is the entire reason `M` was
defined as the product.

> **Lean note.** Rather than defining `H` and `W` by division, *define them by their
> coefficients* (or as the explicit sums above) and prove the defining identities
> `h₀ * H = h(M·X)` and `ρ * W = v(0) * H − v(M·X)` as lemmas. Those two identities are the
> only properties of `H, W` used afterwards, alongside `H(0) = 1`, `W(0) = 0`. This avoids
> any division in `ℤ[X]` and makes §3 pure `ring`/`linear_combination` work.

---

## 3. The two identities

Both are exact identities in `ℤ[X]` — no congruences, no roots, no primality. Given the
defining equations, each should fall to `linear_combination` or explicit rewriting.

Throughout, `p̃ := p(M·X)` for brevity.

### Lemma A (derivative)

> `ρ * derivative g = H * A`, where `A := M*h₀*ũ + M*v(0)*h̃' + ρ*h₀*derivative W ∈ ℤ[X]`.

*Derivation.* From `g = M·X + h̃ * W`:

```
derivative g = M + M * h̃' * W + h̃ * derivative W
```

(chain rule; the `M` factor comes from `derivative (h(M·X)) = M * h'(M·X)`). Multiply by `ρ`
and substitute `ρW = v(0)H − ṽ` and `h̃ = h₀H`:

```
ρ * derivative g = ρM − M * h̃' * ṽ + H * (M*v(0)*h̃' + ρ*h₀*derivative W)
```

Scaling the Bézout relation `u*h + v*h' = ρ` by `X ↦ M·X` gives `ũ*h̃ + ṽ*h̃' = ρ`, i.e.
`h̃' * ṽ = ρ − ũ * h₀ * H`. Hence `ρM − M*h̃'*ṽ = M*h₀*ũ*H`, and the claim follows. ∎

### Lemma B (value)

> `ρ * (f.comp g) = H² * D` for an explicit `D ∈ ℤ[X]`.

*Derivation.* Let `B := h₀ * H * W`, so `g = M·X + B`. Taylor to second order (see §5.1):

```
f.comp g = f̃ + f̃' * B + B² * k          for some k ∈ ℤ[X]
```

Since `f = h * f₁` we get `f̃ = h̃ * f̃₁ = h₀ * H * f̃₁`, so

```
f.comp g = h₀ * H * (f̃₁ + f̃' * W) + H² * (h₀² * W² * k)      ... (∗)
```

Now compute `ρ * (f̃₁ + f̃' * W)`. Using `ρW = v(0)H − ṽ` and `f' = h'f₁ + h f₁'` (scaled):

```
f̃' * ṽ = h̃' * ṽ * f̃₁ + h̃ * f̃₁' * ṽ = (ρ − ũ h₀ H) f̃₁ + h₀ H f̃₁' ṽ
```

so `ρ f̃₁ − f̃' ṽ = h₀ H (ũ f̃₁ − ṽ f̃₁')`, and therefore

```
ρ * (f̃₁ + f̃' * W) = H * C,    C := h₀ * (ũ * f̃₁ − ṽ * f̃₁') + v(0) * f̃'
```

Substituting into `ρ ×` (∗):

```
ρ * (f.comp g) = H² * D,    D := h₀ * C + ρ * h₀² * W² * k
```
∎

> **Lean note.** Lemma B is the crux. Prove it as a single `linear_combination` from four
> hypotheses: `hH : h₀ * H = h̃`, `hW : ρ * W = C (v.eval 0) * H − ṽ`, the scaled Bézout
> `hB : ũ * h̃ + ṽ * h̃' = C ρ`, the factorization `hf : f = h * f₁`, the product rule
> `hd : derivative f = derivative h * f₁ + h * derivative f₁`, and the Taylor step §5.1.
> Nothing else about `f, h, u, v, ρ` is used — in particular *irreducibility of `h` is never
> used in §3*. It is needed only to produce the Bézout data and for §5.3.

---

## 4. Descent: removing `ρ`

> **Lemma C.** Let `P, K ∈ ℤ[X]`, `ρ ∈ ℤ`, `ρ ≠ 0`, and suppose `K.coeff 0` is a unit
> (here `= ±1`). If `K ∣ ρ * P` in `ℤ[X]` then `K ∣ P` in `ℤ[X]`.

*Proof by strong induction on the number of prime factors of `|ρ|`.* If `ρ = ±1` there is
nothing to do. Otherwise pick a prime `p ∣ ρ`, write `ρ = p * ρ₁`, and let `ρ * P = K * D`.
Reduce mod `p`: in `𝔽ₚ[X]` we get `0 = K̄ * D̄`. Since `K.coeff 0 = ±1 ≢ 0 (mod p)`, `K̄ ≠ 0`,
and `𝔽ₚ[X]` is a domain, so `D̄ = 0`, i.e. `D = p * D₁`. Cancelling `p` in the domain `ℤ[X]`
gives `ρ₁ * P = K * D₁`. Induct. ∎

Applying Lemma C with `K = H` (Lemma A) and `K = H²` (Lemma B; `(H²).coeff 0 = 1`):

> **Corollary C'.** `H ∣ derivative g` and `H² ∣ f.comp g`, both in `ℤ[X]`.

> **Lean note.** This step is *why* the construction normalizes `H(0) = 1` rather than making
> `H` monic. Two alternative proofs if the induction is awkward:
> (a) `H(0) = 1` makes `H` a unit in `ℤ⟦X⟧`, so `(f.comp g) * H⁻²  ∈ ℤ⟦X⟧`; it is also `D/ρ ∈ ℚ[X]`;
> and `ℚ[X] ∩ ℤ⟦X⟧ = ℤ[X]`.
> (b) Gauss: `H` is primitive irreducible hence prime in `ℤ[X]`, and `H ∤ ρ` by degree.
> Route (b) needs §5.3 first; routes (a) and the induction above need nothing.

---

## 5. Supporting lemmas

### 5.1 Taylor to second order

> For `f ∈ ℤ[X]` and `A, B` in a commutative ring `R` (here `R = ℤ[X]`), there is `k ∈ R` with
> `f(A + B) = f(A) + f'(A)·B + B²·k`.

Mathlib has this as a binomial-expansion / Taylor lemma about `eval`; the version needed here
is for `Polynomial.comp` in `ℤ[X]`, which is `eval` in the ring `ℤ[X]` after pushing `f` up
along `C : ℤ[X] → (ℤ[X])[X]`. Either reuse the library lemma through that identification or
prove it directly by induction on `f` (`f = X` and `f = C a` base cases, additivity, and the
multiplicative step). *Verify the exact Mathlib name before relying on it.*

### 5.2 Nondegeneracy

> **Lemma E.** `W ≠ 0`, `1 ≤ deg W`, `deg g = n + deg W ≥ 2`, and `derivative g ≠ 0`.

*Proof.* If `W = 0` then `ṽ = v(0) * H`. Comparing with `h₀ H = h̃`, this says
`h₀ * ṽ = v(0) * h̃`, i.e. `h₀ * v = v(0) * h` after undoing the (injective) scaling. Then
`h ∣ h₀ v` in `ℚ[X]`, so `v = (v(0)/h₀) * h`, and the Bézout relation becomes
`ρ = h * (u + (v(0)/h₀) h')`, forcing `deg h = 0` — contradiction with `n ≥ 1`. So `W ≠ 0`,
and `W(0) = 0` then gives `deg W ≥ 1`.

Since `M ≠ 0`, `deg h̃ = n`, so `deg (h̃ * W) = n + deg W ≥ n + 1 ≥ 2 > 1 = deg (M·X)`; no
cancellation, and `deg g = n + deg W`. Char 0 and `deg g ≥ 1` give `derivative g ≠ 0`. ∎

If the Bézout data is chosen with `deg v < n` (automatic for the subresultant/`Res` choice)
then `deg W ≤ n` and hence **`n + 1 ≤ deg g ≤ 2n`**. The lower bound is sharp and forced:
`H ∣ derivative g` gives `deg g ≥ n + 1` for *any* solution.

### 5.3 Irreducibility of `H`

> **Lemma D.** `H` is irreducible in `ℤ[X]`.

*Proof.* `h` primitive irreducible ⇒ irreducible in `ℚ[X]` (Gauss). For `M ≠ 0`, `X ↦ M·X` is a
`ℚ`-algebra automorphism of `ℚ[X]`, so `h̃` is irreducible in `ℚ[X]`; `H = h̃ / h₀` differs from
it by a unit of `ℚ`, so `H` is irreducible in `ℚ[X]`. And `H(0) = 1` ⇒ `H` primitive. Primitive
plus irreducible over `ℚ` ⇒ irreducible in `ℤ[X]` (Gauss again). ∎

This is the only place Gauss's lemma is needed. Mathlib file:
`Mathlib/RingTheory/Polynomial/GaussLemma.lean` (`IsPrimitive.Int.irreducible_iff_irreducible_map_cast`
and neighbours — *check current names*).

---

## 6. Degenerate case `X ∣ f`

If every irreducible factor of `f` is `±X`, i.e. `f = c·Xᵏ` with `k ≥ 1`, take

```
g = X²,   H = X
```

Then `derivative g = 2X`, so `H ∣ derivative g`; and `f.comp g = c·X^{2k}`, so `H² ∣ f.comp g`
since `2k ≥ 2`. `X` is irreducible in `ℤ[X]`.

More simply: the case split is only on whether `f` has *some* irreducible factor `h` with
`h(0) ≠ 0`. If yes, run §2. If no, `f = c·Xᵏ` and the above applies.

---

## 7. Corollary 3 (critical values)

Let `α ∈ ℚ̄`, `h` its primitive integral minimal polynomial. If `α = 0` take `g = X²`, `β = 0`.
Otherwise `h(0) ≠ 0`, run the construction of §2 with `f = h` (so `f₁ = 1`), and set
`β := α / M`. Then `H(β) = h(Mβ)/h₀ = h(α)/h₀ = 0`, and evaluating the definitions:

```
W(β) = (v(0)·H(β) − v(α))/ρ = −v(α)/ρ = −1/h'(α)
g(β) = Mβ + h(α)·W(β) = α
g'(β) = M + M·h'(α)·W(β) + h(α)·W'(β) = M(1 − 1) = 0
```

using `v(α) h'(α) = ρ` from Bézout at `α`, and `h(α) = 0`.

So `β = α/M` is a critical point of `g` with critical value `α`. The ring at work is
`ℤ[β] = ℤ[α/M] ⊇ ℤ[α][1/ρ]`: dividing `α` by `M` makes all higher Taylor coefficients
integral, while `H(0) = 1` makes `β` a *unit* in `ℤ[β]`, which is what permits trading the
constant term of `1/h'(α)` for higher-degree terms.

**Not needed anywhere:** the class group of `ℚ(α)`, the unit group `𝒪_K^×`, monogenicity of
`𝒪_K`, or any Thue/index-form solvability. `ℤ[β]` is not an order in `𝒪_K` — `β` is not an
algebraic integer — and the relevant units are `S`-units manufactured by the construction.

---

## 8. Test vectors

Each identity below is a closed `ring`-checkable statement; good smoke tests for the
formalized construction and for `#eval`-ing a computable version of it.

**8.1 `f = q·X − p`** (`p ≠ 0`; `u = 0, v = 1, ρ = q`, `h₀ = −p`, `M = −pq`, `H = q²X + 1`,
`W = qX`):

```
g = −p q³ X² − 2 p q X
derivative g = −2pq (q²X + 1)
f.comp g     = −p (q²X + 1)²
```

**8.2 `f = X² + 1`** (`u = 2, v = −X, ρ = 2`, `h₀ = 1`, `M = 2`, `H = 4X² + 1`, `W = X`):

```
g = 4X³ + 3X
derivative g = 3(4X² + 1)
f.comp g     = (4X² + 1)²(X² + 1)
```

Note `𝒪_K^× = {±1, ±i}` has rank 0 and `ℤ[i/2] = ℤ[i][1/2]` supplies the unit `1 + i`.
Also `deg g = 3 = n + 1`, meeting the lower bound.

**8.3 `f = X³ − 2`** (`u = 3, v = −X, ρ = −6`, `h₀ = −2`, `M = 12`, `H = 1 − 864X³`, `W = −2X`):

```
g = −3456X⁴ + 16X
derivative g = 16(1 − 864X³)
```

**8.4 `f = X³ − X − 1`** — the construction gives `M = 23` and a sextic. A hand-tuned quintic
also works and is a useful independent check of the *statement* (not of the construction):

```
g = −24334X⁵ + 39675X⁴ − 26450X³ + 9085X² − 1610X + 118
H = 23X³ − 23X² + 8X − 1
derivative g = −230(23X − 7)·H
H² ∣ f.comp g     (cofactor of degree 9)
```

**8.5 Non-monogenic check.** `f = X³ − X² − 2X − 8` (Dedekind's field: `2` is a common index
divisor, `𝒪_K` is not monogenic). The construction goes through unchanged with `M = 4024`.

---

## 9. Suggested Lean skeleton

Names below are sketches, not verified Mathlib API. Everything is over `ℤ[X]`; write
`h'` for `derivative h` and `scale M p` for `p.comp (C M * X)`.

```lean
-- §2, definitions (take H, W as data with their defining equations as hypotheses)
structure Setup (f : ℤ[X]) where
  h u v f₁ : ℤ[X]
  ρ M h₀ : ℤ
  H W g  : ℤ[X]
  hρ    : ρ ≠ 0
  hh₀   : h.coeff 0 = h₀ ∧ h₀ ≠ 0
  hn    : 1 ≤ h.natDegree
  hirr  : Irreducible h
  hprim : h.IsPrimitive
  hfac  : f = h * f₁
  hbez  : u * h + v * derivative h = C ρ
  hM    : M = ρ * h₀
  hH    : C h₀ * H = scale M h            -- H = h(MX)/h₀
  hH0   : H.coeff 0 = 1
  hW    : C ρ * W = C (v.coeff 0) * H - scale M v
  hg    : g = C M * X + scale M h * W

-- §3
lemma lemA (S : Setup f) : ∃ A, C S.ρ * derivative S.g = S.H * A
lemma lemB (S : Setup f) : ∃ D, C S.ρ * (f.comp S.g) = S.H ^ 2 * D

-- §4
lemma descent {P K : ℤ[X]} {ρ : ℤ} (hρ : ρ ≠ 0) (hK : IsUnit (K.coeff 0))
    (hd : K ∣ C ρ * P) : K ∣ P

-- §5
lemma lemD (S : Setup f) : Irreducible S.H
lemma lemE (S : Setup f) : S.W ≠ 0 ∧ 2 ≤ S.g.natDegree

-- §2 existence + §6
lemma setup_exists (f : ℤ[X]) (hf : 1 ≤ f.natDegree) (hX : ¬ (X ∣ f)) : Nonempty (Setup f)

-- §1
theorem main (f : ℤ[X]) (hf : 1 ≤ f.natDegree) :
    ∃ g H : ℤ[X], Irreducible H ∧ H ∣ derivative g ∧ H ^ 2 ∣ f.comp g
```

**Anticipated friction points, in order of expected cost:**

1. **`scale M` as a ring hom** and its interaction with `derivative`
   (`derivative (scale M p) = C M * scale M (derivative p)`). Worth isolating first; it is
   used in every step of §3.
2. **§5.1 Taylor**, if the Mathlib lemma is stated for `eval` rather than `comp`.
3. **§2.1 integrality**, if `H` and `W` are defined by division rather than by coefficients.
   Defining them as data (as in the `Setup` above) sidesteps this for Theorem 1 and defers it
   to `setup_exists`.
4. **Gauss's lemma plumbing** in §5.3, purely a matter of finding current names.

Steps §3 and §4 should be cheap. §3 is `linear_combination` from the `Setup` fields;
§4 is `Nat.strong_induction` on `(|ρ|).factors.length` plus `Polynomial.map` to `ZMod p`.

---

## 10. Scope guards — do not try to strengthen these

- **`H` must be allowed to be non-monic.** The monic version is *false*: `√2` is not a critical
  value of any `g ∈ ℤ[X]` at any algebraic-integer critical point. (If `H` is monic irreducible
  with `g(β) = √2, g'(β) = 0` then `H² ∣ g² − 2` in `ℤ[X]`; mod 2, `H̄² ∣ ḡ²` gives `H̄ ∣ ḡ`, so
  `g = HA + 2B` and `H² ∣ 4HAB + 4B² − 2 = 2C` with `C̄ = 1`; monic division gives `2C = H²D`,
  then `D = 2E` and `1 = H̄²Ē`, impossible for `deg H̄ ≥ 1`.) Yet `−4√2` *is*: `g = X³ − 6X`,
  `g² − 32 = (X² − 2)²(X² − 8)`. The invariant governing the monic case is the class of `dα` in
  `Ω_{ℤ[β]/ℤ} ≅ ℤ[β]/(H'(β))`, not integrality and not units.
- **`ρ = Res(h, h')` is not required.** Any nonzero element of `(h, h') ∩ ℤ` works, and smaller
  choices give smaller `g` (test 8.2 uses `ρ = 2` where the resultant is `4`).
- **Nothing here needs `f` separable, squarefree, or primitive**, nor `deg f` bounded. A
  repeated factor of `f` only helps.
- **Characteristic zero is used** (via `h' ≠ 0`). In char `p` with `α` inseparable the whole
  approach dies (`ρ = 0`); there `g = Xᵖ` gives `f.comp g = fᵖ` but `derivative g = 0` has no
  irreducible factorization, so the statement itself degenerates.
- **Multiplicity is free.** Since `H'(β)` is a unit in `ℤ[β]`, the map `ℤ[X] → ℤ[β][Y]/(Yᵐ)`,
  `X ↦ β + Y`, is surjective, so `Hᵐ ∣ f.comp g` is achievable for every `m`. Worth stating as a
  generalization only *after* Theorem 1 lands.
- **The base ring can be any characteristic-zero UFD**; `ℤ` is used only through Gauss (§5.3)
  and prime factorization (§4). Generalize afterwards, if at all.
