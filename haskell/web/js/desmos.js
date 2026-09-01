// The visual check: g and g' on one pair of axes, with a vertical line at every
// real root of g'.
//
// What is being checked. Where g' crosses zero, g has a critical point, so each
// line meets the blue curve at a critical value. The construction claims α is
// one of them — that line is drawn in red, and its meeting point is the one the
// labels read out. For x⁵−x−1, g has degree 10 and exactly one real critical
// point, whose value is the real root of f: the theorem in one picture.
//
// The labels are ${...} so Desmos evaluates g at those points itself and prints
// its own decimals. That matters: a number we formatted would only repeat what
// the Haskell said, whereas this is an independent evaluation by another engine
// arriving at the same value.
//
// g' is plotted as g'/k with k = 1, so what is drawn is g' itself. The divisor
// is there only as a handle: g' dwarfs g — on x⁵−x−1 it reaches ±6·10⁴ against
// g's 1.7 — so most of it leaves the frame. Raising k in the expression list
// pulls it back in, and changes the height only: the zeros, which are what the
// plot is about, do not move. The Haskell sends a k that fits the window, and
// the panel prints it as the suggestion.
//
// Only offered for real roots: a complex β is not a point on a real plot.
//
// Double precision is not a problem here, which is worth stating because g's
// coefficients run to 34 digits and it looks like it should be. The terms
// c_k β^k are all O(1) — the huge coefficients are cancelled by the tiny powers
// of β = α/M — so there is no catastrophic cancellation. Measured on x^5-x-1:
// largest term 1.317 against an answer of 1.167, zero digits lost.
//
// The API key below is Desmos's public demo key, documented for development.
// For anything public, get your own at desmos.com/my-api.
const API_KEY = "dcb31709b452b1cf9dc26972add0fda6";
const SRC = `https://www.desmos.com/api/v1.11/calculator.js?apiKey=${API_KEY}`;

export const COLORS = { g: "#2d70b3", gp: "#000000", sel: "#c74440", other: "#6b6b6b" };

let loading = null;
function loadDesmos() {
  if (globalThis.Desmos) return Promise.resolve(globalThis.Desmos);
  if (loading) return loading;
  loading = new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = SRC;
    s.onload = () => (globalThis.Desmos ? resolve(globalThis.Desmos) : reject(new Error("no Desmos")));
    s.onerror = () => reject(new Error("could not load the Desmos API"));
    document.head.append(s);
  });
  return loading;
}

/** The critical point the selected root belongs to, by value: β is printed from
 *  α/M and the root of g' is found numerically, so the decimals can disagree in
 *  the last place and string equality would pick nothing. */
function split(crit, beta) {
  const b = Number(beta);
  let sel = null, best = Infinity;
  for (const c of crit) {
    const d = Math.abs(Number(c.b) - b);
    if (d < best) { best = d; sel = c; }
  }
  return { sel, others: crit.filter((c) => c !== sel) };
}

/**
 * The expression list, as Desmos LaTeX. Also what the clipboard gets.
 *
 * Nothing drawn here is a number we computed. The critical points arrive only
 * as *seeds*; Desmos refines each one with Newton's method on its own D, and
 * the lines, the points and the labels all read the refined value. That is not
 * ceremony — our β is printed to seven significant figures, and at the zoom
 * this panel invites, seven figures puts the line visibly beside the place
 * where the black curve actually crosses zero. One step of Newton from that
 * seed already lands on the root to full double precision; three is slack.
 */
export function expressions({ gLatex, gpLatex, crit, plot, beta }) {
  const { sel, others } = split(crit || [], beta);
  const refine = (v) => `N\\left(N\\left(N\\left(${v}\\right)\\right)\\right)`;
  const out = [
    { id: "G", latex: `G\\left(x\\right)=${gLatex}` },
    { id: "D", latex: `D\\left(x\\right)=${gpLatex}` },
    { id: "k", latex: "k=1" },
    { id: "N", latex: "N\\left(x\\right)=x-\\frac{D\\left(x\\right)}{D'\\left(x\\right)}" },
    { id: "cg", latex: "y=G\\left(x\\right)", color: COLORS.g, lineWidth: 2.5 },
    { id: "cd", latex: "y=\\frac{D\\left(x\\right)}{k}", color: COLORS.gp, lineWidth: 2 },
  ];
  if (others.length) {
    const seeds = others.map((c) => c.b).join(",");
    out.push({ id: "B0", latex: `B_{0}=\\left[${seeds}\\right]`, hidden: true });
    out.push({ id: "B", latex: `B=${refine("B_{0}")}`, hidden: true });
    // A is bound only so the label can name it: ${...} interpolates a variable,
    // not an expression, and ${G(B)} would print verbatim.
    out.push({ id: "A", latex: "A=G\\left(B\\right)", hidden: true });
    out.push({ id: "lB", latex: "x=B", color: COLORS.other, lineWidth: 1.5 });
    out.push({ id: "pB", latex: "\\left(B,A\\right)", color: COLORS.other,
      pointSize: 9, showLabel: true, label: "(${B}, ${A})",
      labelSize: "small", labelOrientation: "above" });
  }
  if (sel) {
    out.push({ id: "S0", latex: `S_{0}=${sel.b}`, hidden: true });
    out.push({ id: "S", latex: `S=${refine("S_{0}")}`, hidden: true });
    out.push({ id: "T", latex: "T=G\\left(S\\right)", hidden: true });
    out.push({ id: "lS", latex: "x=S", color: COLORS.sel, lineWidth: 2.5 });
    out.push({ id: "pS", latex: "\\left(S,T\\right)", color: COLORS.sel,
      pointSize: 15, showLabel: true, label: "(${S}, ${T})", labelOrientation: "above" });
  }
  return out;
}

/** One expression per line — Desmos's expression list accepts a multi-line paste. */
export const asText = (exprs) => exprs.map((e) => e.latex).join("\n");

let calc = null;

export async function showGraph(host, fallback, data) {
  const exprs = expressions(data);
  const p = data.plot;

  try {
    const Desmos = await loadDesmos();
    fallback.classList.add("d-none");
    host.classList.remove("d-none");
    if (!calc) calc = Desmos.GraphingCalculator(host, {
      expressionsCollapsed: true, settingsMenu: false, border: false,
    });
    calc.setBlank();
    calc.resize();  // the panel may have been resized while it was hidden
    for (const e of exprs) calc.setExpression(e);
    if (p) calc.setMathBounds({
      left: Number(p.xlo), right: Number(p.xhi),
      bottom: Number(p.ylo), top: Number(p.yhi),
    });
    return "ok";
  } catch (e) {
    // no network, or the key was rejected — hand over the expressions instead
    host.classList.add("d-none");
    fallback.classList.remove("d-none");
    const text = asText(exprs);
    fallback.querySelector("#desmos-exprs").textContent = text;
    fallback.querySelector("#copydesmos").dataset.copy = text;
    return String(e.message || e);
  }
}

/**
 * Hand the same plot over to desmos.com.
 *
 * Desmos has no way to receive a graph by link: the query string is discarded
 * (tested), and a saved-graph URL needs an account. So the expression list goes
 * to the clipboard and the calculator opens ready for one paste, which it turns
 * into one row per line. The caller reports what actually happened — a blocked
 * popup or a refused clipboard both need the user to be told something.
 */
export async function openInDesmos(data) {
  const text = asText(expressions(data));
  let copied = false;
  try { await navigator.clipboard.writeText(text); copied = true; } catch { /* denied */ }
  const w = window.open("https://www.desmos.com/calculator", "_blank", "noopener");
  return { copied, opened: !!w, text };
}
