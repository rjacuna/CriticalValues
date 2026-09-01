-- | Benchmark: pure-Haskell Kronecker against FLINT, on inputs deliberately
-- harder than anything in spec §8.
--
-- Three columns matter.  "choose h" is where the algorithmic difference lives.
-- "digits" is the size of the largest coefficient of `g`, which is what the
-- choice of `h` controls (§4 of OPTIMIZATION.md) and what a user actually has
-- to look at.
module Main (main) where

import Control.Exception (evaluate)
import Data.List (minimumBy, sortBy)
import Data.Ord (comparing)
import System.CPUTime (getCPUTime)
import System.Timeout (timeout)
import Poly
import Bezout (bezout)
import Factor (Strategy(..), chooseFactor)
import Construct
import Verify
import FlintBind

kronekerBudget :: Int
kronekerBudget = 10 * 1000000   -- 10 s

tests :: [(String, Poly)]
tests =
  [ ("Phi_7",                     poly (replicate 7 1))
  , ("Phi_11",                    poly (replicate 11 1))
  , ("X^8 - 2",                   poly ([-2] ++ replicate 7 0 ++ [1]))
  , ("Swinnerton-Dyer S3",        poly [576,0,-960,0,352,0,-40,0,1])
  , ("(X-1)...(X-6)",             foldr1 mul [poly [-k,1] | k <- [1..6]])
  , ("(X^3-2)(X^3-3)",            mul (poly [-2,0,0,1]) (poly [-3,0,0,1]))
  , ("X^12 - 1",                  poly ([-1] ++ replicate 11 0 ++ [1]))
  , ("X^5 - X - 1",               poly [-1,-1,0,0,0,1])
  , ("X^3 - 1000003X + 7",        poly [7,-1000003,0,1])
  , ("7X^5+1234567X^3-89X+1e5",   poly [100003,-89,0,1234567,0,7])
    -- one cheap factor and one expensive one: these are where the choice of h
    -- (OPTIMIZATION.md §4) actually costs or saves something.
  , ("(X^3-1000003X+7)(X-1)",     mul (poly [7,-1000003,0,1]) (poly [-1,1]))
  , ("(X^5-X-1)(X+3)",            mul (poly [-1,-1,0,0,0,1]) (poly [3,1]))
  , ("(7X^5+..+1e5)(X-2)",        mul (poly [100003,-89,0,1234567,0,7]) (poly [-2,1]))
  ]

-- force a polynomial completely
force :: Poly -> IO Integer
force p = evaluate (sum (map abs (coeffs p)) + fromIntegral (deg p))

timeIt :: IO a -> IO (a, Double)
timeIt act = do
  t0 <- getCPUTime
  r  <- act
  t1 <- getCPUTime
  return (r, fromIntegral (t1 - t0) / 1e12)

digitsOf :: Poly -> Int
digitsOf p
  | isZero p  = 1
  | otherwise = length (show (maximum (map abs (coeffs p))))

-- FLINT's factors, filtered to those the construction can use
usable :: [Poly] -> [Poly]
usable = filter (\h -> deg h >= 1 && coeff h 0 /= 0)

-- §4: among usable factors, the one minimising |M| = |rho * h0|
bestByM :: [Poly] -> Maybe (Poly, Integer)
bestByM hs =
  case [ (h, abs (r * coeff h 0)) | h <- hs, Just (_,_,r) <- [bezout h] ] of
    [] -> Nothing
    xs -> Just (minimumBy (comparing snd) xs)

pad :: Int -> String -> String
pad n s = s ++ replicate (max 0 (n - length s)) ' '

lpad :: Int -> String -> String
lpad n s = replicate (max 0 (n - length s)) ' ' ++ s

fmt :: Double -> String
fmt t
  | t >= 10   = show (round t :: Integer) ++ "s"
  | t >= 0.01 = show (fromIntegral (round (t * 100) :: Integer) / 100 :: Double)
  | otherwise = "<0.01"

data Row = Row
  { rName :: String, rDegF :: Int, rNFac :: Int
  , rKron :: Maybe Double, rFlint :: Double
  , rDegH :: Int, rRhoD :: Int, rMD :: Int
  , rDegG :: Int, rGD :: Int, rOk :: String
  , rFirstMD :: Int }

measure :: (String, Poly) -> IO Row
measure (name, f) = do
  (kres, kt) <- timeIt $ timeout kronekerBudget $ do
    let h = chooseFactor Irreducible f
    maybe (return 0) force h
  (fs, ft) <- timeIt $ do
    hs <- flintIrreducibleFactors f
    mapM_ force hs
    return (usable hs)
  let mOf h = case bezout h of
                Just (_, _, r) -> Just (r, abs (r * coeff h 0))
                Nothing        -> Nothing
      cands  = [ (h, r, m) | h <- fs, Just (r, m) <- [mOf h] ]
      firstM = case cands of ((_,_,m):_) -> m; [] -> 0
      best   = case cands of
                 [] -> Nothing
                 xs -> Just (minimumBy (comparing (\(_,_,m) -> m)) xs)
  case best of
    Nothing -> return (Row name (deg f) (length fs) (fmap (const kt) kres) ft
                           0 0 0 0 0 "-" 0)
    Just (h, r, m) -> case setupOfFactor f h of
      Left _  -> return (Row name (deg f) (length fs) (fmap (const kt) kres) ft
                             (deg h) 0 0 0 0 "err" 0)
      Right s -> do
        _ <- force (setG s)
        return (Row name (deg f) (length fs) (fmap (const kt) kres) ft
                    (deg h) (digitsI r) (digitsI m) (deg (setG s)) (digitsOf (setG s))
                    (if allOk (checks s) then "ok" else "FAIL") (digitsI firstM))

digitsI :: Integer -> Int
digitsI n = length (show (abs n))

main :: IO ()
main = do
  rows <- mapM measure tests
  putStrLn ""
  putStrLn "FACTORING  (choosing h; Kronecker budget 10s)"
  putStrLn (replicate 74 '-')
  putStrLn (pad 26 "  polynomial" ++ lpad 5 "deg" ++ lpad 6 "#irr"
            ++ lpad 12 "Kronecker" ++ lpad 10 "FLINT" ++ lpad 12 "speedup")
  putStrLn (replicate 74 '-')
  mapM_ rowA rows
  putStrLn ""
  putStrLn "CONSTRUCTION  (built from FLINT's factors, h chosen to minimise |M|)"
  putStrLn (replicate 74 '-')
  putStrLn (pad 26 "  polynomial" ++ lpad 6 "deg h" ++ lpad 8 "digits" ++ lpad 8 "digits"
            ++ lpad 7 "deg g" ++ lpad 10 "digits" ++ lpad 9 "checks")
  putStrLn (pad 26 "" ++ lpad 6 "" ++ lpad 8 "of rho" ++ lpad 8 "of M"
            ++ lpad 7 "" ++ lpad 10 "of g")
  putStrLn (replicate 74 '-')
  mapM_ rowB rows
  putStrLn ""
  putStrLn "CHOICE OF h  (only reducible f offer a choice; OPTIMIZATION.md §4)"
  putStrLn (replicate 74 '-')
  mapM_ rowC [r | r <- rows, rNFac r > 1, rMD r > 0]
  putStrLn ""
  where
    rowA r = putStrLn $ pad 26 ("  " ++ rName r) ++ lpad 5 (show (rDegF r))
             ++ lpad 6 (show (rNFac r))
             ++ lpad 12 (maybe "timeout" fmt (rKron r))
             ++ lpad 10 (fmt (rFlint r))
             ++ lpad 12 (case rKron r of
                           Nothing -> ">" ++ show (round (10 / max 1e-4 (rFlint r)) :: Integer) ++ "x"
                           Just k  -> show (round (k / max 1e-6 (rFlint r)) :: Integer) ++ "x")
    rowB r = putStrLn $ pad 26 ("  " ++ rName r) ++ lpad 6 (show (rDegH r))
             ++ lpad 8 (show (rRhoD r)) ++ lpad 8 (show (rMD r))
             ++ lpad 7 (show (rDegG r)) ++ lpad 10 (show (rGD r))
             ++ lpad 9 (rOk r)
    rowC r = putStrLn $ pad 26 ("  " ++ rName r)
             ++ "  first usable factor: |M| has " ++ show (rFirstMD r)
             ++ " digits;  best: " ++ show (rMD r)
