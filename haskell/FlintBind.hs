{-# LANGUAGE ForeignFunctionInterface #-}

-- | Factoring via FLINT, through the Hackage @Flint2@ bindings.
--
-- @Flint2@ wraps FLINT in Haskell types (@FmpzPoly@, @FmpzPolyFactor@) rather
-- than raw @ccall@s, and is maintained, so it is the right way to reach FLINT
-- from native Haskell. It does not build against FLINT 3.4 unpatched — see
-- @flint2-fork/@ for the five struct incompatibilities and the patch.
--
-- The boundary here is still a string, because FLINT's own @fmpz_poly_get_str@
-- and @fmpz_poly_set_str@ are the cheapest exact transport and the cost is
-- amortised over a whole factorisation.
module FlintBind (flintIrreducibleFactors) where

import Data.Number.Flint.Fmpz.Poly
import Data.Number.Flint.Fmpz.Poly.Factor
import Foreign.C.String (CString, peekCString, withCString)
import Foreign.Marshal.Array (advancePtr)
import Foreign.Ptr (Ptr)
import Foreign.Storable (peek)
import Poly

foreign import ccall "flint.h flint_free" flint_free :: CString -> IO ()

-- | FLINT's wire format: @"len  c0 c1 ... c_{len-1}"@.
toFlintStr :: Poly -> String
toFlintStr p = show (length cs) ++ "  " ++ unwords (map show cs)
  where cs = coeffs p

fromFlintStr :: String -> Poly
fromFlintStr s = case words s of
  (_len : cs) -> poly (map read cs)
  _           -> zero

-- | The distinct irreducible factors of @p@, multiplicities discarded.
flintIrreducibleFactors :: Poly -> IO [Poly]
flintIrreducibleFactors p
  | isZero p  = return []
  | otherwise = fmap snd $ withNewFmpzPoly $ \pp -> do
      _ <- withCString (toFlintStr p) (fmpz_poly_set_str pp)
      fmap snd $ withNewFmpzPolyFactor $ \fac -> do
        fmpz_poly_factor fac pp
        CFmpzPolyFactor _ parr _ num _ <- peek fac
        mapM (readFactor parr) [0 .. fromIntegral num - 1]
  where
    readFactor parr i = do
      cstr <- fmpz_poly_get_str (parr `advancePtr` i)
      s <- peekCString cstr
      flint_free cstr
      return (fromFlintStr s)
