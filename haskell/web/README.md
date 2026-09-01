# The app

```sh
cabal build critjson       # the backend
./web/serve.py             # http://localhost:8000
```

One input, two panels: the roots of `f` on the left, and on the right the `g`
the construction produces, preceded by `M` and the critical point `β` for
whichever root is selected.

Two panels rather than three because **`β` is always `α/M`**. The construction
builds `g = M·x + h(M·x)·W`, so `g(β) = Mβ + h(α)W(β) = α`: the linear term
produces `α` and the rest exists only to be divisible by `H²`, vanishing at `β`.
There is no independent `β` to display — only `M`, and the decimal. Its closed
form would likewise just be the closed form of `α` divided by `M`, which is
already on the left.

**`g` does not change when you select a different root, and that is correct.**
`g` depends on `h`, never on `α`. Without a factoriser `h` is the squarefree
part of `f`, so a single `g` serves every root — which is exactly the property
that makes this the right variant for a UI that lets you pick any root. With
FLINT supplying an irreducible factor instead, `g` *would* change when the
selected root belongs to a different factor of a reducible `f`; for irreducible
`f` it stays fixed either way.

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
