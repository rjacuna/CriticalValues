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

import Data.Complex (Complex(..), magnitude, realPart, imagPart)
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
  , ("gp",      jarr (pcoeffs (derivative (setG s))))
  , ("crit",    jcrit (critPoints s))
  , ("plot",    maybe "null" jplot (plotOf s))
  , ("degG",    jstr (show (deg (setG s))))
  , ("digitsG", jstr (show (digitsOf (setG s))))
  , ("checks",  jchecks (checks s))
  ]

-- | Every root of @f@, matched to the setup whose @h@ vanishes there — so a
-- reducible @f@ gets a different @g@ per factor, and @β = α/M@ uses that
-- factor's own @M@. The match is numeric because the roots are; the winner
-- beats the others by orders of magnitude in practice.
--
-- The closed form comes from that factor, not from @f@. @deg α@ is the degree
-- of its minimal polynomial, so a rational root of a quartic gets a rational
-- expression and not the Ferrari formula: @(x³+x−2)(x+2)@ factors as
-- @(x−1)(x²+x+2)(x+2)@, whose roots deserve @x = 1@, the quadratic formula, and
-- @x = −2@ respectively. It also means a degree-6 @f@ splitting into two cubics
-- gets Cardano twice rather than nothing at all.
jroots :: Poly -> [Setup] -> String
jroots f ss = "[" ++ intercalate "," (map one (roots f)) ++ "]"
  where
    -- one radical table per factor, not per root
    brss = [ radicals (setH s) | s <- ss ]
    one a = obj
      [ ("alpha",  jstr (showComplex 7 a))
      , ("beta",   jstr (showComplex 7 (a / (fromInteger (setM (ss !! i)) :+ 0))))
      , ("setup",  jstr (show i))
      , ("degree", jstr (show (deg (setH (ss !! i)))))
      , ("rad",    maybe "null" (jstr . brLatex . nearest a) (brss !! i))
      ]
      where i = idxOf a
    idxOf a = snd (minimumBy (comparing fst)
                [ (magnitude (evalC (setH s) a), i) | (i, s) <- zip [(0 :: Int) ..] ss ])
    nearest a = minimumBy (comparing (\b -> magnitude (brValue b - a)))

-- | The real critical points of @g@: the real roots of @g\'@, each with the
-- critical value there. The construction puts @α@ at one of them, and this is
-- what makes that checkable rather than asserted — the plot draws every one.
--
-- Real means real: a root is kept when its imaginary part is negligible beside
-- its own size, and clustered duplicates (@g\'@ can have repeated roots) are
-- collapsed, so a double critical point is drawn once.
critPoints :: Setup -> [(Double, Double)]
critPoints s = dedupe
  [ (b, realPart (evalC (setG s) (b :+ 0)))
  | z <- roots (derivative (setG s))
  , let b = realPart z
  , abs (imagPart z) <= 1e-9 * max 1 (magnitude z) ]
  where
    dedupe = foldr ins []
    ins x acc | any (near x) acc = acc
              | otherwise        = x : acc
    near (b, _) (c, _) = abs (b - c) <= 1e-9 * max 1 (max (abs b) (abs c))

-- | The viewing window, computed here rather than in the browser: it is
-- geometry, and geometry is mathematics.
--
-- Wide enough to hold every real critical point and the x-axis, so each line
-- @x = β@ meets the curve inside the frame. One critical point gives no spread
-- to scale from, so the width falls back to the curvature half-width — the
-- distance over which the parabola @α + ½g''(β)t²@ climbs by @max(1,|α|)@.
--
-- @k@ is what makes @g@ and @g\'@ shareable axes. They differ by orders of
-- magnitude: on @x⁵−x−1@, @g@ spans about 1.7 while @g\'@ runs to ±6·10⁴, so
-- an unscaled @g\'@ is a vertical stripe. Dividing by @k@ — the largest @|g\'|@
-- in frame, over the half-height — puts its zeros where they belong without
-- moving them. Only the height is a lie, and @k@ is on screen to say so.
data Plot = Plot Double Double Double Double Double

plotOf :: Setup -> Maybe Plot
plotOf s = case critPoints s of
  []            -> Nothing
  cps@(c0 : _)  -> Just (Plot xlo xhi ylo yhi k)
    where
      bs = map fst cps
      as = map snd cps
      x0 = minimum bs;      x1 = maximum bs
      y0 = minimum (0 : as); y1 = maximum (0 : as)
      padx | x1 > x0   = 0.25 * (x1 - x0)
           | otherwise = 4 * halfWidth s c0
      pady | y1 > y0   = 0.25 * (y1 - y0)
           | otherwise = max 1 (abs (snd c0))
      xlo = x0 - padx; xhi = x1 + padx
      ylo = y0 - pady; yhi = y1 + pady
      gp  = derivative (setG s)
      -- over the span of the critical points, not the padded window: @g'@ is a
      -- high-degree polynomial and its largest values in frame are always out
      -- at the edges, so scaling by those would flatten every interior zero —
      -- exactly the part the plot exists to show. A lone critical point has no
      -- span, so it gets one curvature half-width to either side.
      (s0, s1) | x1 > x0   = (x0, x1)
               | otherwise = (x0 - padx / 4, x1 + padx / 4)
      m   = maximum [ abs (realPart (evalC gp (t :+ 0)))
                    | i <- [0 .. 400 :: Int]
                    , let t = s0 + (s1 - s0) * fromIntegral i / 400 ]
      k   = max 1 (m / max 1e-300 ((yhi - ylo) / 2))

-- | Half the width over which @g@ rises by @max(1,|α|)@ above a critical point.
halfWidth :: Setup -> (Double, Double) -> Double
halfWidth s (b, a)
  | h2 <= 0 || isNaN h2 || isInfinite h2 = 1
  | otherwise = sqrt (2 * max 1 (abs a) / h2)
  where h2 = abs (realPart (evalC (derivative (derivative (setG s))) (b :+ 0)))

jplot :: Plot -> String
jplot (Plot a b c d k) = obj
  [ ("xlo", jstr (showComplex 7 (a :+ 0))), ("xhi", jstr (showComplex 7 (b :+ 0)))
  , ("ylo", jstr (showComplex 7 (c :+ 0))), ("yhi", jstr (showComplex 7 (d :+ 0)))
  , ("k",   jstr (showComplex 7 (k :+ 0))) ]

jcrit :: [(Double, Double)] -> String
jcrit bs = "[" ++ intercalate ","
  [ obj [("b", jstr (showComplex 7 (b :+ 0))), ("a", jstr (showComplex 7 (a :+ 0)))]
  | (b, a) <- bs ] ++ "]"

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
