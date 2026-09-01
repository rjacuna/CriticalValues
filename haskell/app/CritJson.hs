-- | The same request handler as a native binary, for the development server.
--
-- Reads one wire string per line on stdin and writes one JSON object per line.
-- Line-oriented so the server can keep a single process warm rather than
-- paying process startup per request.
module Main (main) where

import System.IO
import WebCore (run)

main :: IO ()
main = do
  hSetBuffering stdout LineBuffering
  hSetEncoding stdout utf8
  hSetEncoding stdin utf8
  contents <- getContents
  mapM_ (putStrLn . run) (lines contents)
