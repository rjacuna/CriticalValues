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

# 5. fmpz_lll_check_babai_heuristic takes mpf_mat arguments, so its Haskell
#    signature needs CMpfMat from the module removed above. The underlying
#    FLINT function went with mpf_mat; drop the declaration. (Its sibling
#    fmpz_lll_check_babai_heuristic_d is unaffected and stays.)
sed -i '' \
  -e '/fmpz_lll\.h fmpz_lll_check_babai_heuristic"/,+1d' \
  -e '/, fmpz_lll_check_babai_heuristic$/d' \
  src/Data/Number/Flint/Fmpz/LLL/FFI.hsc

# 6. Flint2 vendors ~160 small C helpers in csrc/. Two of them are functions
#    FLINT 3 now provides itself, with different signatures, so the vendored
#    declaration and FLINT's header collide. Give the vendored copies the
#    trailing underscore Flint2 already uses for such shims. For
#    fmpz_factor_fprint the Haskell binding follows the shim; for
#    fmpz_mpoly_q_get_str_pretty the binding is header-qualified and so now
#    resolves to FLINT's own, which is what it wanted all along.
for n in fmpz_factor_fprint fmpz_mpoly_q_get_str_pretty; do
  for f in $(grep -rl "$n" csrc 2>/dev/null); do sed -i '' "s/$n/${n}_/g" "$f"; done
  for f in $(grep -rl "\"$n\"" src 2>/dev/null); do sed -i '' "s/\"$n\"/\"${n}_\"/g" "$f"; done
done

# 7. FLINT 3 slimmed its headers, so some declarations are no longer pulled in
#    transitively. Two vendored files need an explicit include. Insert after the
#    last existing #include -- these files open with a block comment, so
#    appending at line 1 would land inside it.
add_include() {
  awk -v inc="$2" '
    { l[NR] = $0; if ($0 ~ /^#include/) last = NR }
    END { for (i = 1; i <= NR; i++) { print l[i]; if (i == last) print inc } }
  ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
add_include csrc/fmpz_mpoly_factor/io.c '#include <flint/fmpz.h>'
add_include csrc/ca_ext/io.c            '#include <flint/calcium.h>'

# 8. The same `rows` removal hits two vendored C helpers. FLINT 3 supplies
#    accessor macros, so use those rather than open-coding entries+stride.
sed -i '' 's|return mat->rows\[i\] + j;|return arb_mat_entry(mat, i, j);|' csrc/arb_mat/entry.c
sed -i '' 's|return mat->rows\[i\] + j;|return acb_mat_entry(mat, i, j);|' csrc/acb_mat/entry.c

# 9. And the vendored C helper for the dropped mpfr_mat module goes with it.
rm -rf csrc/mpfr_mat csrc/mpfr_mat.h
sed -i '' \
  -e '/csrc\/mpfr_mat\/swap_entrywise\.c/d' \
  -e '/^      mpfr_mat\.h$/d' \
  Flint2.cabal

# 10. FLINT 3 renamed ~30 functions, leaving _Pragma("GCC error") stubs behind.
#     Exactly one is used by the vendored C.
sed -i '' 's/_perm_set_one/_perm_one/g' csrc/psl2z/word_problem.c

echo "patched $D for FLINT 3.4"
