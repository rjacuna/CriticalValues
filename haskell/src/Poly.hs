-- | Dense integer polynomials.
--
-- The representation mirrors Lean's @Polynomial.coeff@ indexing: coefficients
-- are stored little-endian, so @coeff p j@ is the @j@-th list element, and
-- @deg@ is @natDegree@ (the zero polynomial has degree @0@).
--
-- Everything here is exact.  Rationals appear in this program only inside
-- "QPoly", and only for the Bézout step; no rational ever reaches the output.
module Poly
  ( Poly
  , poly, coeffs, coeff, deg, leading, isZero
  , zero, one, xP, constP, monomial
  , add, sub, neg, mul, pow, evalP
  , derivative, comp, scaleX
  , content, primPart, exactDiv, divC
  , pretty
  ) where

import Data.List (dropWhileEnd)

-- | Invariant: no trailing zeros, so @(==)@ is mathematical equality.
newtype Poly = P [Integer] deriving (Eq)

instance Show Poly where
  show = pretty

-- | The only constructor: normalizes away trailing zeros.
poly :: [Integer] -> Poly
poly = P . dropWhileEnd (== 0)

coeffs :: Poly -> [Integer]
coeffs (P cs) = cs

coeff :: Poly -> Int -> Integer
coeff (P cs) j
  | j < 0 || j >= length cs = 0
  | otherwise               = cs !! j

-- | @natDegree@: zero has degree @0@, as in Lean.
deg :: Poly -> Int
deg (P []) = 0
deg (P cs) = length cs - 1

leading :: Poly -> Integer
leading (P []) = 0
leading (P cs) = last cs

isZero :: Poly -> Bool
isZero (P cs) = null cs

zero, one, xP :: Poly
zero = P []
one  = P [1]
xP   = P [0, 1]

-- | @C a@.
constP :: Integer -> Poly
constP a = poly [a]

-- | @monomial n a@.
monomial :: Int -> Integer -> Poly
monomial n a = poly (replicate n 0 ++ [a])

zipLong :: (Integer -> Integer -> Integer) -> [Integer] -> [Integer] -> [Integer]
zipLong f as bs = take n (zipWith f (as ++ repeat 0) (bs ++ repeat 0))
  where n = max (length as) (length bs)

add, sub, mul :: Poly -> Poly -> Poly
add (P as) (P bs) = poly (zipLong (+) as bs)
sub (P as) (P bs) = poly (zipLong (-) as bs)
mul (P []) _ = zero
mul _ (P []) = zero
mul (P as) (P bs) =
  poly [ sum [ (as !! i) * (bs !! (k - i))
             | i <- [max 0 (k - length bs + 1) .. min k (length as - 1)] ]
       | k <- [0 .. length as + length bs - 2] ]

neg :: Poly -> Poly
neg (P as) = P (map negate as)

pow :: Poly -> Int -> Poly
pow _ 0 = one
pow p n = mul p (pow p (n - 1))

-- | Evaluation at an integer, by Horner.
evalP :: Poly -> Integer -> Integer
evalP (P cs) x = foldr (\c acc -> c + x * acc) 0 cs

derivative :: Poly -> Poly
derivative (P cs) = poly (zipWith (*) [1 ..] (drop 1 cs))

-- | @p.comp q@, by Horner.
comp :: Poly -> Poly -> Poly
comp (P cs) q = foldr (\c acc -> add (constP c) (mul q acc)) zero cs

-- | @scale M p = p(M·X)@.
--
-- This is Lean's @coeff_scale@ read as a definition: the @j@-th coefficient is
-- multiplied by @M^j@.  In Lean @scale@ is @Polynomial.compRingHom (C M * X)@
-- and @coeff_scale@ is a theorem; here the theorem is the implementation.
scaleX :: Integer -> Poly -> Poly
scaleX m (P cs) = poly (zipWith (\j c -> c * m ^ j) [(0 :: Int) ..] cs)

-- | The (non-negative) gcd of the coefficients.  @content 0 = 0@.
content :: Poly -> Integer
content (P cs) = foldr (\c acc -> gcd (abs c) acc) 0 cs

-- | @p / C (content p)@, matching Mathlib: the sign of @p@ is preserved.
primPart :: Poly -> Poly
primPart p
  | isZero p  = zero
  | otherwise = maybe p id (divC (content p) p)

-- | Exact division by a constant: @divC c p = Just q@ iff @p = C c * q@.
divC :: Integer -> Poly -> Maybe Poly
divC 0 _ = Nothing
divC c (P as)
  | all (\a -> a `mod` c == 0) as = Just (poly (map (`div` c) as))
  | otherwise                     = Nothing

-- | Exact division: @exactDiv p q = Just r@ iff @p = q * r@.
--
-- Used both to compute cofactors and, in "Verify", to test the divisibility
-- conclusions of Theorem 1 without ever forming a quotient field.
exactDiv :: Poly -> Poly -> Maybe Poly
exactDiv p q
  | isZero q                        = Nothing
  | isZero p                        = Just zero
  | deg p < deg q                   = Nothing
  | leading p `mod` leading q /= 0  = Nothing
  | otherwise =
      let t = monomial (deg p - deg q) (leading p `div` leading q)
      in fmap (add t) (exactDiv (sub p (mul q t)) q)

pretty :: Poly -> String
pretty p
  | isZero p  = "0"
  | otherwise = go True (reverse [ t | t@(_, c) <- zip [(0 :: Int) ..] (coeffs p), c /= 0 ])
  where
    go _ [] = ""
    go first ((j, c) : rest) = sgn ++ body ++ go False rest
      where
        sgn | c < 0     = if first then "-" else " - "
            | otherwise = if first then ""  else " + "
        a = abs c
        body
          | j == 0            = show a
          | a == 1, j == 1    = "X"
          | a == 1            = "X^" ++ show j
          | j == 1            = show a ++ "X"
          | otherwise         = show a ++ "X^" ++ show j
