{-# LANGUAGE ForeignFunctionInterface #-}

-- | The wasm reactor export. A shim over "WebCore" and nothing else — all the
-- work, and all the mathematics, is in the library.
module Web (solve) where

import GHC.Wasm.Prim
import WebCore (run)

-- `sync` matters: without it a JSFFI export returns a Promise, because GHC
-- defaults to running the export on the RTS scheduler. The construction is a
-- pure function and the caller wants a string back.
foreign export javascript "solve sync" solve :: JSString -> IO JSString

solve :: JSString -> IO JSString
solve = pure . toJSString . run . fromJSString
