/* The FLINT side of the browser build.
 *
 * The whole surface is `char * -> char *`. That is not laziness: the Haskell
 * module is wasm32-wasi and this one is Emscripten, so they are two instances
 * with two linear memories and no shared pointers. A coarse boundary — one
 * round trip per factorisation, decimal strings both ways — makes that
 * irrelevant, because the marshalling is amortised over an entire
 * factorisation.
 *
 * Wire format is FLINT's own `fmpz_poly_get_str`: "len  c0 c1 ... c_{len-1}".
 * Output: one line per irreducible factor, "<exponent> <poly_str>", with the
 * content first as "c <content>".
 */
#include <flint/fmpz.h>
#include <flint/fmpz_poly.h>
#include <flint/fmpz_poly_factor.h>
#include <emscripten.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

EMSCRIPTEN_KEEPALIVE
char *crit_flint_factor(const char *poly_str)
{
    fmpz_poly_t f;
    fmpz_poly_factor_t fac;
    char *content, *out;
    size_t cap = 1024, len = 0;
    slong i;

    fmpz_poly_init(f);
    if (fmpz_poly_set_str(f, poly_str) != 0) { fmpz_poly_clear(f); return NULL; }

    fmpz_poly_factor_init(fac);
    fmpz_poly_factor(fac, f);

    out = malloc(cap);
    if (!out) { fmpz_poly_factor_clear(fac); fmpz_poly_clear(f); return NULL; }
    out[0] = '\0';

    content = fmpz_get_str(NULL, 10, &fac->c);
    len += snprintf(out + len, cap - len, "c %s\n", content);
    flint_free(content);

    for (i = 0; i < fac->num; i++) {
        char *ps = fmpz_poly_get_str(fac->p + i);
        size_t need = strlen(ps) + 32;
        if (len + need > cap) {
            char *bigger;
            cap = (len + need) * 2;
            bigger = realloc(out, cap);
            if (!bigger) { flint_free(ps); free(out);
                           fmpz_poly_factor_clear(fac); fmpz_poly_clear(f); return NULL; }
            out = bigger;
        }
        len += snprintf(out + len, cap - len, "%ld %s\n", (long) fac->exp[i], ps);
        flint_free(ps);
    }

    fmpz_poly_factor_clear(fac);
    fmpz_poly_clear(f);
    return out;
}

EMSCRIPTEN_KEEPALIVE
void crit_flint_free(char *p) { free(p); }
