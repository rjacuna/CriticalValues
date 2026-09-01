// The same picture, on geogebra.org — populated, not pasted.
//
// GeoGebra takes its input from the URL: ?command= runs a semicolon-separated
// list, so the graph arrives built. This is what Desmos has no equivalent of,
// and it is why the button exists. Verified against the live applet: every
// object is created, the Newton refinement is evaluated there, and the point
// lands on (β, g(β)).
//
// Two differences from the Desmos list. GeoGebra input is plain text rather
// than LaTeX — x^7, not x^{7} — and it names objects itself unless told, so
// the lines are given names in order to be coloured afterwards.
//
// As in the Desmos list, the critical points are only seeds: n is Newton's
// method on GeoGebra's own d, and the lines and points read the refined value.
import { split } from "./desmos.js";

const BASE = "https://www.geogebra.org/calculator";

/** KaTeX-flavoured polynomial to GeoGebra input. */
const plain = (latex) => latex.replace(/\^\{(\d+)\}/g, "^$1").replace(/\s+/g, "");

const rgb = { g: [45, 112, 179], gp: [0, 0, 0], sel: [199, 68, 64], other: [107, 107, 107] };
const setColor = (name, c) => `SetColor(${name},${c[0]},${c[1]},${c[2]})`;

export function commands({ gLatex, gpLatex, crit, plot, beta }) {
  const { sel, others } = split(crit || [], beta);
  const refine = (v) => `n(n(n(${v})))`;
  const cs = [
    `f(x)=${plain(gLatex)}`,
    `d(x)=${plain(gpLatex)}`,
    `k=${plot ? plot.k : 1}`,
    "e(x)=d(x)/k",
    "n(x)=x-d(x)/d'(x)",
    setColor("f", rgb.g),
    setColor("e", rgb.gp),
    // n and d are machinery; showing them would draw the Newton map over the plot
    "SetVisibleInView(d,1,false)",
    "SetVisibleInView(n,1,false)",
  ];
  others.forEach((c, i) => {
    const b = `b_${i + 1}`, line = `u_${i + 1}`, pt = `Q_${i + 1}`;
    cs.push(`${b}=${refine(c.b)}`, `${line}: x=${b}`, `${pt}=(${b},f(${b}))`,
            setColor(line, rgb.other), setColor(pt, rgb.other));
  });
  if (sel) {
    cs.push(`s=${refine(sel.b)}`, "t: x=s", "P=(s,f(s))",
            setColor("t", rgb.sel), setColor("P", rgb.sel));
  }
  if (plot) cs.push(`ZoomIn(${plot.xlo},${plot.ylo},${plot.xhi},${plot.yhi})`);
  return cs;
}

export const url = (data) =>
  `${BASE}?command=${encodeURIComponent(commands(data).join(";"))}`;

export function openInGeoGebra(data) {
  const u = url(data);
  return { opened: !!window.open(u, "_blank", "noopener"), url: u };
}
