// Turning what the user typed into something the backend can evaluate.
//
// mathjs *parses*; it does not do the algebra. Its parser is excellent — 13 ms
// whether the input is (x+1)^2 or (x+1)^8 — but `rationalize`, which would
// expand the product, normalises by rewriting to a fixed point and rescans the
// whole tree against the whole rule set after every rewrite. Measured:
//
//     (x+1)^2   23 ms      (x+1)^4      75 ms
//     (x+1)^3   25 ms      (x+1)^5   52,981 ms
//
// The same expansion in the Haskell (src/Expr.hs) takes 0.26 ms, and does
// (x+1)^200 in 6.3 ms. So the AST is serialised to an s-expression and expanded
// there, with the exact arithmetic the rest of the project already uses. No
// mathematics happens in this file.
const M = () => {
  const m = globalThis.math;
  if (!m) throw new Error("mathjs not loaded (vendor/math.js)");
  return m;
};

const OPS = {
  add: "+", subtract: "-", multiply: "*", divide: "/",
  pow: "^", unaryMinus: "-", unaryPlus: "+",
};

function sexp(node) {
  switch (node.type) {
    case "ConstantNode": {
      const v = node.value;
      if (typeof v === "number") {
        if (!Number.isInteger(v)) {
          // 0.5 becomes (/ 1 2) rather than a float: the backend is exact
          const f = M().fraction(v);
          return `(/ ${f.s < 0 ? "-" : ""}${f.n} ${f.d})`;
        }
        return String(v);
      }
      if (v && v.n !== undefined && v.d !== undefined)
        return `(/ ${v.s < 0 ? "-" : ""}${v.n} ${v.d})`;
      return String(v);
    }
    case "SymbolNode":
      return node.name;
    case "ParenthesisNode":
      return sexp(node.content);
    case "OperatorNode": {
      const op = OPS[node.fn];
      if (!op) throw new Error(`unsupported operator ${node.fn}`);
      return `(${op} ${node.args.map(sexp).join(" ")})`;
    }
    default:
      throw new Error(`unsupported ${node.type.replace("Node", "").toLowerCase()}`);
  }
}

const isIntStr = (s) => /^[+-]?\d+$/.test(s);

/**
 * @returns {string} either a coefficient list "c0,c1,..." or an s-expression,
 *   both of which the backend accepts. An s-expression always starts with "(",
 *   which is how the two are told apart.
 */
export function toWire(raw) {
  const s = String(raw).trim();
  if (!s) throw new Error("enter a polynomial");

  // a bare coefficient list stays a coefficient list
  if (!/[a-zA-Z]/.test(s)) {
    const cs = s.split(",").map((t) => t.trim()).filter(Boolean);
    if (!cs.every(isIntStr)) throw new Error("coefficients must be integers");
    return cs.join(",");
  }

  let node;
  try {
    node = M().parse(s);
  } catch (e) {
    throw new Error(`cannot read that expression (${e.message || e})`);
  }

  const vars = new Set();
  node.traverse((n) => { if (n.type === "SymbolNode") vars.add(n.name); });
  if (vars.size > 1) throw new Error(`one variable only, saw ${[...vars].join(", ")}`);
  const v = [...vars][0];
  if (v && v !== "x") {
    // let the user write t or y; the backend only knows x
    node = node.transform((n) =>
      n.type === "SymbolNode" && n.name === v ? new (M().SymbolNode)("x") : n);
  }
  // always parenthesised, so the backend can tell it from a coefficient list
  const body = sexp(node);
  return body.startsWith("(") ? body : `(+ ${body})`;
}
