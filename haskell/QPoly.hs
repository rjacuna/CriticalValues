-- | Polynomials over ℚ, used only as scratch space.
--
-- Two steps of the construction are stated over ℚ in the spec and in the Lean
-- development: the Bézout relation (§2, via coprimality in the PID ℚ[X]) and
-- Lagrange interpolation inside Kronecker's factoring method.  Both clear
-- denominators before returning, so nothing rational escapes this module.
module QPoly
  ( QP
  , qnorm, qIsZero, qDeg, qAdd, qSub, qMul, qScale
  , qDivMod, qGcd, qExtGcd, qInterpolate
  , toQP, clearDenoms, integralQP
  ) where

import Data.Ratio (numerator, denominator)
import Poly (Poly, poly, coeffs)

-- | Little-endian, no trailing zeros.
type QP = [Rational]

qnorm :: QP -> QP
qnorm = reverse . dropWhile (== 0) . reverse

qIsZero :: QP -> Bool
qIsZero = null . qnorm

-- | @-1@ for the zero polynomial (unlike "Poly", which follows @natDegree@).
qDeg :: QP -> Int
qDeg q = length (qnorm q) - 1

pad :: Int -> QP -> QP
pad n a = a ++ replicate (n - length a) 0

qAdd, qSub :: QP -> QP -> QP
qAdd a b = qnorm (zipWith (+) (pad n a) (pad n b)) where n = max (length a) (length b)
qSub a b = qnorm (zipWith (-) (pad n a) (pad n b)) where n = max (length a) (length b)

qMul :: QP -> QP -> QP
qMul a b
  | qIsZero a || qIsZero b = []
  | otherwise =
      qnorm [ sum [ (a !! i) * (b !! (k - i))
                  | i <- [max 0 (k - length b + 1) .. min k (length a - 1)] ]
            | k <- [0 .. length a + length b - 2] ]

qScale :: Rational -> QP -> QP
qScale c = qnorm . map (c *)

-- | Division with remainder.  Precondition: the divisor is nonzero.
qDivMod :: QP -> QP -> (QP, QP)
qDivMod p d
  | qIsZero d = error "QPoly.qDivMod: zero divisor"
  | otherwise = go (qnorm p) []
  where
    d'  = qnorm d
    dd  = length d' - 1
    ld  = last d'
    go r acc
      | qIsZero r || qDeg r < dd = (foldr qAdd [] acc, qnorm r)
      | otherwise =
          let r' = qnorm r
              k  = length r' - 1 - dd
              c  = last r' / ld
              t  = replicate k 0 ++ [c]
          in go (qSub r' (qMul d' t)) (t : acc)

-- | The monic gcd.
qGcd :: QP -> QP -> QP
qGcd p q
  | qIsZero q = qMonic p
  | otherwise = qGcd q (snd (qDivMod p q))
  where
    qMonic r | qIsZero r = []
             | otherwise = qScale (recip (last (qnorm r))) (qnorm r)

-- | Extended Euclid: @qExtGcd p q = (g, a, b)@ with @a*p + b*q = g@.
qExtGcd :: QP -> QP -> (QP, QP, QP)
qExtGcd p q
  | qIsZero q = (qnorm p, [1], [])
  | otherwise =
      let (d, r)    = qDivMod p q
          (g, a, b) = qExtGcd q r
      in (g, b, qSub a (qMul d b))

-- | Lagrange interpolation through the given points (distinct abscissae).
qInterpolate :: [(Rational, Rational)] -> QP
qInterpolate pts = foldr qAdd [] (map term [0 .. length pts - 1])
  where
    xs = map fst pts
    ys = map snd pts
    term i =
      let xi     = xs !! i
          others = [ x | (j, x) <- zip [(0 :: Int) ..] xs, j /= i ]
          num    = foldr qMul [1] [ [negate x, 1] | x <- others ]
          den    = product [ xi - x | x <- others ]
      in qScale ((ys !! i) / den) num

toQP :: Poly -> QP
toQP = map fromInteger . coeffs

-- | Multiply through by the lcm of the denominators.
clearDenoms :: QP -> Poly
clearDenoms q = poly [ numerator (r * fromInteger d) | r <- q ]
  where d = foldr (lcm . denominator) 1 q

-- | @Just@ the integral polynomial, when every coefficient is an integer.
integralQP :: QP -> Maybe Poly
integralQP q
  | all ((== 1) . denominator) q = Just (poly (map numerator q))
  | otherwise                    = Nothing
