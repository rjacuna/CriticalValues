-- | All complex roots of an integer polynomial, by the Aberth–Ehrlich method.
--
-- In Haskell rather than JavaScript on purpose: the compile target is
-- JavaScript, so anything mathematical belongs here and gets compiled. The
-- browser is only ever handed a rendered answer.
--
-- Aberth–Ehrlich over Durand–Kerner (cubic rather than quadratic convergence)
-- and over companion-matrix eigenvalues (no matrix, and a small componentwise
-- backward error: each computed root is an exact root of a nearby polynomial).
-- It is the iteration MPSolve uses.
module Roots (roots, showComplex) where

import Data.Bits (shiftR)
import Data.Complex
import Data.List (sortBy)
import Data.Ord (comparing)
import Poly

-- | Coefficients to `Double`, scaled so nothing overflows. Dividing every
-- coefficient by a common factor does not move the roots.
toDoubles :: Poly -> [Double]
toDoubles p = map (\c -> fromInteger (c `shiftR` sh)) cs
  where
    cs   = coeffs p
    bits = maximum (1 : map (bitLen . abs) cs)
    sh   = max 0 (bits - 900)          -- comfortably inside 1e308
    bitLen 0 = 0
    bitLen n = 1 + bitLen (n `div` 2)

-- | Horner, in ℂ.
evalC :: [Double] -> Complex Double -> Complex Double
evalC as z = foldr (\a acc -> acc * z + (a :+ 0)) 0 as

-- | Every root, with multiplicity, to full `Double` precision.
roots :: Poly -> [Complex Double]
roots p
  | n < 1     = []
  | otherwise = sortBy (comparing realPart <> comparing imagPart)
              . map tidy $ go (0 :: Int) start
  where
    as0 = dropTrailing (toDoubles p)
    n   = length as0 - 1
    an  = last as0
    mon = map (/ an) as0                       -- monic
    da  = zipWith (\a i -> a * fromIntegral i) (drop 1 mon) [1 :: Int ..]

    dropTrailing = reverse . dropWhile (== 0) . reverse

    -- Cauchy bound; guesses on a circle, offset to break symmetry
    r0    = 1 + maximum (0 : map abs (init mon))
    start = [ mkPolar (0.5 * r0) (2 * pi * fromIntegral k / fromIntegral n + 0.4)
            | k <- [0 .. n - 1] ]

    go it zs
      | it >= 500 || worst < 1e-14 * (1 + r0) = zs'
      | otherwise                             = go (it + 1) zs'
      where
        zs'   = zipWith step zs [0 ..]
        worst = maximum (0 : zipWith (\a b -> magnitude (a - b)) zs zs')
        step z i
          | magnitude dv == 0 = z
          | otherwise         = z - off
          where
            pv  = evalC mon z
            dv  = evalC da z
            w   = pv / dv                                   -- Newton correction
            s   = sum [ 1 / (z - zj)
                      | (j, zj) <- zip [0 :: Int ..] zs, j /= i, magnitude (z - zj) > 0 ]
            den = 1 - w * s
            off = if magnitude den == 0 then w else w / den

    -- snap both parts: a root that is really real should not display a
    -- 10^-17 imaginary part, and vice versa
    tidy z = snapRe (snapIm z)
      where
        eps = 1e-10 * (1 + r0)
        snapIm w = if abs (imagPart w) < eps then realPart w :+ 0 else w
        snapRe w = if abs (realPart w) < eps then 0 :+ imagPart w else w

-- | LaTeX for a complex number at the given number of significant digits.
showComplex :: Int -> Complex Double -> String
showComplex sig z
  | im == 0   = sigFig sig re
  | re == 0   = imOnly
  | otherwise = sigFig sig re ++ (if im < 0 then " - " else " + ") ++ imMag ++ "i"
  where
    re = realPart z
    im = imagPart z
    imMag  = let t = sigFig sig (abs im) in if t == "1" then "" else t
    imOnly = (if im < 0 then "-" else "") ++ imMag ++ "i"

-- | @sig@ significant digits, without Haskell's @show@ (which renders 0.01 as
-- @1.0e-2@). Built from the digit string so the mantissa cannot pick up
-- floating error on the way out.
sigFig :: Int -> Double -> String
sigFig sig x
  | x == 0 || isNaN x || isInfinite x = "0"
  | otherwise = (if x < 0 then "-" else "") ++ render digits e
  where
    ax = abs x
    e0 = floor (logBase 10 ax) :: Int
    d0 = round (ax / 10 ^^ (e0 - sig + 1)) :: Integer
    (digits, e) | length (show d0) > sig = (d0 `div` 10, e0 + 1)
                | otherwise              = (d0, e0)

    render ds ex
      | ex >= sig = trimZeros (dsStr ++ replicate (ex - sig + 1) '0')
      | ex >= 0   = let (i, f) = splitAt (ex + 1) dsStr in dot (trimZeros i) (trimTrail f)
      | ex >= -5  = dot "0" (trimTrail (replicate (negate ex - 1) '0' ++ dsStr))
      | otherwise = let (i, f) = splitAt 1 dsStr
                    in dot i (trimTrail f) ++ " \\times 10^{" ++ show ex ++ "}"
      where dsStr = show ds

    dot i "" = i
    dot i f  = i ++ "." ++ f
    trimTrail = reverse . dropWhile (== '0') . reverse
    trimZeros t = if null t then "0" else t
