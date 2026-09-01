{-# LANGUAGE ForeignFunctionInterface #-}

-- | The wasm reactor export. A shim over "WebCore" and nothing else — all the
-- work, and all the mathematics, is in the library.
module Web (solve) where

import GHC.Wasm.Prim
import WebCore (run)

foreign export javascript "solve" solve :: JSString -> IO JSString

solve :: JSString -> IO JSString
solve = pure . toJSString . run . fromJSString
