module Main

import Data.List1
import Data.String

hasher : String -> Int
hasher s = let
    helper : Int -> Char -> Int
    helper current ch = (current + (ord ch)) * 17 `mod` 256
  in
    foldl helper 0 (unpack s)

main : IO ()
main = do
    input <- getLine
    let steps := String.split (== ',') input
        result := sum (map hasher steps)
    putStrLn (show result)
