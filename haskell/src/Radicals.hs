-- | Closed-form radical expressions for roots of degree ≤ 4.
--
-- Cardano for the cubic, Ferrari for the quartic, in the standard presentation:
-- the auxiliary quantities Δ₀, Δ₁, Q, S are computed *exactly* from the integer
-- coefficients and substituted in. Expanding a general quartic into one nested
-- radical is unreadable and no more informative.
--
-- Each branch carries its numeric value, so the caller can match the expression
-- to whichever root the user picked rather than guessing at branch order.
module Radicals (radicals, Branch(..)) where

import Data.Complex
import Poly

data Branch = Branch { brLatex :: String, brValue :: Complex Double }

d2c :: Integer -> Complex Double
d2c n = fromInteger n :+ 0

-- principal square root
csqrt :: Complex Double -> Complex Double
csqrt z = mkPolar (sqrt (magnitude z)) (phase z / 2)

-- k-th cube root
ccbrt :: Int -> Complex Double -> Complex Double
ccbrt k z
  | magnitude z == 0 = 0
  | otherwise = mkPolar (magnitude z ** (1 / 3))
                        ((phase z + 2 * pi * fromIntegral k) / 3)

zeta :: Int -> Complex Double
zeta k = mkPolar 1 (2 * pi * fromIntegral k / 3)

-- | Render an exact rational a/b, reduced.
frac :: Integer -> Integer -> String
frac a b
  | b < 0            = frac (-a) (-b)
  | r == 0           = show (a `div` g)
  | otherwise        = "\\tfrac{" ++ show (a `div` g) ++ "}{" ++ show (b `div` g) ++ "}"
  where g = gcd (abs a) (abs b); r = a `mod` b

-- | Radical expressions for every root, or `Nothing` above degree 4.
radicals :: Poly -> Maybe [Branch]
radicals p = case reverse (coeffs p) of        -- highest degree first
  [a, b]          -> Just (deg1 a b)
  [a, b, c]       -> Just (deg2 a b c)
  [a, b, c, d]    -> Just (deg3 a b c d)
  [a, b, c, d, e] -> Just (deg4 a b c d e)
  _               -> Nothing

deg1 :: Integer -> Integer -> [Branch]
deg1 a b = [Branch ("x = " ++ frac (-b) a) (d2c (-b) / d2c a)]

deg2 :: Integer -> Integer -> Integer -> [Branch]
deg2 a b c =
  [ Branch (tex s) (val s) | s <- [1, -1 :: Integer] ]
  where
    disc = b * b - 4 * a * c
    sq   = csqrt (d2c disc)
    tex s = "x = \\frac{" ++ show (-b) ++ (if s > 0 then " + " else " - ")
            ++ "\\sqrt{" ++ show disc ++ "}}{" ++ show (2 * a) ++ "}"
    val s = (d2c (-b) + fromInteger s * sq) / d2c (2 * a)

deg3 :: Integer -> Integer -> Integer -> Integer -> [Branch]
deg3 a b c d
  | d0 == 0 && d1 == 0 =
      [Branch ("x = " ++ frac (-b) (3 * a)) (d2c (-b) / d2c (3 * a))]
  | otherwise = [ Branch (tex k) (val k) | k <- [0, 1, 2] ]
  where
    d0 = b * b - 3 * a * c
    d1 = 2 * b ^ (3 :: Int) - 9 * a * b * c + 27 * a * a * d
    inner = csqrt (d2c (d1 * d1 - 4 * d0 ^ (3 :: Int)))
    -- pick the cube-root branch that does not vanish
    cc k = let u = ccbrt k ((d2c d1 + inner) / 2)
           in if magnitude u > 1e-12 then u else ccbrt k ((d2c d1 - inner) / 2)
    val k = let cK = zeta k * cc 0
            in negate (d2c b + cK + d2c d0 / cK) / d2c (3 * a)
    tex k = unlines $
      [ "\\begin{aligned}"
      , "\\Delta_0 &= " ++ show d0 ++ ", \\qquad \\Delta_1 = " ++ show d1 ++ " \\\\" ]
      ++ [ "\\zeta &= \\tfrac{-1 + \\sqrt{-3}}{2}"
           ++ " \\quad (\\zeta^3 = 1) \\\\" | k /= 0 ] ++
      [ "C &= \\sqrt[3]{\\tfrac{1}{2}\\left(" ++ show d1
        ++ " + \\sqrt{" ++ show (d1 * d1 - 4 * d0 ^ (3 :: Int)) ++ "}\\right)} \\\\"
      , "x &= -\\frac{1}{" ++ show (3 * a) ++ "}\\left(" ++ show b ++ " + "
        ++ zetaTex k ++ "C + \\frac{" ++ show d0 ++ "}{" ++ zetaTex k ++ "C}\\right)"
      , "\\end{aligned}" ]
    zetaTex 0 = ""
    zetaTex k = "\\zeta^{" ++ show (k :: Int) ++ "}"

deg4 :: Integer -> Integer -> Integer -> Integer -> Integer -> [Branch]
deg4 a b c d e = [ Branch (tex s t) (val s t) | (s, t) <- [(1,1),(1,-1),(-1,1),(-1,-1)] ]
  where
    d0 = c * c - 3 * b * d + 12 * a * e
    d1 = 2 * c ^ (3 :: Int) - 9 * b * c * d + 27 * b * b * e + 27 * a * d * d
         - 72 * a * c * e
    pn = 8 * a * c - 3 * b * b        ; pd = 8 * a * a      -- p = pn/pd
    qn = b ^ (3 :: Int) - 4 * a * b * c + 8 * a * a * d ; qd = 8 * a ^ (3 :: Int)
    pC = d2c pn / d2c pd
    qC = d2c qn / d2c qd
    inner = csqrt (d2c (d1 * d1 - 4 * d0 ^ (3 :: Int)))
    qq = case [ u | k <- [0, 1, 2]
              , let u = ccbrt k ((d2c d1 + inner) / 2), magnitude u > 1e-12 ] of
           (u : _) -> u
           []      -> ccbrt 0 ((d2c d1 - inner) / 2)
    ss = 0.5 * csqrt (negate (2 / 3) * pC + (qq + d2c d0 / qq) / d2c (3 * a))
    val s t =
      let base = negate (d2c b) / d2c (4 * a)
          sT   = fromInteger s * ss
          rad  = csqrt (negate (4 * ss * ss) - 2 * pC
                        + fromInteger s * qC / (if magnitude ss == 0 then 1 else ss))
      in base + sT + fromInteger t * 0.5 * rad
    tex s t = unlines
      [ "\\begin{aligned}"
      , "p &= " ++ frac pn pd ++ ", \\qquad q = " ++ frac qn qd ++ " \\\\"
      , "\\Delta_0 &= " ++ show d0 ++ ", \\qquad \\Delta_1 = " ++ show d1 ++ " \\\\"
      , "Q &= \\sqrt[3]{\\tfrac{1}{2}\\left(" ++ show d1 ++ " + \\sqrt{"
        ++ show (d1 * d1 - 4 * d0 ^ (3 :: Int)) ++ "}\\right)} \\\\"
      , "S &= \\tfrac{1}{2}\\sqrt{-\\tfrac{2}{3}p + \\tfrac{1}{" ++ show (3 * a)
        ++ "}\\left(Q + \\tfrac{" ++ show d0 ++ "}{Q}\\right)} \\\\"
      , "x &= " ++ frac (-b) (4 * a) ++ sgn s ++ "S "
        ++ sgn t ++ "\\tfrac{1}{2}\\sqrt{-4S^2 - 2p " ++ sgn s ++ "\\tfrac{q}{S}}"
      , "\\end{aligned}" ]
    sgn n = if n > (0 :: Integer) then " + " else " - "
