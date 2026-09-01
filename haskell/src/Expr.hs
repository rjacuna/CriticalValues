-- | Evaluating a parsed expression to a polynomial.
--
-- The front end uses mathjs to *parse* — that is what a library should do, and
-- it is fast: 13 ms whether the input is @(x+1)^2@ or @(x+1)^8@. What it must
-- not do is the algebra. mathjs's @rationalize@ normalises by rewriting to a
-- fixed point, rescanning the whole tree against the whole rule set after every
-- rewrite, and the cost explodes: @(x+1)^4@ takes 75 ms and @(x+1)^5@ takes
-- 53 seconds for an answer that is six binomial coefficients.
--
-- So the AST arrives here as an s-expression and is evaluated with the exact
-- polynomial arithmetic the rest of the project already uses.
--
-- > (* (+ (^ x 3) x -2) (+ x 2))   ->   x^4 + 2x^3 + x^2 - 4
--
-- Intermediate values are rational, so @x/2 + 1@ is fine; denominators are
-- cleared at the end, which leaves the roots and hence the whole question
-- untouched.
module Expr (evalExpr) where

import Data.Char (isDigit, isSpace)
import Poly (Poly)
import QPoly (QP, clearDenoms, qAdd, qMul, qSub, qnorm)

data Tok = TOpen | TClose | TSym String | TNum Integer deriving (Eq, Show)

tokenize :: String -> Either String [Tok]
tokenize [] = Right []
tokenize s@(c : cs)
  | isSpace c = tokenize cs
  | c == '('  = (TOpen :) <$> tokenize cs
  | c == ')'  = (TClose :) <$> tokenize cs
  | c == '-', (d : _) <- cs, isDigit d =
      let (ds, rest) = span isDigit cs
      in (TNum (negate (read ds)) :) <$> tokenize rest
  | isDigit c = let (ds, rest) = span isDigit s
                in (TNum (read ds) :) <$> tokenize rest
  | otherwise = let (w, rest) = break (\x -> isSpace x || x `elem` "()") s
                in if null w then Left ("unexpected " ++ [c])
                   else (TSym w :) <$> tokenize rest

data Sexp = SNum Integer | SSym String | SList [Sexp] deriving Show

parseS :: [Tok] -> Either String (Sexp, [Tok])
parseS (TNum n : ts) = Right (SNum n, ts)
parseS (TSym w : ts) = Right (SSym w, ts)
parseS (TOpen : ts)  = go ts []
  where
    go (TClose : r) acc = Right (SList (reverse acc), r)
    go [] _             = Left "unclosed ("
    go r acc            = do (e, r') <- parseS r; go r' (e : acc)
parseS (TClose : _)  = Left "unexpected )"
parseS []            = Left "unexpected end of expression"

-- rationals as QP, so division by a constant is available
qconst :: Rational -> QP
qconst r = qnorm [r]

qx :: QP
qx = [0, 1]

qpow :: QP -> Integer -> QP
qpow _ 0 = qconst 1
qpow p n = qMul p (qpow p (n - 1))

isConst :: QP -> Maybe Rational
isConst q = case qnorm q of
  []  -> Just 0
  [r] -> Just r
  _   -> Nothing

eval :: Sexp -> Either String QP
eval (SNum n) = Right (qconst (fromInteger n))
eval (SSym "x") = Right qx
eval (SSym w) = Left ("unknown symbol " ++ w)
eval (SList (SSym op : args)) = do
  vs <- mapM eval args
  case (op, vs) of
    ("+", xs) | not (null xs) -> Right (foldr1 qAdd xs)
    ("*", xs) | not (null xs) -> Right (foldr1 qMul xs)
    ("-", [a])                -> Right (qSub (qconst 0) a)
    ("-", [a, b])             -> Right (qSub a b)
    ("/", [a, b]) -> case isConst b of
      Just r | r /= 0 -> Right (map (/ r) a)
      Just _          -> Left "division by zero"
      Nothing         -> Left "not a polynomial: division by a non-constant"
    ("^", [a, _]) -> case args of
      [_, SNum n] | n >= 0 -> Right (qpow a n)
                  | otherwise -> Left "negative exponent: not a polynomial"
      _ -> Left "exponent must be a non-negative integer"
    _ -> Left ("cannot apply " ++ op ++ " to " ++ show (length vs) ++ " argument(s)")
eval (SList _) = Left "malformed expression"

-- | Evaluate an s-expression to a primitive-free integer polynomial.
evalExpr :: String -> Either String Poly
evalExpr src = do
  ts <- tokenize src
  (e, rest) <- parseS ts
  if not (null rest) then Left "trailing input" else Right ()
  q <- eval e
  Right (clearDenoms (qnorm q))
