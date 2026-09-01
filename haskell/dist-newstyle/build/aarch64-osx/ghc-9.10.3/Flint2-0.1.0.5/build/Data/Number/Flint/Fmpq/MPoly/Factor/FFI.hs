{-# LINE 1 "src/Data/Number/Flint/Fmpq/MPoly/Factor/FFI.hsc" #-}
{-|
module      :  Data.Number.Flint.Fmpq.MPoly.Factor.FFI
copyright   :  (c) 2022 Hartmut Monien
license     :  GNU GPL, version 2 or above (see LICENSE)
maintainer  :  hmonien@uni-bonn.de
-}
module Data.Number.Flint.Fmpq.MPoly.Factor.FFI (
  -- * Factorisation of multivariate polynomials over the rational numbers
  -- * Memory management
    FmpqMPolyFactor (..)
  , CFmpqMPolyFactor (..)
  , newFmpqMPolyFactor
  , withFmpqMPolyFactor
  -- * 
  , fmpq_mpoly_factor_init
  , fmpq_mpoly_factor_clear
  -- * Basic manipulation
  -- , fmpq_mpoly_factor_swap
  , fmpq_mpoly_factor_length
  , fmpq_mpoly_factor_get_constant_fmpq
  , fmpq_mpoly_factor_get_base
  , fmpq_mpoly_factor_swap_base
  , fmpq_mpoly_factor_get_exp_si
  , fmpq_mpoly_factor_sort
  , fmpq_mpoly_factor_make_monic
  , fmpq_mpoly_factor_make_integral
  -- * Factorisation
  , fmpq_mpoly_factor_squarefree
  , fmpq_mpoly_factor
) where

-- factorisation of multivariate polynomials over the rational numbers ---------

import Foreign.Ptr
import Foreign.ForeignPtr
import Foreign.C.Types
import Foreign.C.String
import Foreign.Storable
import Foreign.Marshal.Array ( advancePtr )

import Data.Number.Flint.Flint
import Data.Number.Flint.MPoly
import Data.Number.Flint.Fmpz
import Data.Number.Flint.Fmpz.Poly
import Data.Number.Flint.Fmpz.MPoly
import Data.Number.Flint.Fmpz.MPoly.Q
import Data.Number.Flint.Fmpq
import Data.Number.Flint.Fmpq.Poly
import Data.Number.Flint.Fmpq.MPoly







-- fmpq_mpoly_factor_t ---------------------------------------------------------

data FmpqMPolyFactor =
  FmpqMPolyFactor {-# UNPACK #-} !(ForeignPtr CFmpqMPolyFactor)
data CFmpqMPolyFactor =
  CFmpqMPolyFactor (Ptr CFmpq) (Ptr CFmpqMPoly)
                   (Ptr CFmpz) CLong CLong

instance Storable CFmpqMPolyFactor where
  {-# INLINE sizeOf #-}
  sizeOf _ = (48)
{-# LINE 68 "src/Data/Number/Flint/Fmpq/MPoly/Factor/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 70 "src/Data/Number/Flint/Fmpq/MPoly/Factor/FFI.hsc" #-}
  peek ptr = CFmpqMPolyFactor
    <$> (\hsc_ptr -> peekByteOff hsc_ptr 0) ptr
{-# LINE 72 "src/Data/Number/Flint/Fmpq/MPoly/Factor/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 16) ptr
{-# LINE 73 "src/Data/Number/Flint/Fmpq/MPoly/Factor/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 24) ptr
{-# LINE 74 "src/Data/Number/Flint/Fmpq/MPoly/Factor/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 32) ptr
{-# LINE 75 "src/Data/Number/Flint/Fmpq/MPoly/Factor/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 40) ptr
{-# LINE 76 "src/Data/Number/Flint/Fmpq/MPoly/Factor/FFI.hsc" #-}
  poke = error "CFmpqMPolyFactor.poke: Not defined"

newFmpqMPolyFactor ctx@(FmpqMPolyCtx pctx) = do
  x <- mallocForeignPtr
  withForeignPtr x $ \x -> do
    withFmpqMPolyCtx ctx $ \ctx -> do
      fmpq_mpoly_factor_init x ctx
      addForeignPtrFinalizerEnv p_fmpq_mpoly_factor_clear x pctx
  return $ FmpqMPolyFactor x

withFmpqMPolyFactor (FmpqMPolyFactor p) f = do
  withForeignPtr p $ \fp -> f fp >>= return . (FmpqMPolyFactor p,)

-- Memory management -----------------------------------------------------------

-- | /fmpq_mpoly_factor_init/ /f/ /ctx/ 
--
-- Initialise /f/.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_init"
  fmpq_mpoly_factor_init :: Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyCtx -> IO ()

-- | /fmpq_mpoly_factor_clear/ /f/ /ctx/ 
--
-- Clear /f/.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_clear"
  fmpq_mpoly_factor_clear :: Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyCtx -> IO ()

foreign import ccall "fmpq_mpoly_factor.h &fmpq_mpoly_factor_clear"
  p_fmpq_mpoly_factor_clear :: FunPtr (Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyCtx -> IO ())

-- Basic manipulation ----------------------------------------------------------

-- -- | /fmpq_mpoly_factor_swap/ /f/ /g/ /ctx/ 
-- --
-- -- Efficiently swap /f/ and /g/.
-- foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_swap"
--   fmpq_mpoly_factor_swap :: Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyCtx -> IO ()

-- | /fmpq_mpoly_factor_length/ /f/ /ctx/ 
--
-- Return the length of the product in /f/.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_length"
  fmpq_mpoly_factor_length :: Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyCtx -> IO CLong

-- | /fmpq_mpoly_factor_get_constant_fmpq/ /c/ /f/ /ctx/ 
--
-- Set /c/ to the constant of /f/.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_get_constant_fmpq"
  fmpq_mpoly_factor_get_constant_fmpq :: Ptr CFmpq -> Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyCtx -> IO ()

-- | /fmpq_mpoly_factor_get_base/ /B/ /f/ /i/ /ctx/ 
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_get_base"
  fmpq_mpoly_factor_get_base :: Ptr CFmpqMPoly -> Ptr CFmpqMPolyFactor -> CLong -> Ptr CFmpqMPolyCtx -> IO ()
-- | /fmpq_mpoly_factor_swap_base/ /B/ /f/ /i/ /ctx/ 
--
-- Set (resp. swap) /B/ to (resp. with) the base of the term of index /i/
-- in /A/.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_swap_base"
  fmpq_mpoly_factor_swap_base :: Ptr CFmpqMPoly -> Ptr CFmpqMPolyFactor -> CLong -> Ptr CFmpqMPolyCtx -> IO ()

-- | /fmpq_mpoly_factor_get_exp_si/ /f/ /i/ /ctx/ 
--
-- Return the exponent of the term of index /i/ in /A/. It is assumed to
-- fit an @slong@.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_get_exp_si"
  fmpq_mpoly_factor_get_exp_si :: Ptr CFmpqMPolyFactor -> CLong -> Ptr CFmpqMPolyCtx -> IO CLong

-- | /fmpq_mpoly_factor_sort/ /f/ /ctx/ 
--
-- Sort the product of /f/ first by exponent and then by base.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_sort"
  fmpq_mpoly_factor_sort :: Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyCtx -> IO ()

-- | /fmpq_mpoly_factor_make_monic/ /f/ /ctx/ 
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_make_monic"
  fmpq_mpoly_factor_make_monic :: Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyCtx -> IO CInt
-- | /fmpq_mpoly_factor_make_integral/ /f/ /ctx/ 
--
-- Make the bases in /f/ monic (resp. integral and primitive with positive
-- leading coefficient). Return \(1\) for success, \(0\) for failure.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_make_integral"
  fmpq_mpoly_factor_make_integral :: Ptr CFmpqMPolyFactor -> Ptr CFmpqMPolyCtx -> IO CInt

-- Factorisation ---------------------------------------------------------------




-- | /fmpq_mpoly_factor_squarefree/ /f/ /A/ /ctx/ 
--
-- Set /f/ to a factorization of /A/ where the bases are primitive and
-- pairwise relatively prime. If the product of all irreducible factors
-- with a given exponent is desired, it is recommended to call
-- @fmpq_mpoly_factor_sort@ and then multiply the bases with the desired
-- exponent.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor_squarefree"
  fmpq_mpoly_factor_squarefree :: Ptr CFmpqMPolyFactor -> Ptr CFmpqMPoly -> Ptr CFmpqMPolyCtx -> IO CInt

-- | /fmpq_mpoly_factor/ /f/ /A/ /ctx/ 
--
-- Set /f/ to a factorization of /A/ where the bases are irreducible.
foreign import ccall "fmpq_mpoly_factor.h fmpq_mpoly_factor"
  fmpq_mpoly_factor :: Ptr CFmpqMPolyFactor -> Ptr CFmpqMPoly -> Ptr CFmpqMPolyCtx -> IO CInt

