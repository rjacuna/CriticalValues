-- | Command line driver.
--
--   crit 1 0 1              -- f = X^2 + 1, given by coefficients, low to high
--   crit --squarefree 1 0 1 -- skip the (exponential) irreducibility step
--   crit --demo             -- the test vectors of spec §8
module Main (main) where

import System.Environment (getArgs)
import System.Exit (exitFailure)
import Poly
import Factor (Strategy(..))
import Construct
import Verify

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--demo"] -> demo
    _ -> case span (\a -> take 2 a == "--") args of
      (flags, nums)
        | null nums -> usage
        | otherwise -> run (if "--squarefree" `elem` flags then SquareFree else Irreducible)
                           (poly (map read nums))

usage :: IO ()
usage = putStrLn $ unlines
  [ "usage: crit [--squarefree] c0 c1 c2 ...   coefficients of f, low to high"
  , "       crit --demo                        the test vectors of spec §8"
  , ""
  , "  f = X^2 + 1  is  crit 1 0 1"
  ]

run :: Strategy -> Poly -> IO ()
run strat f = do
  putStrLn $ "f  = " ++ pretty f
  if deg f < 1 || isZero f
    then putStrLn "f must be nonconstant" >> exitFailure
    else if coeff f 0 == 0
      then do
        putStrLn "X | f, so the degenerate case of §6 applies:"
        putStrLn $ "g  = " ++ pretty (pow xP 2)
        putStrLn $ "H  = " ++ pretty xP
      else case setupExists strat f of
        Left err -> putStrLn ("error: " ++ err) >> exitFailure
        Right s  -> do
          putStrLn $ "h  = " ++ pretty (setH s)
          putStrLn $ "u  = " ++ pretty (setU s)
          putStrLn $ "v  = " ++ pretty (setV s)
          putStrLn $ "ρ  = " ++ show (setRho s)
          putStrLn $ "h₀ = " ++ show (setH0 s)
          putStrLn $ "M  = " ++ show (setM s)
          putStrLn $ "H  = " ++ pretty (setBigH s)
          putStrLn $ "W  = " ++ pretty (setW s)
          putStrLn $ "g  = " ++ pretty (setG s)
          putStrLn ""
          putStr (report (checks s))
          if allOk (checks s) then return () else exitFailure

-- | Spec §8.  Each vector is checked twice: fed the spec's own Bézout data it
-- must reproduce the spec's @H@, @W@ and @g@ exactly; run through the
-- program's own pipeline it must satisfy every check.
demo :: IO ()
demo = do
  putStrLn "=== §8.1  f = qX - p, at p = 3, q = 2 ==="
  vector (poly [-3, 2]) (poly [-3, 2]) one zero one 2
    [("H", poly [1, 4]), ("W", poly [0, 2]), ("g", poly [0, -12, -24])]

  putStrLn "=== §8.2  f = X^2 + 1 ==="
  vector (poly [1, 0, 1]) (poly [1, 0, 1]) one (constP 2) (neg xP) 2
    [("H", poly [1, 0, 4]), ("W", poly [0, 1]), ("g", poly [0, 3, 0, 4])]

  putStrLn "=== §8.3  f = X^3 - 2 ==="
  vector (poly [-2, 0, 0, 1]) (poly [-2, 0, 0, 1]) one (constP 3) (neg xP) (-6)
    [("H", poly [1, 0, 0, -864]), ("W", poly [0, -2]), ("g", poly [0, 16, 0, 0, -3456])]

  putStrLn "=== §8.4  f = X^3 - X - 1, the hand-tuned quintic (statement only) ==="
  let f84 = poly [-1, -1, 0, 1]
      g84 = poly [118, -1610, 9085, -26450, 39675, -24334]
      h84 = poly [-1, 8, -23, 23]
  putStrLn $ "  g' = -230(23X - 7)H : "
        ++ ok (derivative g84 == mul (mul (constP (-230)) (poly [-7, 23])) h84)
  putStrLn $ "  H | g'              : " ++ ok (divides (derivative g84) h84)
  putStrLn $ "  H^2 | f(g)          : " ++ ok (divides (comp f84 g84) (mul h84 h84))
  case exactDiv (comp f84 g84) (mul h84 h84) of
    Just c  -> putStrLn $ "  cofactor (deg " ++ show (deg c) ++ "): " ++ pretty c
    Nothing -> putStrLn "  cofactor: none"
  putStrLn ""

  putStrLn "=== §8.5  f = X^3 - X^2 - 2X - 8 (Dedekind; spec claims M = 4024) ==="
  pipeline (poly [-8, -2, -1, 1])

  putStrLn "=== a few more, through the program's own pipeline ==="
  mapM_ pipeline [ poly [1, 0, 1], poly [-2, 0, 0, 1], poly [-1, -1, 0, 1]
                 , poly [1, 0, 0, 0, 1], poly [-3, 2] ]
  where
    ok b = if b then "ok" else "FAIL"
    divides p q = maybe False (const True) (exactDiv p q)

    -- feed the spec's own Bézout data and demand the spec's exact output
    vector f h f1 u v rho expected =
      case setupFromBezout f h f1 u v rho of
        Left err -> putStrLn ("  error: " ++ err) >> putStrLn ""
        Right s  -> do
          mapM_ (\(nm, e) -> putStrLn $ "  " ++ nm ++ " = " ++ pretty (sel nm s)
                          ++ "   matches spec: " ++ ok (sel nm s == e)) expected
          putStr (report (checks s))
          putStrLn ""
      where
        sel "H" = setBigH
        sel "W" = setW
        sel _   = setG

    -- run the program's own choice of h and Bézout data
    pipeline f =
      case setupExists Irreducible f of
        Left err -> putStrLn ("  " ++ pretty f ++ " -> error: " ++ err)
        Right s  -> do
          putStrLn $ "  f = " ++ pretty f
          putStrLn $ "    h = " ++ pretty (setH s) ++ "   ρ = " ++ show (setRho s)
                  ++ "   M = " ++ show (setM s)
          putStrLn $ "    H = " ++ pretty (setBigH s)
          putStrLn $ "    g = " ++ pretty (setG s)
          putStrLn $ "    all " ++ show (length (checks s)) ++ " checks: "
                  ++ (if allOk (checks s) then "ok" else "FAIL")
