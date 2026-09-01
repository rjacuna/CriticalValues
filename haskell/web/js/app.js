// UI only: parsing the input box, rendering with KaTeX, touch selection,
// clipboard. No mathematics happens in this file — every number shown comes
// from the compiled Haskell.
import { pickBackend } from "./backend.js";
import { parsePolynomial } from "./parse.js";

const $ = (s) => document.querySelector(s);
const $$ = (s) => [...document.querySelectorAll(s)];

let backend = null;
let state = { data: null, selected: 0 };

// ---------------------------------------------------------------- rendering
const tex = (el, s, display = false) => {
  try { katex.render(s, el, { displayMode: display, throwOnError: false }); }
  catch { el.textContent = s; }
};

// One LaTeX fragment per term, sign included, so the container can wrap
// between terms. Returns [] for the zero polynomial.
function polyTerms(coeffs, v = "x") {
  const out = [];
  for (let j = coeffs.length - 1; j >= 0; j--) {
    const c = BigInt(coeffs[j]);
    if (c === 0n) continue;
    const a = c < 0n ? -c : c;
    let body;
    if (j === 0) body = a.toString();
    else body = (a === 1n ? "" : a.toString()) + (j === 1 ? v : `${v}^{${j}}`);
    const sign = out.length === 0 ? (c < 0n ? "-" : "") : (c < 0n ? "-" : "+");
    out.push(out.length === 0 ? sign + body : sign + "\\," + body);
  }
  return out.length ? out : ["0"];
}

// Render `lhs = <terms>` into `el`, one KaTeX node per term.
function renderPolyWrapped(el, lhs, coeffs, v = "x") {
  el.innerHTML = "";
  const head = document.createElement("span");
  tex(head, `${lhs} =`);
  el.append(head);
  for (const t of polyTerms(coeffs, v)) {
    const s = document.createElement("span");
    tex(s, t);
    el.append(s);
  }
}

function polyTex(coeffs, v = "x") {
  const parts = [];
  for (let j = coeffs.length - 1; j >= 0; j--) {
    const c = BigInt(coeffs[j]);
    if (c === 0n) continue;
    const a = c < 0n ? -c : c;
    const sign = c < 0n ? "-" : "+";
    let body;
    if (j === 0) body = a.toString();
    else body = (a === 1n ? "" : a.toString()) + (j === 1 ? v : `${v}^{${j}}`);
    parts.push((parts.length === 0 ? (c < 0n ? "-" : "") : ` ${sign} `) + body);
  }
  return parts.length ? parts.join("") : "0";
}

// ---------------------------------------------------------------- selection
function select(i) {
  state.selected = i;
  const d = state.data, r = d.roots[i];
  $$(".root-item").forEach((el, k) => {
    el.classList.toggle("sel", k === i);
    el.setAttribute("aria-selected", k === i ? "true" : "false");
  });

  tex($("#rootexpr"), r.rad ? r.rad : `\\text{degree } ${d.g ? "" : ""}> 4:\\ \\text{no radical form}`, !!r.rad);
  if (!r.rad) $("#rootexpr").innerHTML =
    '<span class="text-body-secondary">degree &gt; 4 — no expression by radicals (Abel–Ruffini)</span>';

  tex($("#mout"), `M = ${d.M}`);
  tex($("#bout"), `\\beta = ${r.beta}`);
  $("#copyb").dataset.copy = r.beta;
  $("#bnote").innerHTML = "";
  tex($("#bnote"), `\\beta = \\alpha / M \\text{ — the construction always rescales}`);

  const sticky = $("#stickysel");
  sticky.classList.add("on");
  tex($("#stickysel-val"), `\\alpha = ${r.alpha}`);

  if (window.matchMedia("(max-width: 991.98px)").matches)
    $("#col-g").scrollIntoView({ behavior: "smooth", block: "start" });
}

// ---------------------------------------------------------------- results
function render(d) {
  state.data = d;
  $("#results").classList.remove("d-none");

  const list = $("#rootlist");
  list.innerHTML = "";
  d.roots.forEach((r, i) => {
    const el = document.createElement("div");
    el.className = "list-group-item list-group-item-action root-item tap d-flex align-items-center";
    el.setAttribute("role", "option");
    el.tabIndex = 0;
    const span = document.createElement("span");
    tex(span, `\\alpha_{${i + 1}} = ${r.alpha}`);
    el.append(span);
    // touch: react on pointerdown so the tap feels immediate
    el.addEventListener("pointerdown", () => el.classList.add("pressed"));
    for (const ev of ["pointerup", "pointercancel", "pointerleave"])
      el.addEventListener(ev, () => el.classList.remove("pressed"));
    el.addEventListener("click", () => select(i));
    el.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); select(i); }
      if (e.key === "ArrowDown") { e.preventDefault(); list.children[i + 1]?.focus(); }
      if (e.key === "ArrowUp") { e.preventDefault(); list.children[i - 1]?.focus(); }
    });
    list.append(el);
  });

  if (d.degenerate) {
    renderPolyWrapped($("#gout"), "g", ["0", "0", "1"]);
    $("#gmeta").textContent = "§6, X ∣ f";
    $("#setupmeta").innerHTML = "H = x";
    $("#copyg").dataset.copy = "x^2";
    $("#checks").innerHTML = "";
    return;
  }

  const gTex = polyTex(d.g);
  renderPolyWrapped($("#gout"), "g", d.g);
  $("#copyg").dataset.copy = gTex;
  $("#gmeta").textContent = `degree ${d.degG}, ${d.digitsG}-digit coefficients`;

  const meta = $("#setupmeta");
  meta.innerHTML = "";
  for (const [k, v] of [["h", polyTex(d.h)], ["H", polyTex(d.H)], ["\\rho", d.rho]]) {
    const row = document.createElement("div");
    row.className = "scrollx mb-1";
    tex(row, `${k} = ${v}`);
    meta.append(row);
  }

  const ck = $("#checks");
  ck.innerHTML = "";
  for (const c of d.checks) {
    const row = document.createElement("div");
    row.className = "chk " + (c.ok ? "text-success" : "text-danger fw-bold");
    row.textContent = (c.ok ? "ok   " : "FAIL ") + c.name;
    ck.append(row);
  }

  select(0);
}

// ---------------------------------------------------------------- run
function busy(on, text = "working…") {
  $("#busy").classList.toggle("d-none", !on);
  $("#busy").classList.toggle("d-flex", on);
  $("#busytext").textContent = text;
  $("#go").disabled = on;
}
const fail = (m) => { const a = $("#alert"); a.textContent = m; a.classList.remove("d-none"); };

async function compute() {
  $("#alert").classList.add("d-none");
  let coeffs, scaled;
  try { ({ coeffs, scaled } = parsePolynomial($("#finput").value)); }
  catch (e) { fail(String(e.message || e)); return; }

  // Echo what was actually parsed. The checks cannot catch a mis-parse — they
  // verify the construction for the f they were handed — so this has to be
  // visible.
  const fEcho = $("#fecho");
  fEcho.innerHTML = "";
  renderPolyWrapped(fEcho, "f", coeffs);
  if (scaled) {
    const n = document.createElement("span");
    n.className = "text-body-secondary ms-2";
    n.textContent = "(cleared denominators — same roots)";
    fEcho.append(n);
  }

  $("#results").classList.add("d-none");
  $("#stickysel").classList.remove("on");
  busy(true, backend.name === "wasm" ? "running in the browser…" : "computing…");
  try {
    // h is left empty: the backend uses the squarefree part, so one g covers
    // every root of f. With FLINT it will pass the irreducible factor instead.
    const d = await backend.solve(`${coeffs.join(",")}|`);
    if (!d.ok) { fail(d.error || "failed"); return; }
    render(d);
  } catch (e) {
    fail(String(e.message || e));
  } finally {
    busy(false);
  }
}

// ---------------------------------------------------------------- wiring
addEventListener("DOMContentLoaded", async () => {
  backend = await pickBackend();
  const badge = $("#backend-badge");
  badge.textContent = backend.name === "wasm" ? "wasm" : "server";
  badge.className = "ms-auto badge " +
    (backend.name === "wasm" ? "text-bg-success" : "text-bg-secondary");

  $("#form").addEventListener("submit", (e) => { e.preventDefault(); compute(); });
  $$(".ex").forEach((b) => b.addEventListener("click", () => {
    $("#finput").value = b.dataset.f; compute();
  }));
  for (const id of ["#copyg", "#copyb"]) {
    const b = $(id);
    b.addEventListener("click", async () => {
      const v = b.dataset.copy;
      if (!v) return;
      try { await navigator.clipboard.writeText(v); } catch { return; }
      const old = b.textContent;
      b.textContent = "Copied"; b.classList.add("btn-success");
      b.classList.remove("btn-outline-secondary");
      setTimeout(() => { b.textContent = old; b.classList.remove("btn-success");
                         b.classList.add("btn-outline-secondary"); }, 1200);
    });
  }
  compute();
});
