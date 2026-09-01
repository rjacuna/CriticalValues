// UI only: parsing the input box, rendering with KaTeX, touch selection,
// clipboard. No mathematics happens in this file — every number shown comes
// from the compiled Haskell.
import { pickBackend, loadFlint } from "./backend.js";
import { showGraph, openInDesmos } from "./desmos.js";
import { toWire } from "./parse.js";

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
  const s = d.setups[Number(r.setup) || 0];
  renderSetup(d, s);
  $$(".root-item").forEach((el, k) => {
    el.classList.toggle("sel", k === i);
    el.setAttribute("aria-selected", k === i ? "true" : "false");
  });

  tex($("#rootexpr"), r.rad ? r.rad : `\\text{degree } ${d.g ? "" : ""}> 4:\\ \\text{no radical form}`, !!r.rad);
  if (!r.rad) $("#rootexpr").innerHTML =
    '<span class="text-body-secondary">degree &gt; 4 — no expression by radicals (Abel–Ruffini)</span>';

  tex($("#mout"), `M = ${s.M}`);
  tex($("#bout"), `\\beta = ${r.beta}`);
  $("#copyb").dataset.copy = r.beta;
  $("#bnote").innerHTML = "";
  tex($("#bnote"), `\\beta = \\alpha / M \\text{ — the construction always rescales}`);

  // real roots only: a complex β is not a point on a real plot
  const isReal = !r.alpha.includes("i") && !d.degenerate;
  const panel = $("#col-graph");
  panel.classList.toggle("d-none", !isReal);
  if (isReal) {
    const payload = {
      gLatex: polyTex(s.g), gpLatex: polyTex(s.gp || ["0"]),
      alpha: r.alpha, beta: r.beta, crit: s.crit || [], plot: s.plot,
    };
    panel.dataset.payload = JSON.stringify(payload);
    const n = payload.crit.length;
    $("#desmos-k").textContent = `k = ${s.plot ? s.plot.k : 1}`;
    $("#desmos-cap").textContent =
      `${n} real critical point${n === 1 ? "" : "s"} of g; the red line is β = ${r.beta}, `
      + `where g takes the selected value α = ${r.alpha}`;
    showGraph($("#desmos-host"), $("#desmos-fallback"), payload);
  }

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

  // Echo f as the *backend* expanded it. The 22 checks cannot catch a
  // mis-parse — they verify the construction for whatever f they were given —
  // so what was actually understood has to be on screen.
  if (d.f) renderPolyWrapped($("#fecho"), "f", d.f);

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
    $("#col-graph").classList.add("d-none");
    renderPolyWrapped($("#gout"), "g", ["0", "0", "1"]);
    $("#gmeta").textContent = "§6, X ∣ f";
    $("#setupmeta").innerHTML = "H = x";
    $("#copyg").dataset.copy = "x^2";
    $("#checks").innerHTML = "";
    $("#hsource").textContent = "";
    return;
  }

  select(0);
}

// One setup per irreducible factor, so this follows the selected root.
function renderSetup(d, s) {
  const gTex = polyTex(s.g);
  renderPolyWrapped($("#gout"), "g", s.g);
  $("#copyg").dataset.copy = gTex;
  renderPolyWrapped($("#gpout"), "g'", s.gp || ["0"]);
  $("#copygp").dataset.copy = polyTex(s.gp || ["0"]);
  $("#gmeta").textContent = `degree ${s.degG}, ${s.digitsG}-digit coefficients`;

  const meta = $("#setupmeta");
  meta.innerHTML = "";
  for (const [k, v] of [["h", polyTex(s.h)], ["H", polyTex(s.H)], ["\\rho", s.rho]]) {
    const row = document.createElement("div");
    row.className = "scrollx mb-1";
    tex(row, `${k} = ${v}`);
    meta.append(row);
  }

  const src = $("#hsource");
  if (d.hIrreducible) {
    src.className = "badge text-bg-success-subtle text-success-emphasis";
    src.textContent = `H irreducible · ${d.setups.length} factor${d.setups.length > 1 ? "s" : ""}`;
  } else {
    src.className = "badge text-bg-warning-subtle text-warning-emphasis";
    src.textContent = "H irreducible only if f is — no factoriser";
  }

  const ck = $("#checks");
  ck.innerHTML = "";
  const rows = [...s.checks];
  if (s.HIrred !== undefined && s.HIrred !== null)
    rows.push({ name: "Lemma D : H is irreducible   (FLINT)", ok: s.HIrred });
  for (const c of rows) {
    const row = document.createElement("div");
    row.className = "chk " + (c.ok ? "text-success" : "text-danger fw-bold");
    row.textContent = (c.ok ? "ok   " : "FAIL ") + c.name;
    ck.append(row);
  }
  $("#gmeta").textContent =
    `degree ${s.degG}, ${s.digitsG}-digit coefficients` +
    (s.HIrred === undefined ? "" : `  ·  ${rows.length} checks`);
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
  let wire;
  try { wire = toWire($("#finput").value); }
  catch (e) { fail(String(e.message || e)); return; }
  $("#fecho").innerHTML = "";

  $("#results").classList.add("d-none");
  $("#stickysel").classList.remove("on");
  busy(true, backend.name === "wasm" ? "running in the browser…" : "computing…");
  try {
    // First pass expands the expression and hands back f's coefficients.
    let d = await backend.solve(`${wire}|`);
    if (!d.ok) { fail(d.error || "failed"); return; }

    // Second pass, when FLINT is available: factor f and rebuild, so H really
    // is irreducible and each factor of a reducible f gets its own g.
    const fl = await loadFlint();
    if (fl && d.f && !d.degenerate) {
      busy(true, "factoring with FLINT…");
      const factors = fl.factor(d.f).filter((h) => h.length > 1 && h[0] !== "0");
      if (factors.length) {
        const d2 = await backend.solve(`${d.f.join(",")}|${factors.map((h) => h.join(",")).join(";")}`);
        if (d2.ok) d = d2;
      }
      // Verify irreducibility of H rather than assuming it. This cannot live in
      // the 22 checks: crit.wasm is base-only and Kronecker would choke on H's
      // coefficients, so it is asked of FLINT here. Counting factors is not
      // arithmetic — FLINT does the work.
      busy(true, "verifying H is irreducible…");
      for (const s of d.setups || []) {
        try { s.HIrred = fl.factor(s.H).length === 1; }
        catch { s.HIrred = null; }
      }
    }
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
  // Desmos cannot be handed a graph by link, so the expressions travel by
  // clipboard and the user has to paste once. Saying so is the whole feature —
  // a tab that opens onto an empty calculator just looks broken.
  $("#opendesmos").addEventListener("click", async () => {
    const d = JSON.parse($("#col-graph").dataset.payload || "{}");
    const { copied, opened, text } = await openInDesmos(d);
    const box = $("#desmos-handoff"), pre = $("#handoff-exprs");
    box.classList.remove("d-none");
    // show the text whenever the hand-off did not fully work: a blocked popup
    // leaves the message pointing at expressions that have to be there
    const needText = !copied || !opened;
    pre.classList.toggle("d-none", !needText);
    if (needText) pre.textContent = text;
    $("#handoff-msg").innerHTML = !opened
      ? "The new tab was blocked. Allow pop-ups for this page, or open "
        + '<a href="https://www.desmos.com/calculator" target="_blank" rel="noopener">'
        + "desmos.com/calculator</a> yourself and paste the expressions below."
      : copied
      ? "<strong>Copied.</strong> In the Desmos tab that just opened, click the "
        + "expression list and paste (⌘V / Ctrl+V) — it becomes one row per line. "
        + "Desmos has no way to receive a graph by link, so this is the hand-off."
      : "The clipboard was refused. Copy these into the Desmos tab that just opened:";
  });

  for (const id of ["#copyg", "#copygp", "#copyb", "#copydesmos"]) {
    const b = $(id);
    if (!b) continue;
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
