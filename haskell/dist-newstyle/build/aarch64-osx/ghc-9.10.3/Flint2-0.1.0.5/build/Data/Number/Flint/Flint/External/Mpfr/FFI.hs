{-# LINE 1 "src/Data/Number/Flint/Flint/External/Mpfr/FFI.hsc" #-}
{-|
module      :  Data.Number.Flint.Flint.External.Mpfr.FFI
copyright   :  (c) 2022 Hartmut Monien
license     :  GNU GPL, version 2 or above (see LICENSE)
maintainer  :  hmonien@uni-bonn.de
-}
module Data.Number.Flint.Flint.External.Mpfr.FFI where

import Data.Word
import Foreign.C.Types
import Foreign.ForeignPtr
import Foreign.Storable

import Data.Number.Flint.Flint.Internal



-- MPFR ------------------------------------------------------------------------

-- | Data structure containing the CMpfr pointer
data Mpfr = CMpfr {-# UNPACK #-} !(ForeignPtr CMpfr) 
type CMpfr = CFlint Mpfr

newtype CMpfrRnd  = CMpfrRnd  {_MpfrRnd  :: CInt} deriving (Show, Eq)
newtype CMpfrPrec = CMpfrPrec {_MpfrPrec :: CInt} deriving (Show, Eq)

instance Storable CMpfr where
  {-# INLINE sizeOf #-}
  sizeOf   _ = (32)
{-# LINE 30 "src/Data/Number/Flint/Flint/External/Mpfr/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 32 "src/Data/Number/Flint/Flint/External/Mpfr/FFI.hsc" #-}
  peek = undefined
  poke = undefined