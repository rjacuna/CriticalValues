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

Ten distinct breakages, in four classes.

**Struct layout** (found by probing all 190 `#{peek}`/`#{poke}` sites with
`offsetof`):

| break | cause |
|---|---|
| `*_mat_struct.rows`, 11 structs | FLINT 3 replaced `rows` with `stride` |
| `bool_mat_struct`, `d_mat_struct` | kept `rows` — must **not** be patched |
| `fmpz_mod_mat_struct.mat`, `.mod` | `fmpz_mod_mat_t` is now a plain `fmpz_mat_struct`, with no embedded modulus |
| `psl2z_word_struct` | type removed |

**Dropped modules** (found by checking every included `flint/*.h` exists):

| break | cause |
|---|---|
| `flint/mpf_mat.h`, `flint/mpfr_mat.h` | dropped from FLINT 3 |
| `CMpfMat` in `fmpz_lll_check_babai_heuristic` | its argument type went with them |
| `csrc/mpfr_mat/swap_entrywise.c` | vendored helper for a dropped module |

**Vendored C against FLINT 3** (found by compiling all ~160 `csrc` files and
mapping each undeclared symbol to its header):

| break | cause |
|---|---|
| `fmpz_factor_fprint`, `fmpz_mpoly_q_get_str_pretty` | FLINT 3 now provides these itself, with different signatures |
| `csrc/{fmpz_mpoly_factor,ca_ext}/io.c` | FLINT 3 slimmed its headers; declarations no longer arrive transitively |
| `csrc/{arb,acb}_mat/entry.c` | the same `rows` removal, in C |
| `_perm_set_one` | one of ~30 FLINT 3 renames, left as a `_Pragma("GCC error")` stub |

Nothing else in the package is affected. In particular all of `fmpz_poly` and
`fmpz_poly_factor` — everything this project calls — is unchanged.

The script is verified: applied to a pristine `cabal get Flint2-0.1.0.5`, it
reproduces the working tree byte-for-byte.

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
