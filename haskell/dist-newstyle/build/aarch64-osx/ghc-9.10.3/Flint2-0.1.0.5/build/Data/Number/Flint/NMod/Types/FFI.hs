{-# LINE 1 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
{-|
module      :  Data.Number.Flint.NMod.Types.FFI
copyright   :  (c) 2022 Hartmut Monien
license     :  GNU GPL, version 2 or above (see LICENSE)
maintainer  :  hmonien@uni-bonn.de
-}
module Data.Number.Flint.NMod.Types.FFI where

import Foreign.C.Types
import Foreign.ForeignPtr
import Foreign.Ptr
import Foreign.Storable

import Data.Number.Flint.Flint
import Data.Number.Flint.Flint.Internal
import Data.Number.Flint.NMod



-- nmod_poly_t -----------------------------------------------------------------

data NModPoly = NModPoly {-# UNPACK #-} !(ForeignPtr CNModPoly)
type CNModPoly = CFlint NModPoly

instance Storable CNModPoly where
  {-# INLINE sizeOf #-}
  sizeOf _ = (48)
{-# LINE 28 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 30 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  peek = undefined
  poke = undefined

-- nmod_poly_factor_t ----------------------------------------------------------

data NModPolyFactor = NModPolyFactor {-# UNPACK #-}
  !(ForeignPtr CNModPolyFactor)
data CNModPolyFactor = CNModPolyFactor (Ptr CNModPoly) (Ptr CLong) CLong CLong

instance Storable CNModPolyFactor where
  {-# INLINE sizeOf #-}
  sizeOf _ = (32)
{-# LINE 42 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 44 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  peek ptr = do
    p     <- (\hsc_ptr -> peekByteOff hsc_ptr 0) ptr
{-# LINE 46 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    exp   <- (\hsc_ptr -> peekByteOff hsc_ptr 8) ptr
{-# LINE 47 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    num   <- (\hsc_ptr -> peekByteOff hsc_ptr 16) ptr
{-# LINE 48 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    alloc <- (\hsc_ptr -> peekByteOff hsc_ptr 24) ptr
{-# LINE 49 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    return $ CNModPolyFactor p exp num alloc
  poke = undefined

-- nmod_mat_t ------------------------------------------------------------------

data NModMat = NModMat {-# UNPACK #-} !(ForeignPtr CNModMat)
data CNModMat = CNModMat (Ptr CMpLimb) CLong CLong (Ptr (Ptr CMpLimb)) (Ptr CNMod)

instance Storable CNModMat where
  {-# INLINE sizeOf #-}
  sizeOf _ = (56)
{-# LINE 60 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 62 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  peek ptr = CNModMat
    <$> (\hsc_ptr -> peekByteOff hsc_ptr 0) ptr
{-# LINE 64 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 8) ptr
{-# LINE 65 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 16) ptr
{-# LINE 66 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 24) ptr
{-# LINE 67 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 32) ptr
{-# LINE 68 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  poke = undefined

-- nmod_poly_mat_t -------------------------------------------------------------

data NModPolyMat = NModPolyMat {-# UNPACK #-} !(ForeignPtr CNModPolyMat)
data CNModPolyMat = CNModPolyMat (Ptr CNModPoly) CLong CLong (Ptr (Ptr CNModPoly)) (Ptr CNMod)

instance Storable CNModPolyMat where
  {-# INLINE sizeOf #-}
  sizeOf _ = (40)
{-# LINE 78 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 80 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  peek ptr = CNModPolyMat
    <$> (\hsc_ptr -> peekByteOff hsc_ptr 0) ptr
{-# LINE 82 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 8) ptr
{-# LINE 83 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 16) ptr
{-# LINE 84 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 24) ptr
{-# LINE 85 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 32) ptr
{-# LINE 86 "src/Data/Number/Flint/NMod/Types/FFI.hsc" #-}
  poke = error "CNModPolyMat.poke: Not defined."
