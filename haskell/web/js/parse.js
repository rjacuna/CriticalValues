// Turning what the user typed into integer coefficients.
//
// Uses mathjs rather than a hand-written parser: `rationalize` expands products
// and powers and hands back the numerator coefficients in increasing exponent
// order, which is already the order the backend wants.
//
//     (x^3 + x - 2)*(x + 2)   ->   [-4, 0, 1, 2, 1]
//
// This is the one place where something arithmetic happens outside the compiled
// Haskell, and it is worth being uneasy about: if the parse were wrong we would
// construct for the wrong f, and all 22 checks would still pass — they verify
// the construction for whatever f they were given. So `expandedLatex` is shown
// back on the page, where a mis-parse is visible rather than silent.
// mathjs is vendored (vendor/math.js, the self-contained UMD build) and loaded
// by a plain script tag, so the page works offline and this module is testable
// under node — the +esm bundle uses root-relative imports that only resolve on
// the CDN.
const M = () => {
  const m = globalThis.math;
  if (!m) throw new Error("mathjs not loaded (vendor/math.js)");
  return m;
};

const isIntStr = (s) => /^[+-]?\d+$/.test(s);

// bigint gcd / lcm, for clearing denominators
const gcd2 = (a, b) => { a = a < 0n ? -a : a; b = b < 0n ? -b : b;
  while (b) { [a, b] = [b, a % b]; } return a; };

function toBigIntExact(x) {
  // mathjs hands back numbers or Fractions depending on the input
  if (typeof x === "number") {
    if (!Number.isFinite(x)) throw new Error("coefficient is not finite");
    if (!Number.isInteger(x)) return { n: null, x };
    return { n: BigInt(x), d: 1n };
  }
  if (x && typeof x === "object" && "n" in x && "d" in x) {
    const s = x.s === undefined ? 1n : BigInt(x.s);
    return { n: s * BigInt(x.n), d: BigInt(x.d) };
  }
  const v = Number(x);
  if (Number.isInteger(v)) return { n: BigInt(v), d: 1n };
  return { n: null, x: v };
}

/**
 * @returns {{coeffs: string[], scaled: boolean}} little-endian integer coefficients
 */
export function parsePolynomial(raw) {
  const s = String(raw).trim();
  if (!s) throw new Error("enter a polynomial");

  // a bare coefficient list stays a coefficient list
  if (!/[a-zA-Z]/.test(s)) {
    const cs = s.split(",").map((t) => t.trim()).filter(Boolean);
    if (!cs.every(isIntStr)) throw new Error("coefficients must be integers");
    while (cs.length > 1 && cs[cs.length - 1] === "0") cs.pop();
    return { coeffs: cs, scaled: false };
  }

  let r;
  try {
    r = M().rationalize(s, {}, true);
  } catch (e) {
    throw new Error(`cannot read that expression (${e.message || e})`);
  }

  // rationalize returns a fraction; we need a polynomial
  const den = r.denominator ? r.denominator.toString() : "1";
  if (den !== "1") throw new Error(`not a polynomial — denominator ${den}`);
  if (r.variables && r.variables.length > 1)
    throw new Error(`one variable only, saw ${r.variables.join(", ")}`);

  const parts = (r.coefficients || []).map(toBigIntExact);
  if (parts.some((p) => p.n === null)) throw new Error("coefficients must be rational");

  // clear denominators: scaling f leaves its roots, and so the whole question,
  // untouched
  let L = 1n;
  for (const p of parts) L = (L / gcd2(L, p.d)) * p.d;
  const coeffs = parts.map((p) => ((p.n * L) / p.d).toString());
  while (coeffs.length > 1 && coeffs[coeffs.length - 1] === "0") coeffs.pop();
  if (coeffs.every((c) => c === "0")) throw new Error("f must be nonzero");
  return { coeffs, scaled: L !== 1n };
}
