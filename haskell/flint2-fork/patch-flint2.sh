#!/bin/sh
# Make Hackage's Flint2-0.1.0.5 build against FLINT 3.4.
#
# Flint2 was last released in November 2023 and targets FLINT 2.x. FLINT 3
# changed several struct layouts and dropped two modules. Everything the
# construction needs (fmpz_poly, fmpz_poly_factor) is unaffected; the
# incompatibilities are all in matrix and modular-group bindings we never call.
#
#   usage:  cabal get Flint2-0.1.0.5 && sh patch-flint2.sh Flint2-0.1.0.5
#
# WARNING. This is a *build* fix, not a port. The patched matrix bindings below
# are structurally wrong under FLINT 3 and must not be used:
#   * `rows` was replaced by `stride`, a slong rather than a row-pointer array,
#     so the fourth field of every C*Mat is now a reinterpreted integer;
#   * fmpz_mod_mat no longer embeds a modulus;
#   * psl2z_word_struct no longer exists.
# The fmpz/fmpq/poly bindings, which is all the benchmark touches, are fine.
set -e
D="${1:?usage: patch-flint2.sh <unpacked-Flint2-dir>}"
cd "$D"

# 1. FLINT 3 renamed `rows` to `stride` in most matrix structs. bool_mat and
#    d_mat kept `rows`, so exclude them.
for f in $(grep -rl ", rows   }" --include='*.hsc' src); do
  case "$f" in
    *Groups/Bool/Mat*|*Support/D/Mat*) continue ;;
  esac
  sed -i '' 's/, rows   }/, stride }/g' "$f"
done

# 2. fmpz_mod_mat_t is now a plain fmpz_mat_struct: no `mat`, no `mod`.
sed -i '' \
  -e 's/#{peek fmpz_mod_mat_struct, mat}/#{peek fmpz_mat_struct, entries}/' \
  -e 's/#{peek fmpz_mod_mat_struct, mod}/#{peek fmpz_mat_struct, r}/' \
  src/Data/Number/Flint/Fmpz/Mod/Mat/FFI.hsc

# 3. psl2z_word_struct is gone; psl2z_struct remains.
sed -i '' \
  -e 's/#{peek psl2z_word_struct, letters}/#{peek psl2z_struct, a}/' \
  -e 's/#{peek psl2z_word_struct, alloc  }/#{peek psl2z_struct, b}/' \
  src/Data/Number/Flint/Acb/Modular/FFI.hsc

# 4. flint/mpf_mat.h and flint/mpfr_mat.h were dropped in FLINT 3. Remove those
#    two modules only — the sibling Mpf/Vec and Mpfr/Vec modules are still good.
rm -rf src/Data/Number/Flint/Support/Mpf/Mat src/Data/Number/Flint/Support/Mpfr/Mat
rm -f  src/Data/Number/Flint/Support/Mpf/Mat.hs src/Data/Number/Flint/Support/Mpfr/Mat.hs
#    Strip every mention: the cabal module lists, the umbrella re-export, and
#    the imports scattered through other matrix modules.
for f in Flint2.cabal $(grep -rl 'Data\.Number\.Flint\.Support\.Mpfr\?\.Mat' src); do
  sed -i '' \
    -e '/Data\.Number\.Flint\.Support\.Mpf\.Mat/d' \
    -e '/Data\.Number\.Flint\.Support\.Mpfr\.Mat/d' \
    "$f"
done

echo "patched $D for FLINT 3.4"
