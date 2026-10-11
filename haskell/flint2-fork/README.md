# Flint2 moved to flintell

The maintained native fork is now in `../../../flintell/vendor/Flint2`.
`../cabal.project` uses that package directly. Its FLINT version and wasm
factorizer are shared with FunDom through the standalone flintell repository.

From `~/Projects/flintell`:

```sh
./scripts/build-deps.sh native
./scripts/configure-cabal.sh ../CriticalValues/haskell
```

Then run `cabal build all` from `CriticalValues/haskell`.

The former vendored `Flint2-0.1.0.5` sources have been removed; the shared
flintell repository is now the source of the binding.
The old patch script has been removed: it knowingly reinterpreted matrix
strides as pointers and redirected PSL2Z word fields to unrelated offsets.
See flintell's `vendor/Flint2/PORTING.md` for the replacement and its scope.
