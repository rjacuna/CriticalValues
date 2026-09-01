# Flint2 fork for FLINT 3.4

[`Flint2`](https://hackage.haskell.org/package/Flint2) is the maintained Haskell
binding to FLINT. Its last release (0.1.0.5, November 2023) targets FLINT 2.x
and does not build against FLINT 3.4.

```sh
cabal get Flint2-0.1.0.5
sh patch-flint2.sh Flint2-0.1.0.5
```

## What breaks, and why

Found by probing every `#{peek}`/`#{poke}` in the package against the installed
headers with `offsetof` — 190 struct fields, of which five structs fail — plus a
check that every included `flint/*.h` still exists.

| break | cause |
|---|---|
| `*_mat_struct.rows`, 11 structs | FLINT 3 replaced `rows` with `stride` |
| `bool_mat_struct`, `d_mat_struct` | kept `rows` — must **not** be patched |
| `fmpz_mod_mat_struct.mat`, `.mod` | `fmpz_mod_mat_t` is now a plain `fmpz_mat_struct`, with no embedded modulus |
| `psl2z_word_struct` | type removed |
| `flint/mpf_mat.h`, `flint/mpfr_mat.h` | modules dropped from FLINT 3 |

Nothing else in the package is affected. In particular all of `fmpz_poly` and
`fmpz_poly_factor` — everything this project calls — is unchanged.

## This is a build fix, not a port

The patched matrix bindings are **structurally wrong** under FLINT 3 and must
not be used:

* `stride` is a `slong`, but it is now read into a field typed as a
  row-pointer array. Size-compatible, semantically meaningless.
* `fmpz_mod_mat` no longer carries a modulus, so those two fields are fiction.
* `psl2z_word_struct`'s fields are redirected to unrelated members of
  `psl2z_struct`.

They are patched only so the package compiles; the integer, rational and
polynomial bindings are untouched and correct. A real FLINT 3 port would retype
those records, which is upstream's job.

The `Mpf/Vec` and `Mpfr/Vec` modules are *not* removed — only the two `Mat`
ones, whose headers are gone.
