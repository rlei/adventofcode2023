module Main

import Data.Fin
import Data.List1
import Data.String
import Data.Vect

data Operation = Remove String | Add String String

data Lens = MkLens String String
lensLabel : Lens -> String
lensLabel (MkLens l _) = l
lensFocal : Lens -> String
lensFocal (MkLens _ f) = f

Show Lens where
    show (MkLens label focalLen)
        = "[" ++ label ++ " " ++ focalLen ++ "]"

parseOperation : String -> Operation
parseOperation s = let
    xs := String.split (\x => x == '=' || x == '-') s in
    case xs of
        (label ::: Nil) => Remove label     -- doesn't really happen
        (label ::: ("" :: Nil)) => Remove label
        (label ::: (focalLen :: _)) => Add label focalLen

label : Operation -> String
label (Remove l) = l
label (Add l _) = l

Boxes : Type
Boxes = Vect 256 (List Lens)

makeEmptyBoxes : Boxes
makeEmptyBoxes = replicate 256 (the (List Lens) [])

hasher : String -> Fin 256
hasher s = let
    helper : Int -> Char -> Int
    helper current ch = (current + (ord ch)) * 17 `mod` 256
  in
    case integerToFin (cast (foldl helper 0 (unpack s))) 256 of
    Just n => n
    Nothing => 0  -- impossible

addOrReplace : List Lens -> Lens -> List Lens
addOrReplace lensList lens = let
    label := lensLabel lens in
    -- case findIndex (\lens => label == lensLabel lens) lensList of
    -- Just index => replaceAt (finToNat index) lens lensList
    case find (\lens => label == lensLabel lens) lensList of
    Just old => replaceWhen (\lens => label == (lensLabel lens)) lens lensList
    Nothing => lensList ++ [lens]

updateBox : List Lens -> Operation -> List Lens
updateBox lensList operation =
    case operation of
        Remove label => filter (\lens => label /= (lensLabel lens)) lensList
        Add label focalLen => addOrReplace lensList (MkLens label focalLen)

applyOperations : List1 String -> Boxes
applyOperations steps = let
    operations := map parseOperation steps
    boxes := makeEmptyBoxes in
        foldl execute boxes operations
    where
        execute : Boxes -> Operation -> Boxes
        execute boxes operation = let
            l := label operation
            boxNo := hasher l
            box := index boxNo boxes in
            replaceAt boxNo (updateBox box operation) boxes

sumBox: (Fin 256, List Lens) -> Int
sumBox (boxIndex, lensList) = let
    allLensesPower := zip [0 .. length lensList] lensList
    sum := sum (map lensPower allLensesPower) in
    (cast (finToInteger boxIndex) + 1) * (cast sum)
    where
        lensPower : (Nat, Lens) -> Nat
        lensPower (lensIndex, lens) =
            case parsePositive (lensFocal lens) of
                Just n => (lensIndex + 1) * n
                Nothing => 0 -- impossible
    

main : IO ()
main = do
    input <- getLine
    let steps := String.split (== ',') input
        result := applyOperations steps
        s := sum (map sumBox (zip Data.Vect.Fin.range result))
    -- putStrLn (show result)
    putStrLn (show s)
