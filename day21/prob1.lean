def Map : Type := Array (Array Char)

structure Pos where
  row : Int
  col : Int
deriving Repr, BEq

partial def readStdinLines : IO Map := do
  let stdin <- IO.getStdin
  let rec readLines (acc : List (Array Char)) : IO (List (Array Char)) := do
    let lineOpt <- stdin.getLine
    let stripped := lineOpt.dropRightWhile Char.isWhitespace |>.toList.toArray
    match lineOpt with
    | "" => pure acc
    | _ => readLines (stripped :: acc)

  (readLines []).map (List.toArray ∘ List.reverse)

def reachableFrom (m: Map) (pos: Pos): List Pos :=
  [(-1, 0), (1, 0), (0, -1), (0, 1)].map (fun move =>
    let row := pos.row + move.fst
    let col := pos.col + move.snd
    Pos.mk row col
  ) |> .filter (fun newPos =>
    newPos.row >= 0 && newPos.row < m.size &&
    newPos.col >= 0 && newPos.col < (m.get! 0).size &&
    (m.get! (Int.toNat newPos.row) |>.get! (Int.toNat newPos.col)) != '#')

-- #eval reachableFrom #[#['.', 'S', '.'], #['.', '.', '.']] (Pos.mk 1 1)

def reachable (m: Map) (start: List Pos): List Pos :=
  start.map (reachableFrom m ·) |>.join.eraseDups

def reachableAfter (m: Map) (start: List Pos) (steps: Nat): List Pos :=
  match steps with
  | 0 => start
  | n + 1 =>
    let now := reachable m start
    reachableAfter m now n

-- #eval reachableAfter #[#['.', '#', '.'], #['.', '.', 'S']] [(Pos.mk 1 1)] 2

def main : IO Unit := do
  let theMap <- readStdinLines
  -- let strings := theMap.map (String.mk ∘ Array.toList)
  -- strings.forM stdout.putStrLn

  let startRow := theMap.findIdx? (·.contains 'S') |>.get!
  let startCol := theMap.get! startRow |>.findIdx? (· = 'S') |>.get!
  let start := Pos.mk startRow startCol
  IO.println s!"start ({startRow}, {startCol})"

  let steps := 64
  let final := reachableAfter theMap [start] steps
  IO.println s!"After 6 steps: {reachableAfter theMap [start] 6 |>.length}"
  IO.println s!"After {steps} steps: {final.length}"
