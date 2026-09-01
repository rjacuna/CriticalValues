#!/usr/bin/env bash
# Build GMP + MPFR + FLINT for WebAssembly with Emscripten, then link the shim.
#
# NOT based on sagemathinc/wasm-flint, though it was the starting point: that
# repo is unmaintained and two of its three downloads are dead — flintlib.org
# no longer serves flint-2.7.1.tar.gz, and it clones MPIR over git://, which
# GitHub disabled in 2021. Only its MPFR URL still resolves.
#
# So this builds current sources instead, and GMP rather than the abandoned
# MPIR. FLINT 3.4.0 here matches the FLINT the native benchmark links against,
# which means the browser and the CLI run the same factoriser.
set -e

GMP_VERSION=6.3.0
MPFR_VERSION=4.2.2
FLINT_VERSION=3.4.0

HERE="$(cd "$(dirname "$0")" && pwd)"

# Build outside the repo. GMP's configure refuses to run under a path
# containing an apostrophe or a space ("unsafe absolute working directory
# name"), and this checkout lives under "Tomorrow's Talk". Override with
# CRIT_WASM_BUILD if you want it elsewhere.
BUILD="${CRIT_WASM_BUILD:-$HOME/.cache/crit-wasm}"
PREFIX="$BUILD/local"
mkdir -p "$BUILD" "$PREFIX"
cd "$BUILD"

fetch() { [ -f "$2" ] || curl -sSL "$1" -o "$2"; }

# --- GMP -------------------------------------------------------------------
# --disable-assembly is required: GMP's hand-written asm is host-specific and
# there is none for wasm.
if [ ! -f "$PREFIX/lib/libgmp.a" ]; then
  fetch "https://ftp.gnu.org/gnu/gmp/gmp-$GMP_VERSION.tar.xz" "gmp.tar.xz"
  rm -rf "gmp-$GMP_VERSION"; tar xf gmp.tar.xz
  cd "gmp-$GMP_VERSION"
  # GMP generates tables with a *build-machine* compiler, distinct from the
  # cross compiler. emconfigure points it at emsdk's clang, which cannot
  # produce host binaries; say Apple clang explicitly. (Not `gcc` -- on this
  # machine that resolves to Alire's GNAT toolchain, whose headers are broken
  # on Darwin 25. See haskell/WEB.md.)
  emconfigure ./configure --host=none --disable-assembly --disable-shared \
      --enable-static --prefix="$PREFIX" \
      CC_FOR_BUILD=/usr/bin/clang HOST_CC=/usr/bin/clang
  emmake make -j4
  emmake make install
  cd "$BUILD"
fi

# --- MPFR ------------------------------------------------------------------
if [ ! -f "$PREFIX/lib/libmpfr.a" ]; then
  fetch "https://www.mpfr.org/mpfr-$MPFR_VERSION/mpfr-$MPFR_VERSION.tar.xz" "mpfr.tar.xz"
  rm -rf "mpfr-$MPFR_VERSION"; tar xf mpfr.tar.xz
  cd "mpfr-$MPFR_VERSION"
  emconfigure ./configure --host=none --with-gmp="$PREFIX" --disable-shared \
      --enable-static --prefix="$PREFIX"
  emmake make -j4
  emmake make install
  cd "$BUILD"
fi

# --- FLINT -----------------------------------------------------------------
if [ ! -f "$PREFIX/lib/libflint.a" ]; then
  fetch "https://github.com/flintlib/flint/releases/download/v$FLINT_VERSION/flint-$FLINT_VERSION.tar.gz" "flint.tar.gz"
  rm -rf "flint-$FLINT_VERSION"; tar xf flint.tar.gz
  cd "flint-$FLINT_VERSION"
  # FLINT enables its getrusage-based profiler whenever __unix__ is defined,
  # which Emscripten does — but Emscripten does not declare getrusage, and the
  # non-Linux path then reaches for sysctl/getpid as well. The profiler is
  # diagnostic only and never on the factoring path, so switch it off at the
  # guard rather than patch inside it.
  sed -i '' \
    's|^#if (defined(__unix__) \&\& !defined(__CYGWIN__)) \|\| defined(__APPLE__)$|#if ((defined(__unix__) \&\& !defined(__CYGWIN__)) \|\| defined(__APPLE__)) \&\& !defined(__EMSCRIPTEN__)|' \
    src/profiler.h
  emconfigure ./configure --host=none --disable-assembly --disable-shared \
      --enable-static --with-gmp="$PREFIX" --with-mpfr="$PREFIX" --prefix="$PREFIX"
  emmake make -j4
  emmake make install
  cd "$BUILD"
fi

# --- the shim --------------------------------------------------------------
emcc -O2 "$HERE/crit_flint.c" \
  -I"$PREFIX/include" -L"$PREFIX/lib" -lflint -lmpfr -lgmp \
  -sEXPORTED_FUNCTIONS='["_crit_flint_factor","_crit_flint_free","_malloc","_free"]' \
  -sEXPORTED_RUNTIME_METHODS='["ccall","cwrap","stringToNewUTF8","UTF8ToString"]' \
  -sALLOW_MEMORY_GROWTH=1 -sMODULARIZE=1 -sEXPORT_ES6=1 \
  -sENVIRONMENT=web,worker,node -sEXPORT_NAME=createFlintModule \
  -o "$HERE/flint.mjs"

echo "built $HERE/flint.mjs and flint.wasm"
