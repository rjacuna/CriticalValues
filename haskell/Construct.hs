-- | The construction itself (spec §2), and Theorem 1.
--
-- 'Setup' is Lean's @structure Setup@ with the propositional fields erased —
-- which is what a record is.  Those fields are not lost: they come back in
-- "Verify" as runtime checks, so the program tests exactly the hypotheses the
-- proof assumes.
--
-- The four entry points correspond one-for-one to the Lean development:
--
-- @
--   setupFromBezout  ~  setup_of_factor, once (u, v, ρ) are fixed
--   setupOfFactor    ~  setup_of_factor
--   setupExists      ~  setup_exists
--   theorem1         ~  main_strong
-- @
module Construct
  ( Setup(..)
  , setupFromBezout, setupOfFactor, setupExists, theorem1
  ) where

import Poly
import Bezout (bezout)
import Factor (Strategy, chooseFactor)

data Setup = Setup
  { setF    :: Poly     -- ^ @f@, the input (Lean's index @Setup f@)
  , setH    :: Poly     -- ^ @h@, a factor of @f@ with @h(0) ≠ 0@
  , setF1   :: Poly     -- ^ @f₁@, the cofactor: @f = h * f₁@
  , setU    :: Poly     -- ^ @u@
  , setV    :: Poly     -- ^ @v@
  , setRho  :: Integer  -- ^ @ρ@, with @u h + v h' = C ρ@
  , setM    :: Integer  -- ^ @M = ρ h₀@
  , setH0   :: Integer  -- ^ @h₀ = h(0)@
  , setBigH :: Poly     -- ^ @H = h(M·X) / h₀@
  , setW    :: Poly     -- ^ @W = (v(0) H − v(M·X)) / ρ@
  , setG    :: Poly     -- ^ @g = M·X + h(M·X) · W@
  }

note :: String -> Maybe a -> Either String a
note msg = maybe (Left msg) Right

-- | The formulas of §2, given all the data.  The two 'divC' calls are exactly
-- the integrality of §2.1; they cannot fail when @M = ρ h₀@, and the program
-- reports it rather than silently rounding if they ever do.
setupFromBezout :: Poly -> Poly -> Poly -> Poly -> Poly -> Integer -> Either String Setup
setupFromBezout f h f1 u v rho
  | rho == 0   = Left "ρ = 0"
  | deg h < 1  = Left "deg h < 1"
  | h0 == 0    = Left "h(0) = 0"
  | otherwise = do
      bigH <- note "§2.1 failed: h₀ ∤ h(M·X)" (divC h0 (scaleX m h))
      w    <- note "§2.1 failed: ρ ∤ v(0)·H − v(M·X)"
                (divC rho (sub (mul (constP (coeff v 0)) bigH) (scaleX m v)))
      return Setup
        { setF = f, setH = h, setF1 = f1, setU = u, setV = v
        , setRho = rho, setM = m, setH0 = h0
        , setBigH = bigH, setW = w
        , setG = add (mul (constP m) xP) (mul (scaleX m h) w)
        }
  where
    h0 = coeff h 0
    m  = rho * h0

-- | Compute the Bézout data for a chosen factor, then apply the formulas.
setupOfFactor :: Poly -> Poly -> Either String Setup
setupOfFactor f h = do
  f1          <- note "h does not divide f" (exactDiv f h)
  (u, v, rho) <- note "gcd(h, h') is nonconstant: h is not squarefree" (bezout h)
  setupFromBezout f h f1 u v rho

setupExists :: Strategy -> Poly -> Either String Setup
setupExists strat f = do
  h <- note "f has no nonconstant factor with nonzero constant term"
         (chooseFactor strat f)
  setupOfFactor f h

-- | Theorem 1: for nonconstant @f@, a pair @(g, H)@ with @H ∣ g'@ and
-- @H² ∣ f ∘ g@.  The case split is on @X ∣ f@, which is @coeff f 0 == 0@ —
-- Lean's @X_dvd_iff@, and decidable.
theorem1 :: Strategy -> Poly -> Either String (Poly, Poly)
theorem1 strat f
  | deg f < 1      = Left "f must be nonconstant"
  | isZero f       = Left "f must be nonconstant"
  | coeff f 0 == 0 = Right (pow xP 2, xP)          -- §6, the degenerate case
  | otherwise      = do s <- setupExists strat f
                        return (setG s, setBigH s)
