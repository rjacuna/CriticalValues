{-# LINE 1 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
{-|
module      :  Data.Number.Flint.Arb.Types.FFI
copyright   :  (c) 2022 Hartmut Monien
license     :  GNU GPL, version 2 or above (see LICENSE)
maintainer  :  hmonien@uni-bonn.de
-}
module Data.Number.Flint.Arb.Types.FFI where

import Foreign.C.String
import Foreign.C.Types
import Foreign.ForeignPtr
import Foreign.Ptr ( Ptr, FunPtr, nullPtr, plusPtr )
import Foreign.Storable
import Foreign.Marshal ( free )
import Foreign.Marshal.Array ( advancePtr )

import Data.Number.Flint.Flint.Internal
import Data.Number.Flint.Flint.External
import Data.Number.Flint.Fmpz






-- mag_t -----------------------------------------------------------------------

-- | Data structure containing the CMag pointer
data Mag = Mag {-# UNPACK #-} !(ForeignPtr CMag)
data CMag = CMag CFmpz CMpLimb

instance Storable CMag where
  sizeOf _ = (16)
{-# LINE 34 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
  alignment _ = 8
{-# LINE 35 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
  peek ptr = CMag
    <$> (\hsc_ptr -> peekByteOff hsc_ptr 0) ptr
{-# LINE 37 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 8) ptr
{-# LINE 38 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
  poke = undefined

-- arf_t -----------------------------------------------------------------------

-- | Data structure containing the CArb pointer
data Arf = Arf {-# UNPACK #-} !(ForeignPtr CArf) 
data CArf = CFlint CArf 

instance Storable CArf where
  sizeOf    _ = (32)
{-# LINE 48 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
  alignment _ = 8
{-# LINE 49 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
  peek = error "CArf.peek undefined."
  poke = error "CArf.poke undefined."

-- >>> Arf depends on a c-union which cannot be converted to a Haskell type

-- | Arf rounding
newtype ArfRnd = ArfRnd {_ArfRnd :: CInt}
  deriving (Show, Eq)

-- | Specifies that the result of an operation should be rounded to
-- the nearest representable number in the direction towards zero.
arf_rnd_up    = ArfRnd 1
{-# LINE 61 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
-- | Specifies that the result of an operation should be rounded to
-- the nearest representable number in the direction away from zero.
arf_rnd_down  = ArfRnd 0
{-# LINE 64 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
-- | Specifies that the result of an operation should be rounded to
-- the nearest representable number in the direction towards minus
-- infinity.
arf_rnd_floor = ArfRnd 2
{-# LINE 68 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
-- | Specifies that the result of an operation should be rounded to
-- the nearest representable number in the direction towards plus
-- infinity.
arf_rnd_ceil  = ArfRnd 3
{-# LINE 72 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
-- | Specifies that the result of an operation should be rounded to
-- the nearest representable number, rounding to even if there is a
-- tie between two values.
arf_rnd_near  = ArfRnd 4
{-# LINE 76 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
-- | If passed as the precision parameter to a function, indicates
-- that no rounding is to be performed. __Warning__: use of this value
-- is unsafe in general. It must only be passed as input under the
-- following two conditions:
-- 
--  * The operation in question can inherently be viewed as an exact operation
--    in \(\mathbb{Z}[\tfrac{1}{2}]\) for all possible inputs, provided that
--    the precision is large enough. Examples include addition,
--    multiplication, conversion from integer types to arbitrary-precision
--    floating-point types, and evaluation of some integer-valued functions.
--
--  * The exact result of the operation will certainly fit in memory.
--    Note that, for example, adding two numbers whose exponents are far
--    apart can easily produce an exact result that is far too large to
--    store in memory.
--
--  The typical use case is to work with small integer values, double
--  precision constants, and the like. It is also useful when writing
--  test code. If in doubt, simply try with some convenient high precision
--  instead of using this special value, and check that the result is exact.
arf_prec_exact = ArfRnd 9223372036854775807
{-# LINE 97 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}

-- arb_t -----------------------------------------------------------------------

-- | Data structure containing the CArb pointer
data Arb = Arb {-# UNPACK #-} !(ForeignPtr CArb) 
data CArb = CArb CMag CArf

instance Storable CArb where
  {-# INLINE sizeOf #-}
  sizeOf _ = (48)
{-# LINE 107 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 109 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
  peek = error "CArb.peek undefined."
  poke = error "CArb.poke undefined."
  
-- | string options
type ArbStrOption = CULong

arb_str_none, arb_str_more, arb_str_no_radius, arb_str_condense :: ArbStrOption

-- | Default print option
arb_str_none      = 0
-- | If /arb_str_more/ is added to flags, more (possibly incorrect)
-- digits may be printed
arb_str_more      = 1
{-# LINE 122 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
-- | If /arb_str_no_radius/ is added to /flags/, the radius is not
-- included in the output if at least 1 digit of the midpoint can be
-- printed.
arb_str_no_radius = 2
{-# LINE 126 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}
-- | By adding a multiple m of /arb_str_condense/ to /flags/, strings of
-- more than three times m consecutive digits are condensed, only
-- printing the leading and trailing m digits along with brackets
-- indicating the number of digits omitted (useful when computing
-- values to extremely high precision).
arb_str_condense  = 16
{-# LINE 132 "src/Data/Number/Flint/Arb/Types/FFI.hsc" #-}

-- arb_poly_t ------------------------------------------------------------------

-- | Data structure containing the CArb pointer
data ArbPoly = ArbPoly {-# UNPACK #-} !(ForeignPtr CArbPoly) 
type CArbPoly = CFlint ArbPoly
