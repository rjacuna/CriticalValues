-- | The pure request handler: wire string in, JSON out.
--
-- Deliberately separate from any front end. Three things call it and none of
-- them contain any mathematics:
--
--   * @app\/Web.hs@      — the wasm reactor export (the SPA);
--   * @app\/CritJson.hs@ — a native binary (the dev server shells out to it);
--   * the test drivers.
--
-- Swapping the browser from server-backed to wasm changes which of the first
-- two runs. It does not change a line of this module, which is the point.
--
-- Wire format. In: @"c0,c1,...|d0,d1,..."@, the coefficients of @f@ and then of
-- @h@, low to high, as decimal integers; the @h@ half may be empty, in which
-- case the squarefree part is used and no factoring happens. Out: JSON.
--
-- Coefficients are decimal strings on both sides, never JavaScript numbers.
-- @g@'s coefficients routinely exceed 2^53, so a numeric boundary would round
-- silently and corrupt the checks along with the answer.
module WebCore (run) where

import Data.Complex (Complex(..), magnitude)
import Data.List (intercalate, minimumBy)
import Data.Ord (comparing)
import Poly
import Expr (evalExpr)
import Factor (Strategy(..))
import Construct
import Verify
import Roots
import Radicals

-- | Split on the single @'|'@, then on commas.
parseInput :: String -> Either String (Poly, [Poly])
parseInput s = do
  f <- readF a
  let hs = [ readPoly t | t <- splitOn ';' b', not (null (dropWhile (== ' ') t)) ]
  Right (f, hs)
  where
    (a, b) = break (== '|') s
    b'     = drop 1 b
    -- An s-expression (always parenthesised) is an expression from the front
    -- end's parser; anything else is a plain coefficient list.
    readF t = case dropWhile (== ' ') t of
      t'@('(' : _) -> evalExpr t'
      t'           -> Right (readPoly t')

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
    Left e -> err e
    Right (f, _) | isZero f || deg f < 1 -> err "f must be nonconstant"
    Right (f, hs)
      | coeff f 0 == 0 -> degenerate f
      | otherwise      -> build f hs

-- | One `Setup` per usable factor.
--
--   * factors supplied — they came from a factoriser, so each `H` really is
--     irreducible and a *different* `g` serves each factor of a reducible `f`;
--   * none supplied — fall back to the squarefree part. Still correct: §3 and
--     §4 never use irreducibility, so both divisibilities hold and one `g`
--     covers every root. But `H` is then only irreducible when `f` is, which
--     the output says out loud rather than leaving implied.
build :: Poly -> [Poly] -> String
build f hs =
  case setups of
    [] -> err "f has no usable factor with nonzero constant term"
    ss -> ok f (if null usable then "squarefree" else "factored") ss
  where
    usable  = [ h | h <- hs, deg h >= 1, coeff h 0 /= 0 ]
    chosen  = if null usable then either (const []) (: []) (fmap setH (setupExists SquareFree f))
                             else usable
    setups  = [ s | h <- chosen, Right s <- [setupOfFactor f h] ]

-- | §6. @X ∣ f@ needs no construction at all.
degenerate :: Poly -> String
degenerate _ = obj
  [ ("ok", "true"), ("degenerate", "true")
  , ("g", jarr (pcoeffs (pow xP 2))), ("H", jarr (pcoeffs xP))
  , ("checks", "[]") ]

-- | The whole answer: one entry in @setups@ per factor, and every root tagged
-- with the setup that serves it.
ok :: Poly -> String -> [Setup] -> String
ok f src ss = obj
  [ ("ok",          "true")
  , ("degenerate",  "false")
  , ("f",           jarr (pcoeffs f))
  , ("hSource",     jstr src)
  , ("hIrreducible", if src == "factored" then "true" else "false")
  , ("setups",      "[" ++ intercalate "," (map jsetup ss) ++ "]")
  , ("roots",       jroots f ss)
  ]

jsetup :: Setup -> String
jsetup s = obj
  [ ("h",       jarr (pcoeffs (setH s)))
  , ("u",       jarr (pcoeffs (setU s)))
  , ("v",       jarr (pcoeffs (setV s)))
  , ("rho",     jstr (show (setRho s)))
  , ("M",       jstr (show (setM s)))
  , ("h0",      jstr (show (setH0 s)))
  , ("H",       jarr (pcoeffs (setBigH s)))
  , ("W",       jarr (pcoeffs (setW s)))
  , ("g",       jarr (pcoeffs (setG s)))
  , ("degG",    jstr (show (deg (setG s))))
  , ("digitsG", jstr (show (digitsOf (setG s))))
  , ("checks",  jchecks (checks s))
  ]

-- | Every root of @f@, matched to the setup whose @h@ vanishes there — so a
-- reducible @f@ gets a different @g@ per factor, and @β = α/M@ uses that
-- factor's own @M@. The match is numeric because the roots are; the winner
-- beats the others by orders of magnitude in practice.
jroots :: Poly -> [Setup] -> String
jroots f ss = "[" ++ intercalate "," (map one (roots f)) ++ "]"
  where
    brs = radicals f
    one a = obj
      [ ("alpha", jstr (showComplex 7 a))
      , ("beta",  jstr (showComplex 7 (a / (mOf a :+ 0))))
      , ("setup", jstr (show (idxOf a)))
      , ("rad",   maybe "null" (jstr . brLatex . nearest a) brs)
      ]
    idxOf a = snd (minimumBy (comparing fst)
                [ (magnitude (evalC (setH s) a), i) | (i, s) <- zip [(0 :: Int) ..] ss ])
    mOf a   = fromInteger (setM (ss !! idxOf a)) :: Double
    nearest a = minimumBy (comparing (\b -> magnitude (brValue b - a)))

evalC :: Poly -> Complex Double -> Complex Double
evalC p z = foldr (\c acc -> acc * z + (fromInteger c :+ 0)) 0 (coeffs p)

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
        esc '\n' = "\\n"
        esc '\r' = "\\r"
        esc '\t' = "\\t"
        esc c
          | c < ' '   = "\\u" ++ pad (showHexish (fromEnum c))
          | otherwise = [c]
        pad h = replicate (4 - length h) '0' ++ h
        showHexish 0 = "0"
        showHexish n = go n ""
          where go 0 acc = acc
                go k acc = go (k `div` 16) (hexDigit (k `mod` 16) : acc)
                hexDigit d | d < 10    = toEnum (fromEnum '0' + d)
                           | otherwise = toEnum (fromEnum 'a' + d - 10)

jarr :: [String] -> String
jarr xs = "[" ++ intercalate "," (map jstr xs) ++ "]"

obj :: [(String, String)] -> String
obj kvs = "{" ++ intercalate "," [jstr k ++ ":" ++ v | (k, v) <- kvs] ++ "}"

jchecks :: [Check] -> String
jchecks cs = "[" ++ intercalate ","
  [ obj [("name", jstr (checkName c)), ("ok", if checkOk c then "true" else "false")]
  | c <- cs ] ++ "]"
