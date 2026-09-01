{-# LINE 1 "src/Data/Number/Flint/Fq/NMod/MPoly/Factor/FFI.hsc" #-}
{-|
module      :  Data.Number.Flint.Fq.NMod.MPoly.Factor.FFI
copyright   :  (c) 2022 Hartmut Monien
license     :  GNU GPL, version 2 or above (see LICENSE)
maintainer  :  hmonien@uni-bonn.de
-}
module Data.Number.Flint.Fq.NMod.MPoly.Factor.FFI (
  -- * Factorisation of multivariate polynomials over finite fields of
  -- word-sized characteristic
    FqNModMPolyFactor (..)
  , CFqNModMPolyFactor (..)
  , newFqNModMPolyFactor
  , withFqNModMPolyFactor 
  -- * Memory management
  , fq_nmod_mpoly_factor_init
  , fq_nmod_mpoly_factor_clear
  -- * Basic manipulation
  , fq_nmod_mpoly_factor_swap
  , fq_nmod_mpoly_factor_length
  , fq_nmod_mpoly_factor_get_constant_fq_nmod
  , fq_nmod_mpoly_factor_get_base
  , fq_nmod_mpoly_factor_swap_base
  , fq_nmod_mpoly_factor_get_exp_si
  , fq_nmod_mpoly_factor_sort
  -- * Factorisation
  , fq_nmod_mpoly_factor_squarefree
  , fq_nmod_mpoly_factor
) where

-- Factorisation of multivariate polynomials over finite fields of
-- word-sized characteristic

import Foreign.C.String
import Foreign.C.Types
import qualified Foreign.Concurrent
import Foreign.ForeignPtr
import Foreign.Ptr ( Ptr, FunPtr, plusPtr )
import Foreign.Storable
import Foreign.Marshal ( free )

import Data.Number.Flint.Flint
import Data.Number.Flint.MPoly
import Data.Number.Flint.Fmpz
import Data.Number.Flint.Fmpz.Mod.Poly
import Data.Number.Flint.NMod.Poly
import Data.Number.Flint.NMod.MPoly
import Data.Number.Flint.Fq
import Data.Number.Flint.Fq.Poly
import Data.Number.Flint.Fq.NMod
import Data.Number.Flint.Fq.NMod.MPoly
import Data.Number.Flint.Fq.NMod.Types







-- fq_nmod_mpoly_factor_t ------------------------------------------------------

data FqNModMPolyFactor =
  FqNModMPolyFactor {-# UNPACK #-} !(ForeignPtr CFqNModMPolyFactor)
data CFqNModMPolyFactor =
  CFqNModMPolyFactor (Ptr CFqNMod) (Ptr CFqNModMPoly) (Ptr CFmpz) CLong CLong

instance Storable CFqNModMPolyFactor where
  {-# INLINE sizeOf #-}
  sizeOf _ = (80)
{-# LINE 69 "src/Data/Number/Flint/Fq/NMod/MPoly/Factor/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 71 "src/Data/Number/Flint/Fq/NMod/MPoly/Factor/FFI.hsc" #-}
  peek ptr = CFqNModMPolyFactor
    <$> (\hsc_ptr -> peekByteOff hsc_ptr 0) ptr
{-# LINE 73 "src/Data/Number/Flint/Fq/NMod/MPoly/Factor/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 48) ptr
{-# LINE 74 "src/Data/Number/Flint/Fq/NMod/MPoly/Factor/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 56) ptr
{-# LINE 75 "src/Data/Number/Flint/Fq/NMod/MPoly/Factor/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 64) ptr
{-# LINE 76 "src/Data/Number/Flint/Fq/NMod/MPoly/Factor/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 72) ptr
{-# LINE 77 "src/Data/Number/Flint/Fq/NMod/MPoly/Factor/FFI.hsc" #-}
  poke = error "CFqNModMPolyFactor.poke: Not defined"

newFqNModMPolyFactor ctx@(FqNModMPolyCtx fctx) = do
  x <- mallocForeignPtr
  withForeignPtr x $ \x -> do
    withFqNModMPolyCtx ctx $ \ctx -> do
      fq_nmod_mpoly_factor_init x ctx
      addForeignPtrFinalizerEnv p_fq_nmod_mpoly_factor_clear x fctx
  return $ FqNModMPolyFactor x

withFqNModMPolyFactor (FqNModMPolyFactor p) f = do
  withForeignPtr p $ \fp -> f fp >>= return . (FqNModMPolyFactor p,)
  
-- Memory management -----------------------------------------------------------

-- | /fq_nmod_mpoly_factor_init/ /f/ /ctx/ 
--
-- Initialise /f/.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_init"
  fq_nmod_mpoly_factor_init :: Ptr CFqNModMPolyFactor -> Ptr CFqNModMPolyCtx -> IO ()

-- | /fq_nmod_mpoly_factor_clear/ /f/ /ctx/ 
--
-- Clear /f/.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_clear"
  fq_nmod_mpoly_factor_clear :: Ptr CFqNModMPolyFactor -> Ptr CFqNModMPolyCtx -> IO ()

foreign import ccall "fq_nmod_mpoly_factor.h &fq_nmod_mpoly_factor_clear"
  p_fq_nmod_mpoly_factor_clear :: FunPtr (Ptr CFqNModMPolyFactor -> Ptr CFqNModMPolyCtx -> IO ())

-- Basic manipulation ----------------------------------------------------------

-- | /fq_nmod_mpoly_factor_swap/ /f/ /g/ /ctx/ 
--
-- Efficiently swap /f/ and /g/.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_swap"
  fq_nmod_mpoly_factor_swap :: Ptr CFqNModMPolyFactor -> Ptr CFqNModMPolyFactor -> Ptr CFqNModMPolyCtx -> IO ()

-- | /fq_nmod_mpoly_factor_length/ /f/ /ctx/ 
--
-- Return the length of the product in /f/.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_length"
  fq_nmod_mpoly_factor_length :: Ptr CFqNModMPolyFactor -> Ptr CFqNModMPolyCtx -> IO CLong

-- | /fq_nmod_mpoly_factor_get_constant_fq_nmod/ /c/ /f/ /ctx/ 
--
-- Set \(c\) to the constant of /f/.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_get_constant_fq_nmod"
  fq_nmod_mpoly_factor_get_constant_fq_nmod :: Ptr CFqNMod -> Ptr CFqNModMPolyFactor -> Ptr CFqNModMPolyCtx -> IO ()

-- | /fq_nmod_mpoly_factor_get_base/ /p/ /f/ /i/ /ctx/ 
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_get_base"
  fq_nmod_mpoly_factor_get_base :: Ptr CFqNModMPoly -> Ptr CFqNModMPolyFactor -> CLong -> Ptr CFqNModMPolyCtx -> IO ()
-- | /fq_nmod_mpoly_factor_swap_base/ /p/ /f/ /i/ /ctx/ 
--
-- Set (resp. swap) /B/ to (resp. with) the base of the term of index /i/
-- in /A/.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_swap_base"
  fq_nmod_mpoly_factor_swap_base :: Ptr CFqNModMPoly -> Ptr CFqNModMPolyFactor -> CLong -> Ptr CFqNModMPolyCtx -> IO ()

-- | /fq_nmod_mpoly_factor_get_exp_si/ /f/ /i/ /ctx/ 
--
-- Return the exponent of the term of index /i/ in /A/. It is assumed to
-- fit an @slong@.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_get_exp_si"
  fq_nmod_mpoly_factor_get_exp_si :: Ptr CFqNModMPolyFactor -> CLong -> Ptr CFqNModMPolyCtx -> IO CLong

-- | /fq_nmod_mpoly_factor_sort/ /f/ /ctx/ 
--
-- Sort the product of /f/ first by exponent and then by base.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_sort"
  fq_nmod_mpoly_factor_sort :: Ptr CFqNModMPolyFactor -> Ptr CFqNModMPolyCtx -> IO ()

-- Factorisation ---------------------------------------------------------------

-- | /fq_nmod_mpoly_factor_squarefree/ /f/ /A/ /ctx/ 
--
-- Set /f/ to a factorization of /A/ where the bases are primitive and
-- pairwise relatively prime. If the product of all irreducible factors
-- with a given exponent is desired, it is recommended to call
-- @fq_nmod_mpoly_factor_sort@ and then multiply the bases with the desired
-- exponent.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor_squarefree"
  fq_nmod_mpoly_factor_squarefree :: Ptr CFqNModMPolyFactor -> Ptr CFqNModMPoly -> Ptr CFqNModMPolyCtx -> IO CInt

-- | /fq_nmod_mpoly_factor/ /f/ /A/ /ctx/ 
--
-- Set /f/ to a factorization of /A/ where the bases are irreducible.
foreign import ccall "fq_nmod_mpoly_factor.h fq_nmod_mpoly_factor"
  fq_nmod_mpoly_factor :: Ptr CFqNModMPolyFactor -> Ptr CFqNModMPoly -> Ptr CFqNModMPolyCtx -> IO CInt

