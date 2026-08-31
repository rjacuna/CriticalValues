# Is `crit` optimal? — a survey

Short answer: **the mathematics is already optimal in the one place that matters
most, and the algorithmics are a century out of date in the one place that costs
most.** Those are different places, which is the useful part.

---

## 0. Where the time actually goes

| step | current | cost |
|---|---|---|
| `Factor.properFactor` | Kronecker's method (1882) | **exponential**, dominant |
| `Bezout.squareFreePart` | naive Euclid in `ℚ[X]` with `Data.Ratio` | coefficient swell |
| `Bezout.bezout` | extended Euclid in `ℚ[X]`, then clear denominators | coefficient swell — but see §2 |
| `Poly.mul`, `exactDiv` | schoolbook | irrelevant at these degrees |
| `Integer` arithmetic | GMP natively, `ghc-bignum` native on wasm | the real constant factor |

Note what is *not* on the list. Degrees here are single digits; the polynomials
are tiny. Karatsuba, Schönhage–Strassen, FFT-based multiplication — none of it
matters. **The complexity is in the coefficients, not the degree.** That is why
`Integer` performance dominates the arithmetic, and why algorithms that avoid
coefficient growth beat algorithms with better degree asymptotics.

## 1. The dominant cost: factoring

Kronecker's method — interpolate through divisors of sampled values — is
correct, elementary, short, and exponential in the number of divisors of those
values. It was chosen for brevity and it is by far the weakest link.

The literature, in order:

* **Berlekamp–Zassenhaus** (1967/1969). Factor mod a small prime, Hensel-lift to
  a high `p`-adic precision, then *recombine* local factors into true factors.
  Recombination is an exhaustive search over subsets — fine up to roughly 40
  local factors, exponential beyond. The classical worst case is the
  Swinnerton-Dyer polynomials, which have many local factors and no proper
  rational ones.
* **Lenstra–Lenstra–Lovász** (1982). The first polynomial-time algorithm for
  factoring in `ℤ[X]`, via lattice reduction. Famous, and for a long time not
  competitive in practice.
* **van Hoeij** (2002). Recast recombination as a *knapsack* problem and solve it
  with LLL on a much smaller lattice than Lenstra's. This is the modern answer:
  same skeleton as Berlekamp–Zassenhaus, with the exponential step replaced.
* **Hart–Novocin–van Hoeij**, the "r³" algorithm (ISSAC 2010). The first
  implementation both polynomial-time *and* competitive with the best practical
  codes; it is what FLINT ships. Belabas has a relative version over number
  fields.
* Recent: [arXiv:2410.15880](https://arxiv.org/abs/2410.15880) (2024) revisits
  recombining *real* factors rather than `p`-adic ones.

### What to actually do here — cheaper than any of it

**Test for irreducibility before trying to factor.** Irreducibility is much
easier than factorization: reduce `f` mod a few small primes not dividing the
leading coefficient, run distinct-degree factorization, and read off the degree
pattern. If for some prime no proper sub-multiset of the local degrees sums to a
possible factor degree, `f` is irreducible — return `h = f` and never factor
anything.

This is not a corner case for this project. Every polynomial in §8 —
`X²+1`, `X³−2`, `X³−X−1`, `X³−X²−2X−8`, `qX−p` — is irreducible, and a single
prime settles each. More importantly the *headline application*, Corollary 3,
feeds in the minimal polynomial of an algebraic number, which is irreducible by
construction. **The exponential step is entirely avoidable in the main use
case.**

Priority: certificate first, then Berlekamp–Zassenhaus with Hensel lifting for
genuinely reducible input (a few hundred lines, handles everything realistic),
and van Hoeij only if adversarial polynomials ever show up. Implementing van
Hoeij properly is research-grade work and would dwarf the rest of this codebase.

## 2. The Bézout constant is already optimal — a result worth knowing

`bezout` computes the unique `ℚ[X]` cofactors `a, b` with `a h + b h' = 1` and
`deg a < deg h'`, `deg b < deg h` (extended Euclid gives exactly these), then
takes `ρ = lcm` of their denominators.

That quantity has a name — the **reduced resultant**: the generator of the
elimination ideal `(h, h') ∩ ℤ`, i.e. the smallest positive integer expressible
as a `ℤ[X]`-combination of `h` and `h'`. And the standard characterisation is
that it *equals* the lcm of the reduced denominators of the Bézout cofactors.

So `bezout` does not merely find *some* `ρ` — **it finds the smallest possible
one**, and the content-reduction step afterwards is provably a no-op.

Two independent confirmations already in this repo:

* `X² + 1` gives `ρ = 2`, where the *resultant* is `4`. Spec §10 flags this
  case; the reduced resultant is what makes it come out right.
* `X³ − X² − 2X − 8` gives `ρ = 1006`, and a direct kernel computation over the
  degree-bounded lattice confirms `1006` generates the ideal — which is how the
  §8.5 erratum was found in the first place.

This matters more than any constant factor, because the output is **exponential
in `ρ`**: `H`'s coefficients are `h_j ρ^j h₀^{j-1}`. Halving `ρ` is worth more
than a 100× speedup. That it is already minimal is the single best fact about
the current implementation.

Caveat: minimal *given `h`*. See §4.

## 3. The GCD steps are the textbook trap

`squareFreePart` runs Euclid in `ℚ[X]` over `Data.Ratio`, which normalises by a
`gcd` on every single operation. This is the classic intermediate-expression
swell that the whole PRS literature exists to avoid:

* **Subresultant PRS** (Collins; Brown–Traub) — stay in `ℤ[X]`, divide by
  predicted subresultant factors, never form a fraction. Ducos later improved
  the division step.
* **Modular GCD** (Brown, 1971) — compute mod several primes and CRT. Its
  advantage over PRS is structural: the gcd is almost always much smaller than
  the inputs, and the modular method computes it *without ever forming the
  subresultant*, which is the large object.
* **GCDHEU** (Char–Geddes–Gonnet) — heuristic, via integer gcd; strong for few
  variables. **Zippel** (1979) — sparse modular, for sparse multivariate.

The comparative literature is fairly clear that a careful implementation of
Brown's modular GCD beats GCDHEU and EEZ-GCD both in theory and in practice, for
the dense univariate case that applies here.

For §2's `bezout` the *value* of `ρ` will not change — it is already minimal —
but computing it modularly avoids the swollen rationals along the way.

## 4. An optimisation the spec does not mention

`ρ` is minimal for a given `h`, but **`h` itself is a free choice** whenever `f`
is reducible: any irreducible factor with `h(0) ≠ 0` works, and §3–§4 of the
proof never use irreducibility at all.

Since `M = ρ h₀` and the output grows like `ρ^j h₀^{j-1}`, the right move when
`f` factors is to compute the reduced resultant for *each* irreducible factor
and take the one minimising `|M| = |ρ h₀|`. Currently `chooseFactor` takes
whatever Kronecker returns first, which is arbitrary.

Worth noting the spec's §5.2 bound interacts here: choosing Bézout data with
`deg v < n` forces `deg W ≤ n`, hence `n+1 ≤ deg g ≤ 2n`, and the lower bound is
sharp. Extended Euclid already delivers `deg v < n`, so degree is fine; it is
the *coefficients* that the choice of `h` controls.

## 5. Haskell-level issues

Secondary to everything above, but real, and cheap to fix:

* **`Poly.mul` indexes with `!!`** inside a double comprehension — that is
  quadratic list traversal layered on the quadratic convolution. Irrelevant at
  degree 10, wrong at degree 100. A zip/fold convolution, or `Data.Vector`,
  fixes it.
* **`Poly.scaleX` recomputes `m ^ j` per coefficient** — `O(n²)` bignum
  multiplications where a running product is `O(n)`, and with `M` large the
  operands are not small. A one-line `scanl` fix.
* **Lazy accumulation.** `sum` over `Integer` builds thunks; `foldl'` throughout.
* **`Data.Ratio` in the GCD path** is the swell described in §3 — the fix is
  algorithmic, not a strictness annotation.
* **Bignum backend.** GMP natively; on wasm, `ghc-bignum`'s pure-Haskell
  `native`. Since coefficients dominate, this is the constant factor that
  actually shows up in a browser.

None of these change the asymptotics. §1 and §3 do.

## 6. Recommended order

1. **Irreducibility certificate mod `p`** before factoring. Removes the
   exponential step for every realistic input, including the whole of §8 and the
   Corollary 3 application. Small, self-contained, biggest win by far.
2. **Modular GCD** (or subresultant PRS) for `squareFreePart`, and modular
   computation of the Bézout data. Kills the rational swell.
3. **Choose `h` minimising `|ρ h₀|`** when `f` is reducible. Pure output-size
   win, cheap once §1 gives a real factorisation.
4. **Berlekamp–Zassenhaus with Hensel lifting** to replace Kronecker for
   genuinely reducible input.
5. Haskell micro-fixes from §5.
6. **van Hoeij** only if adversarial input ever matters. It probably never will
   here.

`--squarefree` remains the escape hatch throughout: it skips §1 entirely and
still gives `H ∣ g'` and `H² ∣ f ∘ g`, losing only the irreducibility of `H`.

---

## Sources

* [van Hoeij, *Factoring polynomials and the knapsack problem*](https://www.math.fsu.edu/~hoeij/knapsack/paper/May16_2001/knapsack.pdf)
* [Hart, Novocin, van Hoeij, *Practical polynomial factoring in polynomial time* (ISSAC 2010)](https://www.math.fsu.edu/~hoeij/papers/issac10/A.pdf)
* [Belabas, *A relative van Hoeij algorithm over number fields*](https://www.math.u-bordeaux.fr/~kbelabas/research/vanhoeij.pdf)
* [Integer polynomial factorization by recombination of real factors (arXiv:2410.15880)](https://arxiv.org/abs/2410.15880)
* [Brown, *The subresultant PRS algorithm*](https://dl.acm.org/doi/pdf/10.1145/355791.355795)
* [Char, Geddes, Gonnet, *GCDHEU*](https://www.academia.edu/73430211/GCDHEU_Heuristic_polynomial_GCD_algorithm_based_on_integer_GCD_computation)
* [Reduced resultants and Bézout cofactors (arXiv:2508.11043)](https://arxiv.org/pdf/2508.11043)
* [Optimizing the half-gcd algorithm (arXiv:2212.12389)](https://arxiv.org/pdf/2212.12389)
* [FLINT](https://flintlib.org/links.html) · [NTL vs FLINT benchmarks (Shoup)](https://libntl.org/benchmarks.pdf)
