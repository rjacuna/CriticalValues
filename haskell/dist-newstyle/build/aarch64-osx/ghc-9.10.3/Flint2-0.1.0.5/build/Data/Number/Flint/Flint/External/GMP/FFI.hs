{-# LINE 1 "src/Data/Number/Flint/Flint/External/GMP/FFI.hsc" #-}
{-|
module      :  Data.Number.Flint.Flint.External.GMP.FFI
copyright   :  (c) 2022 Hartmut Monien
license     :  GNU GPL, version 2 or above (see LICENSE)
maintainer  :  hmonien@uni-bonn.de
-}
module Data.Number.Flint.Flint.External.GMP.FFI where

import Data.Int
import Data.Word
import Foreign.ForeignPtr
import Foreign.C.Types
import Foreign.Storable

import Data.Number.Flint.Flint.Internal





-- BUG: should be set by #type mp_limb_t
-- type MpLimb   = CULong
type CMpLimb   = Word64
{-# LINE 24 "src/Data/Number/Flint/Flint/External/GMP/FFI.hsc" #-}
type CMpSLimb  = Int64
{-# LINE 25 "src/Data/Number/Flint/Flint/External/GMP/FFI.hsc" #-}
type CMpSize   = Int64
{-# LINE 26 "src/Data/Number/Flint/Flint/External/GMP/FFI.hsc" #-}
type CMpBitCnt = Word64
{-# LINE 27 "src/Data/Number/Flint/Flint/External/GMP/FFI.hsc" #-}

-- | Data structure containing the CMp pointer
data Mp = CMp {-# UNPACK #-} !(ForeignPtr CMp) 
type CMp = CFlint Mp

-- | Data structure containing the CMpz pointer
data Mpz = CMpz {-# UNPACK #-} !(ForeignPtr CMpz) 
type CMpz = CFlint Mpz

-- | Data structure containing the CMpq pointer
data Mpq = CMpq {-# UNPACK #-} !(ForeignPtr CMpq) 
type CMpq = CFlint Mpq

-- | Data structure containing the CMpf pointer
data Mpf = CMpf {-# UNPACK #-} !(ForeignPtr CMpf) 
type CMpf = CFlint Mpf

-- | Data structure containing the CGmpRandstate pointer
data GmpRandstate = GmpRandstate {-# UNPACK #-} !(ForeignPtr CGmpRandstate)
type CGmpRandstate = CFlint GmpRandstate

instance Storable CMpf where
  {-# INLINE sizeOf #-}
  sizeOf   _ = (24)
{-# LINE 51 "src/Data/Number/Flint/Flint/External/GMP/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 53 "src/Data/Number/Flint/Flint/External/GMP/FFI.hsc" #-}
  peek = undefined
  poke = undefined
