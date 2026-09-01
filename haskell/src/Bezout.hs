-- | The Bézout step (spec §2) and the squarefree part.
--
-- This is the first of the two places the Lean development is not executable:
-- @exists_bezout@ proves the relation exists by coprimality in the PID ℚ[X]
-- plus @IsLocalization.integerNormalization@, both non-computable.  Here the
-- same two moves are carried out by extended Euclid and an explicit lcm.
module Bezout (bezout, squareFreePart) where

import Data.Ratio (denominator)
import Poly
import QPoly

-- | @bezout h = Just (u, v, ρ)@ with @u*h + v*h' = C ρ@ and @ρ ≠ 0@.
--
-- Returns 'Nothing' exactly when @gcd(h, h')@ is nonconstant, i.e. when @h@ is
-- not squarefree — which for irreducible @h@ in characteristic zero never
-- happens, and is precisely the hypothesis Lean discharges from @hirr@.
--
-- The final content reduction is licensed by spec §10 (\"any nonzero element of
-- @(h, h') ∩ ℤ@ works, and the smaller @ρ@ is, the smaller the output\"); it is
-- what returns @ρ = 2@ for @X² + 1@, where the resultant is @4@.
bezout :: Poly -> Maybe (Poly, Poly, Integer)
bezout h
  | deg h < 1 = Nothing
  | otherwise =
      case qExtGcd (toQP h) (toQP (derivative h)) of
        (g, a, b) | [c] <- g, c /= 0 ->
          let a' = map (/ c) a
              b' = map (/ c) b
              d  = foldr (lcm . denominator) 1 (a' ++ b')
              u  = clearDenoms (qScale (fromInteger d) a')
              v  = clearDenoms (qScale (fromInteger d) b')
              e  = gcd (gcd (content u) (content v)) d
          in do uu <- divC e u
                vv <- divC e v
                return (uu, vv, d `div` e)
        _ -> Nothing

-- | The primitive squarefree part, @primPart (h / gcd(h, h'))@.
squareFreePart :: Poly -> Poly
squareFreePart f
  | isZero f  = zero
  | deg f < 1 = f
  | otherwise =
      let fq = toQP f
          g  = qGcd fq (toQP (derivative f))
      in primPart (clearDenoms (fst (qDivMod fq g)))
