# The app

```sh
cabal build critjson       # the backend
./web/serve.py             # http://localhost:8000
```

One input, three panels: the roots of `f`, the `g` the construction produces,
and the critical point `β = α/M` for whichever root is selected.

## No mathematics happens in JavaScript

Every number on the page comes from compiled Haskell. `web/js/` parses the
input box, renders with KaTeX, wires touch and the clipboard — nothing else.
The construction, the 22 checks, the root-finding and the Cardano–Ferrari
expressions are all in `src/`, and the browser is handed a rendered answer.

That is the reason for the awkward-looking `WebCore` split: `src/WebCore.hs` is
the whole request handler, and both front ends are shims over it.

| front end | what it is | when |
|---|---|---|
| `app/CritJson.hs` | native binary, one line in one line out | now |
| `app/Web.hs` | `wasm32-wasi` reactor export | once the cross-compiler is installed |

`web/serve.py` keeps one `critjson` process warm and forwards `POST /solve` to
it. It does no arithmetic — it is a pipe, and it is deleted when the wasm module
exists. Switching is one line in `web/js/backend.js`, because both front ends
speak the identical wire format. `?backend=server` or `?backend=wasm` forces
either.

## Mobile

Touch-first rather than a desktop layout that reflows:

* selection reacts on `pointerdown`, so a tap feels immediate rather than
  waiting for `click`;
* 44px minimum targets, `touch-action: manipulation` to drop the 300 ms
  double-tap delay, and no affordance that depends on hover — the hover rule is
  behind `@media (hover: hover)` so it never fires on a touch screen;
* below `lg` the three panels stack, a sticky bar keeps the selected root
  visible once the list scrolls away, and selecting a root scrolls to `g`;
* full keyboard path too: the list is a `listbox`, arrow keys move, Enter and
  Space select.

One trap worth recording: the selected row uses `.sel`, not `.active`.
Bootstrap's `.list-group-item.active` forces white text, which is invisible
against a subtle background — the row renders, and its content is simply not
readable.

## Numbers

Coefficients cross every boundary as decimal strings and are parsed to `BigInt`
only for display. `g` routinely exceeds `2^53` — 13 digits for `x⁴−10x²+1`, and
460 in one benchmark case — so a numeric boundary would round silently and
corrupt the checks along with the answer.

Roots are shown to 7 significant digits. Above degree 4 there is no expression
by radicals and the panel says so rather than leaving a blank.
