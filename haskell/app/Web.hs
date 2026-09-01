{-# LANGUAGE ForeignFunctionInterface #-}

-- | The wasm reactor entry point.
--
-- Deliberately thin. The orchestrator (JavaScript) does the factoring — with
-- wasm-FLINT if it is loaded — and hands the chosen factor @h@ in; this module
-- runs the construction and the checks and hands back the result. That keeps
-- every Haskell function on the verified path pure and synchronous: no async
-- JSFFI import, so no @IO@ leaking into @setupOfFactor@ and upward.
--
-- @setupOfFactor@ already takes @h@ as a parameter, because it mirrors Lean's
-- @setup_of_factor@. The split built to follow the proof is the delegation
-- seam.
--
-- Wire format. In: @"c0,c1,...|d0,d1,..."@, the coefficients of @f@ and then of
-- @h@, low to high, as decimal integers; the @h@ half may be empty, in which
-- case the Haskell picks a factor itself. Out: JSON.
--
-- Coefficients are decimal strings on both sides, never JavaScript numbers.
-- @g@'s coefficients routinely exceed 2^53 — see the 460-digit case in
-- OPTIMIZATION.md — so a numeric boundary would round silently and corrupt the
-- checks along with the answer.
module Web (solve) where

import Data.List (intercalate)
import GHC.Wasm.Prim
import Poly
import Factor (Strategy(..))
import Construct
import Verify

foreign export javascript "solve" solve :: JSString -> IO JSString

solve :: JSString -> IO JSString
solve = pure . toJSString . run . fromJSString

-- | Split on the single @'|'@, then on commas.
parseInput :: String -> (Poly, Maybe Poly)
parseInput s = (readPoly a, if null (dropWhile (== ' ') b') then Nothing else Just (readPoly b'))
  where
    (a, b) = break (== '|') s
    b'     = drop 1 b

readPoly :: String -> Poly
readPoly = poly . map read . filter (not . null) . splitOn ','

splitOn :: Char -> String -> [String]
splitOn c s = case break (== c) s of
  (w, [])      -> [trim w]
  (w, _ : r)   -> trim w : splitOn c r
  where trim = dropWhile (== ' ')

run :: String -> String
run input =
  case parseInput input of
    (f, _) | isZero f || deg f < 1 -> err "f must be nonconstant"
    (f, mh)
      | coeff f 0 == 0 -> degenerate f
      | otherwise ->
          case maybe (setupExists Irreducible f) (setupOfFactor f) mh of
            Left e  -> err e
            Right s -> ok s

-- | §6. @X ∣ f@ needs no construction at all.
degenerate :: Poly -> String
degenerate _ = obj
  [ ("ok", "true"), ("degenerate", "true")
  , ("g", jarr (pcoeffs (pow xP 2))), ("H", jarr (pcoeffs xP))
  , ("checks", "[]") ]

ok :: Setup -> String
ok s = obj
  [ ("ok",     "true")
  , ("degenerate", "false")
  , ("h",      jarr (pcoeffs (setH s)))
  , ("u",      jarr (pcoeffs (setU s)))
  , ("v",      jarr (pcoeffs (setV s)))
  , ("rho",    jstr (show (setRho s)))
  , ("M",      jstr (show (setM s)))
  , ("h0",     jstr (show (setH0 s)))
  , ("H",      jarr (pcoeffs (setBigH s)))
  , ("W",      jarr (pcoeffs (setW s)))
  , ("g",      jarr (pcoeffs (setG s)))
  , ("degG",   jstr (show (deg (setG s))))
  , ("digitsG", jstr (show (digitsOf (setG s))))
  , ("checks", jchecks (checks s))
  ]

digitsOf :: Poly -> Int
digitsOf p | isZero p  = 1
           | otherwise = length (show (maximum (map abs (coeffs p))))

err :: String -> String
err m = obj [("ok", "false"), ("error", jstr m)]

-- minimal JSON output; every value we emit is digits, ASCII or the check names
pcoeffs :: Poly -> [String]
pcoeffs p = map show (coeffs p)

jstr :: String -> String
jstr t = "\"" ++ concatMap esc t ++ "\""
  where esc '"'  = "\\\""
        esc '\\' = "\\\\"
        esc c    = [c]

jarr :: [String] -> String
jarr xs = "[" ++ intercalate "," (map jstr xs) ++ "]"

obj :: [(String, String)] -> String
obj kvs = "{" ++ intercalate "," [jstr k ++ ":" ++ v | (k, v) <- kvs] ++ "}"

jchecks :: [Check] -> String
jchecks cs = "[" ++ intercalate ","
  [ obj [("name", jstr (checkName c)), ("ok", if checkOk c then "true" else "false")]
  | c <- cs ] ++ "]"
