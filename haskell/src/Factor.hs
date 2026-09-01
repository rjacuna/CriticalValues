-- | Choosing the factor @h@ (spec §2).
--
-- This is the second place the Lean development is not executable: in
-- @setup_exists@ Lean calls @WfDvdMonoid.exists_irreducible_factor@, a pure
-- existence lemma.
--
-- The two strategies here reflect the Lean dependency structure exactly.
-- §3 (Lemmas A and B) and §4 (the descent) never use @hirr@ — they need only
-- that @h@ is primitive with @h(0) ≠ 0@, and that @gcd(h, h') = 1@ so the
-- Bézout data exists, which for a nonconstant @h@ in characteristic zero is
-- squarefreeness.  Irreducibility of @h@ is used in one place only, Lemma D,
-- to conclude that @H@ is irreducible.  So:
--
--   * 'SquareFree' is cheap and still gives @H ∣ g'@ and @H² ∣ f ∘ g@;
--   * 'Irreducible' additionally gives Theorem 1 as stated.
module Factor (Strategy(..), chooseFactor, irreducibleFactor) where

import Data.Maybe (listToMaybe, isJust, fromJust)
import Poly
import QPoly (qInterpolate, integralQP)
import Bezout (squareFreePart)

data Strategy = Irreducible | SquareFree deriving (Eq, Show)

-- | A factor of @f@ that is primitive, nonconstant, has nonzero constant term,
-- and (under 'Irreducible') is irreducible.
chooseFactor :: Strategy -> Poly -> Maybe Poly
chooseFactor strat f
  | deg s < 1 = Nothing
  | otherwise = Just h
  where
    s = stripX (squareFreePart f)
    h = case strat of
          SquareFree  -> s
          Irreducible -> irreducibleFactor s

-- | Divide out every factor of @X@, so the result has nonzero constant term.
-- This is the computational content of the case split in @main_strong@.
stripX :: Poly -> Poly
stripX p
  | isZero p        = p
  | coeff p 0 /= 0  = p
  | otherwise       = stripX (fromJust (exactDiv p xP))

-- | An irreducible factor, by Kronecker's method.
--
-- Elementary and correct, and exponential in the number of divisors of the
-- sampled values: this is the only super-polynomial step in the program, and
-- the one a serious implementation would replace with Zassenhaus or van Hoeij.
-- Input must be primitive and nonconstant.
irreducibleFactor :: Poly -> Poly
irreducibleFactor p
  | deg p <= 1 = p
  | otherwise  = maybe p irreducibleFactor (properFactor p)

-- | A factor of degree in @[1, deg p - 1]@, if one exists.
properFactor :: Poly -> Maybe Poly
properFactor p = listToMaybe
  [ cand
  | ys   <- sequence [ divisorsPM (evalP p x) | x <- pts ]
  , Just cand <- [integralQP (qInterpolate (zip (map fromInteger pts) (map fromInteger ys)))]
  , deg cand >= 1
  , deg cand < deg p
  , isJust (exactDiv p cand)
  ]
  where
    d   = deg p `div` 2
    pts = take (d + 1) [ x | x <- samplePoints, evalP p x /= 0 ]

samplePoints :: [Integer]
samplePoints = 0 : concat [ [n, negate n] | n <- [1 ..] ]

-- | All divisors of @n@, positive and negative.  @n@ is never zero here, since
-- the sample points avoid the roots of @p@.
divisorsPM :: Integer -> [Integer]
divisorsPM n = concat [ [d, negate d] | d <- [1 .. abs n], abs n `mod` d == 0 ]
