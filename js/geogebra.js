// The same picture, on geogebra.org — populated, not pasted.
//
// GeoGebra takes its input from the URL: ?command= runs a semicolon-separated
// list, so the graph arrives built. This is what Desmos has no equivalent of,
// and it is why the button exists.
//
// Only g goes across. GeoGebra differentiates it and solves g' = 0 itself:
//
//   f(x) = <g>      the curve
//   d(x) = f'(x)    its derivative
//   c: d(x) = 0     an equation in x alone, which GeoGebra draws as a vertical
//                   line at each real root — every critical point of g, found
//                   over there, not sent from here
//
// Three rows, and none of them is a number we computed. The seeds, the Newton
// refinement, the scale k and the marked points all belong to the panel's own
// plot, where they earn their place; here they would be our arithmetic wearing
// GeoGebra's colours. Sending less also makes the check stronger — if the
// lines land on the turning points of a curve GeoGebra drew from g alone, that
// is independent of everything except g.
//
// ZoomIn is the exception, and it is a viewport rather than a quantity: β runs
// to 1e-2 and smaller, so the default -10..10 view would show a blank grid.
const BASE = "https://www.geogebra.org/calculator";

/** KaTeX-flavoured polynomial to GeoGebra input: x^7, not x^{7}. */
const plain = (latex) => latex.replace(/\^\{(\d+)\}/g, "^$1").replace(/\s+/g, "");

export function commands({ gLatex, plot }) {
  const cs = [`f(x)=${plain(gLatex)}`, "d(x)=f'(x)", "c: d(x)=0"];
  if (plot) cs.push(`ZoomIn(${plot.xlo},${plot.ylo},${plot.xhi},${plot.yhi})`);
  return cs;
}

export const url = (data) =>
  `${BASE}?command=${encodeURIComponent(commands(data).join(";"))}`;
