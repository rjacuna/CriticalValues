{-# LINE 1 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
{-|
module      :  Data.Number.Flint.Calcium.FFI
copyright   :  (c) 2023 Hartmut Monien
license     :  GNU GPL, version 2 or above (see LICENSE)
maintainer  :  hmonien@uni-bonn.de
-}
module Data.Number.Flint.Calcium.FFI (
  -- * Calcium
    CalciumStream (..)
  , CCalciumStream (..)
  , newCalciumStreamFile
  , newCalciumStreamStr
  , withCalciumStream
  , CCalciumFunctionCode (..)
  -- * Version
  , calcium_version
  -- * Triple-valued logic
  , t_true
  , t_false
  , t_unknown
  , CTruth (..)
  -- * Flint, Arb and Antic extras
  --, calcium_fmpz_hash
  , calcium_func_name
  -- * Input and output
  , calcium_stream_init_file
  , calcium_stream_init_str
  , calcium_write
  , calcium_write_free
  , calcium_write_si
  , calcium_write_fmpz
  , calcium_write_arb
  , calcium_write_acb
  -- * Function codes
  , ca_QQBar
  , ca_Neg
  , ca_Add
  , ca_Sub
  , ca_Mul
  , ca_Div
  , ca_Sqrt
  , ca_Cbrt
  , ca_Root
  , ca_Floor
  , ca_Ceil
  , ca_Abs
  , ca_Sign
  , ca_Re
  , ca_Im
  , ca_Arg
  , ca_Conjugate
  , ca_Pi
  , ca_Sin
  , ca_Cos
  , ca_Exp
  , ca_Log
  , ca_Pow
  , ca_Tan
  , ca_Cot
  , ca_Cosh
  , ca_Sinh
  , ca_Tanh
  , ca_Coth
  , ca_Atan
  , ca_Acos
  , ca_Asin
  , ca_Acot
  , ca_Atanh
  , ca_Acosh
  , ca_Asinh
  , ca_Acoth
  , ca_Euler
  , ca_Gamma
  , ca_LogGamma
  , ca_Psi
  , ca_Erf
  , ca_Erfc
  , ca_Erfi
  , ca_RiemannZeta
  , ca_HurwitzZeta
  , ca_FUNC_CODE_LENGTH
) where

-- Calcium ---------------------------------------------------------------------

import Foreign.C.Types
import Foreign.C.String
import Foreign.ForeignPtr
import Foreign.Ptr
import Foreign.Storable
import Foreign.Marshal.Alloc (free)

import Data.Number.Flint.Fmpz
import Data.Number.Flint.Arb.Types
import Data.Number.Flint.Acb.Types




-- calcium_stream_t ------------------------------------------------------------

data CalciumStream = CalciumStream {-# UNPACK #-} !(ForeignPtr CCalciumStream)
data CCalciumStream = CCalciumStream (Ptr CFile) CString CLong CLong

instance Storable CCalciumStream where
  {-# INLINE sizeOf #-}
  sizeOf _ = (32)
{-# LINE 108 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
  {-# INLINE alignment #-}
  alignment _ = 8
{-# LINE 110 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
  peek ptr = CCalciumStream
    <$> (return $ castPtr ptr)
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 8) ptr
{-# LINE 113 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 16) ptr
{-# LINE 114 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
    <*> (\hsc_ptr -> peekByteOff hsc_ptr 24) ptr
{-# LINE 115 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
  poke ptr (CCalciumStream fp s len alloc) = do
    (\hsc_ptr -> pokeByteOff hsc_ptr 0) ptr fp
{-# LINE 117 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
    (\hsc_ptr -> pokeByteOff hsc_ptr 8) ptr s
{-# LINE 118 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
    (\hsc_ptr -> pokeByteOff hsc_ptr 16) ptr len
{-# LINE 119 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
    (\hsc_ptr -> pokeByteOff hsc_ptr 24) ptr alloc
{-# LINE 120 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}
    
newCalciumStreamFile fp = do
  p <- mallocForeignPtr
  withForeignPtr p $ \p -> do
    calcium_stream_init_file p fp
  return $ CalciumStream p

newCalciumStreamStr s = do
  p <- mallocForeignPtr
  withForeignPtr p $ \p -> do
    calcium_stream_init_str p
  return $ CalciumStream p
  
withCalciumStream (CalciumStream p) f = do
  withForeignPtr p $ \fp -> (CalciumStream p,) <$> f fp
  
-- Version ---------------------------------------------------------------------

-- | /calcium_version/ 
--
-- Returns a pointer to the version of the library as a string @X.Y.Z@.
foreign import ccall "calcium.h calcium_version"
  calcium_version :: IO CString

-- Triple-valued logic ---------------------------------------------------------

-- | Triple-valued logic
newtype CTruth = CTruth {_CTruth :: CULong} deriving Eq

t_true     :: CTruth
t_true     = CTruth 0
t_false    :: CTruth
t_false    = CTruth 1
t_unknown  :: CTruth
t_unknown  = CTruth 2

{-# LINE 154 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}

instance Show CTruth where
  show x
    | x == t_true    = "T_TRUE"
    | x == t_false   = "T_FALSE"
    | x == t_unknown = "T_UNKNOWN"
  
newtype CCalciumFunctionCode =
  CCalciumFunctionCode {_CCalciumFunctionCode :: CULong} deriving (Show, Eq)

ca_QQBar  :: CCalciumFunctionCode
ca_QQBar  = CCalciumFunctionCode 0
ca_Neg  :: CCalciumFunctionCode
ca_Neg  = CCalciumFunctionCode 1
ca_Add  :: CCalciumFunctionCode
ca_Add  = CCalciumFunctionCode 2
ca_Sub  :: CCalciumFunctionCode
ca_Sub  = CCalciumFunctionCode 3
ca_Mul  :: CCalciumFunctionCode
ca_Mul  = CCalciumFunctionCode 4
ca_Div  :: CCalciumFunctionCode
ca_Div  = CCalciumFunctionCode 5
ca_Sqrt  :: CCalciumFunctionCode
ca_Sqrt  = CCalciumFunctionCode 6
ca_Cbrt  :: CCalciumFunctionCode
ca_Cbrt  = CCalciumFunctionCode 7
ca_Root  :: CCalciumFunctionCode
ca_Root  = CCalciumFunctionCode 8
ca_Floor  :: CCalciumFunctionCode
ca_Floor  = CCalciumFunctionCode 9
ca_Ceil  :: CCalciumFunctionCode
ca_Ceil  = CCalciumFunctionCode 10
ca_Abs  :: CCalciumFunctionCode
ca_Abs  = CCalciumFunctionCode 11
ca_Sign  :: CCalciumFunctionCode
ca_Sign  = CCalciumFunctionCode 12
ca_Re  :: CCalciumFunctionCode
ca_Re  = CCalciumFunctionCode 13
ca_Im  :: CCalciumFunctionCode
ca_Im  = CCalciumFunctionCode 14
ca_Arg  :: CCalciumFunctionCode
ca_Arg  = CCalciumFunctionCode 15
ca_Conjugate  :: CCalciumFunctionCode
ca_Conjugate  = CCalciumFunctionCode 16
ca_Pi  :: CCalciumFunctionCode
ca_Pi  = CCalciumFunctionCode 17
ca_Sin  :: CCalciumFunctionCode
ca_Sin  = CCalciumFunctionCode 18
ca_Cos  :: CCalciumFunctionCode
ca_Cos  = CCalciumFunctionCode 19
ca_Exp  :: CCalciumFunctionCode
ca_Exp  = CCalciumFunctionCode 20
ca_Log  :: CCalciumFunctionCode
ca_Log  = CCalciumFunctionCode 21
ca_Pow  :: CCalciumFunctionCode
ca_Pow  = CCalciumFunctionCode 22
ca_Tan  :: CCalciumFunctionCode
ca_Tan  = CCalciumFunctionCode 23
ca_Cot  :: CCalciumFunctionCode
ca_Cot  = CCalciumFunctionCode 24
ca_Cosh  :: CCalciumFunctionCode
ca_Cosh  = CCalciumFunctionCode 25
ca_Sinh  :: CCalciumFunctionCode
ca_Sinh  = CCalciumFunctionCode 26
ca_Tanh  :: CCalciumFunctionCode
ca_Tanh  = CCalciumFunctionCode 27
ca_Coth  :: CCalciumFunctionCode
ca_Coth  = CCalciumFunctionCode 28
ca_Atan  :: CCalciumFunctionCode
ca_Atan  = CCalciumFunctionCode 29
ca_Acos  :: CCalciumFunctionCode
ca_Acos  = CCalciumFunctionCode 30
ca_Asin  :: CCalciumFunctionCode
ca_Asin  = CCalciumFunctionCode 31
ca_Acot  :: CCalciumFunctionCode
ca_Acot  = CCalciumFunctionCode 32
ca_Atanh  :: CCalciumFunctionCode
ca_Atanh  = CCalciumFunctionCode 33
ca_Acosh  :: CCalciumFunctionCode
ca_Acosh  = CCalciumFunctionCode 34
ca_Asinh  :: CCalciumFunctionCode
ca_Asinh  = CCalciumFunctionCode 35
ca_Acoth  :: CCalciumFunctionCode
ca_Acoth  = CCalciumFunctionCode 36
ca_Euler  :: CCalciumFunctionCode
ca_Euler  = CCalciumFunctionCode 37
ca_Gamma  :: CCalciumFunctionCode
ca_Gamma  = CCalciumFunctionCode 38
ca_LogGamma  :: CCalciumFunctionCode
ca_LogGamma  = CCalciumFunctionCode 39
ca_Psi  :: CCalciumFunctionCode
ca_Psi  = CCalciumFunctionCode 40
ca_Erf  :: CCalciumFunctionCode
ca_Erf  = CCalciumFunctionCode 41
ca_Erfc  :: CCalciumFunctionCode
ca_Erfc  = CCalciumFunctionCode 42
ca_Erfi  :: CCalciumFunctionCode
ca_Erfi  = CCalciumFunctionCode 43
ca_RiemannZeta  :: CCalciumFunctionCode
ca_RiemannZeta  = CCalciumFunctionCode 44
ca_HurwitzZeta  :: CCalciumFunctionCode
ca_HurwitzZeta  = CCalciumFunctionCode 45
ca_FUNC_CODE_LENGTH  :: CCalciumFunctionCode
ca_FUNC_CODE_LENGTH  = CCalciumFunctionCode 46

{-# LINE 213 "src/Data/Number/Flint/Calcium/FFI.hsc" #-}

-- Flint, Arb and Antic extras -------------------------------------------------

-- -- | /calcium_fmpz_hash/ /x/ 
--
-- -- Hash function for integers. The algorithm may change; presently, this
-- -- simply extracts the low word (with sign).
-- foreign import ccall "calcium.h calcium_fmpz_hash"
--   calcium_fmpz_hash :: Ptr CFmpz -> IO CULong

foreign import ccall "calcium.h calcium_stream_init_file"
  calcium_func_name :: CCalciumFunctionCode -> IO CString

-- Input and output ------------------------------------------------------------

-- | /calcium_stream_init_file/ /out/ /fp/ 
--
-- Initializes the stream /out/ for writing to the file /fp/. The file can
-- be /stdout/, /stderr/, or any file opened for writing by the user.
foreign import ccall "calcium.h calcium_stream_init_file"
  calcium_stream_init_file :: Ptr CCalciumStream -> Ptr CFile -> IO ()

-- | /calcium_stream_init_str/ /out/ 

-- Initializes the stream /out/ for writing to a string in memory. When
-- finished, the user should free the string (the /s/ member of /out/ with
-- @flint_free()@).
calcium_stream_init_str out = do
  cs <- newCString (replicate 16 '\0')
  poke out (CCalciumStream nullPtr cs 0 16)
  
-- | /calcium_write/ /out/ /s/ 
--
-- Writes the string /s/ to /out/.
foreign import ccall "calcium.h calcium_write"
  calcium_write :: Ptr CCalciumStream -> CString -> IO ()

-- | /calcium_write_free/ /out/ /s/ 
--
-- Writes /s/ to /out/ and then frees /s/ by calling @flint_free()@.
calcium_write_free :: Ptr CCalciumStream -> CString -> IO ()
calcium_write_free out s = do
  calcium_write out s
  free s
  
-- | /calcium_write_si/ /out/ /x/ 
foreign import ccall "calcium.h calcium_write_si"
  calcium_write_si :: Ptr CCalciumStream -> CLong -> IO ()
  
-- | /calcium_write_fmpz/ /out/ /x/ 
--
-- Writes the integer /x/ to /out/.
foreign import ccall "calcium.h calcium_write_fmpz"
  calcium_write_fmpz :: Ptr CCalciumStream
                     -> Ptr CFmpz -> IO ()

-- | /calcium_write_arb/ /out/ /z/ /digits/ /flags/ 
foreign import ccall "calcium.h calcium_write_arb"
  calcium_write_arb :: Ptr CCalciumStream
                    -> Ptr CArb -> CLong -> CULong -> IO ()
                    
-- | /calcium_write_acb/ /out/ /z/ /digits/ /flags/ 
--
-- Writes the Arb number /z/ to /out/, showing /digits/ digits and with the
-- display style specified by /flags/ (@ARB_STR_NO_RADIUS@, etc.).
foreign import ccall "calcium.h calcium_write_acb"
  calcium_write_acb :: Ptr CCalciumStream
  -> Ptr CAcb -> CLong -> CULong -> IO ()