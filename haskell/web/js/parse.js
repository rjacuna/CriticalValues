// Parse polynomial syntax into the Haskell engine's s-expressions. Expansion,
// division and all polynomial arithmetic remain in Haskell. Numeric literals
// stay strings, so large integers and decimal fractions never pass through Number.
export function toWire(raw) {
  const source = String(raw).trim();
  if (!source) throw new Error("enter a polynomial");
  if (source.includes(",") || /^[+-]?\d+$/.test(source)) {
    const coefficients = source.split(",").map(s => s.trim());
    if (!coefficients.every(s => /^[+-]?\d+$/.test(s)))
      throw new Error("coefficients must be integers");
    return coefficients.join(",");
  }
  const tokens = [];
  const pattern = /\s+|(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|[a-zA-Z_][a-zA-Z_0-9]*|[()+*/^−-]/gy;
  let offset = 0;
  while (offset < source.length) {
    pattern.lastIndex = offset;
    const match = pattern.exec(source);
    if (!match) throw new Error(`cannot read that expression at character ${offset + 1}`);
    offset = pattern.lastIndex;
    if (!/^\s/.test(match[0])) tokens.push(match[0].replace("−", "-"));
  }
  let position = 0;
  const variables = new Set();
  const peek = () => tokens[position];
  const take = () => tokens[position++];
  const binary = (op, left, right) => `(${op} ${left} ${right})`;
  const number = token => {
    const [mantissa, exponent = "0"] = token.toLowerCase().split("e");
    const [whole, fraction = ""] = mantissa.split(".");
    const shift = Number(exponent) - fraction.length;
    // Bound literal size before allocating strings. This is unrelated to the
    // algebraic degree, which the engine handles independently.
    if (!Number.isSafeInteger(shift) || Math.abs(shift) > 100000)
      throw new Error("numeric literal exponent is too large");
    const digits = ((whole || "0") + fraction).replace(/^0+(?=\d)/, "");
    if (shift >= 0) return digits + "0".repeat(shift);
    return `(/ ${digits} 1${"0".repeat(-shift)})`;
  };
  function primary() {
    const token = take();
    if (token === "(") {
      const value = sum();
      if (take() !== ")") throw new Error("cannot read that expression: missing )");
      return value;
    }
    if (token && /^(?:\d|\.)/.test(token)) return number(token);
    if (token && /^[a-zA-Z_]/.test(token)) { variables.add(token); return "x"; }
    throw new Error(`cannot read that expression: expected a number, variable or ( at ${token || "end of input"}`);
  }
  function power() {
    const left = primary();
    return peek() === "^" ? (take(), binary("^", left, unary())) : left;
  }
  function unary() {
    if (peek() === "+") { take(); return unary(); }
    if (peek() === "-") { take(); return `(- ${unary()})`; }
    return power();
  }
  const implicit = token => token && /^(?:[a-zA-Z_(]|\d|\.)/.test(token);
  // Implicit multiplication binds more tightly than explicit multiplication
  // and division, matching mathjs: x/2x means x/(2*x).
  function juxtaposition() {
    let left = unary();
    // As in mathjs, a literal fraction followed by juxtaposition is a
    // coefficient: 2/3x means (2/3)*x, while x/2x means x/(2*x).
    if (/^(?:\d+|\(\/ \d+ \d+\))$/.test(left) && peek() === "/"
        && /^(?:\d|\.)/.test(tokens[position + 1] || "")
        && implicit(tokens[position + 2]) && tokens[position + 2] !== "^") {
      take(); left = binary("/", left, primary());
    }
    while (implicit(peek())) left = binary("*", left, unary());
    return left;
  }
  function product() {
    let left = juxtaposition();
    while (peek() === "*" || peek() === "/") {
      const op = take(); left = binary(op, left, juxtaposition());
    }
    return left;
  }
  function sum() {
    let left = product();
    while (peek() === "+" || peek() === "-") {
      const op = take(); left = binary(op, left, product());
    }
    return left;
  }
  const body = sum();
  if (position !== tokens.length) throw new Error(`cannot read that expression: unexpected ${peek()}`);
  if (variables.size > 1) throw new Error(`one variable only, saw ${[...variables].join(", ")}`);
  return body.startsWith("(") ? body : `(+ ${body})`;
}
