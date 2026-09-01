{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_crit (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "crit"
version :: Version
version = Version [0,1,0,0] []

synopsis :: String
synopsis = "Critical values of integer polynomials \8212 the construction"
copyright :: String
copyright = ""
homepage :: String
homepage = ""
