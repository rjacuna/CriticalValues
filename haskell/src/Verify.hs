-- | The propositional fields of Lean's @Setup@, plus the conclusions, as
-- runtime checks over exact integer arithmetic.
--
-- This is @CriticalValues/Ledger.lean@ in program form.  Every entry is a
-- hypothesis the Lean proof assumes or a theorem it proves; if the program is
-- right, all of them hold for every input.
module Verify (Check(..), checks, checksX, allOk, report) where

import Data.Maybe (isJust)
import Poly
import Construct

data Check = Check { checkName :: String, checkOk :: Bool }

checks :: Setup -> [Check]
checks s =
  [ -- the fields of `structure Setup`
    Check "hρ    : ρ ≠ 0"                         (rho /= 0)
  , Check "hh₀   : h.coeff 0 = h₀"                (coeff h 0 == h0)
  , Check "hh₀0  : h₀ ≠ 0"                        (h0 /= 0)
  , Check "hn    : 1 ≤ deg h"                     (deg h >= 1)
  , Check "hfac  : f = h * f₁"                    (f == mul h f1)
  , Check "hbez  : u*h + v*h' = C ρ"              (add (mul u h) (mul v (derivative h)) == constP rho)
  , Check "hM    : M = ρ * h₀"                    (m == rho * h0)
  , Check "hH    : C h₀ * H = h(M·X)"             (mul (constP h0) bigH == scaleX m h)
  , Check "hH0   : H.coeff 0 = 1"                 (coeff bigH 0 == 1)
  , Check "hW    : C ρ * W = C v₀ * H − v(M·X)"   (mul (constP rho) w
                                                     == sub (mul (constP (coeff v 0)) bigH) (scaleX m v))
  , Check "hg    : g = M·X + h(M·X)*W"            (g == add (mul (constP m) xP) (mul (scaleX m h) w))
    -- §3, the two exact identities
  , Check "Lemma A : H ∣ ρ·g'"                    (isJust (exactDiv (mul (constP rho) (derivative g)) bigH))
  , Check "Lemma B : H² ∣ ρ·(f∘g)"                (isJust (exactDiv (mul (constP rho) (comp f g)) (mul bigH bigH)))
    -- §4, what the descent buys: the same divisibilities without ρ
  , Check "Cor C'  : H ∣ g'"                      (isJust (exactDiv (derivative g) bigH))
  , Check "Cor C'  : H² ∣ f∘g"                    (isJust (exactDiv (comp f g) (mul bigH bigH)))
    -- §5.2 and §5.3
  , Check "Lemma E : W ≠ 0"                       (not (isZero w))
  , Check "Lemma E : 1 ≤ deg W"                   (deg w >= 1)
  , Check "Lemma E : deg g = deg h + deg W"       (deg g == deg h + deg w)
  , Check "Lemma E : 2 ≤ deg g"                   (deg g >= 2)
  , Check "Lemma E : g' ≠ 0"                      (not (isZero (derivative g)))
  , Check "Lemma D : deg H = deg h"               (deg bigH == deg h)
  , Check "        : H is primitive"              (content bigH == 1)
  ]
  where
    f    = setF s;    h  = setH s;   f1 = setF1 s
    u    = setU s;    v  = setV s
    rho  = setRho s;  m  = setM s;   h0 = setH0 s
    bigH = setBigH s; w  = setW s;   g  = setG s

-- | The degenerate case, spec §6: when @X ∣ f@ the pair @g = X²@, @H = X@
-- settles Theorem 1 outright, and it is what serves the root @α = 0@.  There is
-- no `Setup` here — §2 needs @h(0) ≠ 0@ — so the conclusions are checked
-- directly.
checksX :: Poly -> [Check]
checksX f =
  [ Check "§6      : X ∣ f"                       (isJust (exactDiv f xP))
  , Check "Cor C'  : H ∣ g'"                      (isJust (exactDiv (derivative g) xP))
  , Check "Cor C'  : H² ∣ f∘g"                    (isJust (exactDiv (comp f g) (mul xP xP)))
  , Check "Lemma E : 2 ≤ deg g"                   (deg g >= 2)
  , Check "Lemma E : g' ≠ 0"                      (not (isZero (derivative g)))
  , Check "Lemma D : deg H = 1"                   (deg xP == 1)
  , Check "        : H is primitive"              (content xP == 1)
  ]
  where g = pow xP 2

allOk :: [Check] -> Bool
allOk = all checkOk

report :: [Check] -> String
report = unlines . map line
  where
    line c = (if checkOk c then "  ok   " else "  FAIL ") ++ checkName c
