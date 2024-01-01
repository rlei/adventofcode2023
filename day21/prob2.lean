import Lean.Data.HashSet

def Map : Type := Array (Array Char)

structure Pos where
  row : Int
  col : Int
deriving Repr, BEq, Hashable

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

def reachable (m: Map) (start: List Pos): List Pos :=
  let s := Lean.HashSet.empty
  start.map (reachableFrom m ·) |>.join |> s.insertMany |>.toList

def reachableAfter (m: Map) (start: List Pos) (steps: Nat): List Pos :=
  match steps with
  | 0 => start
  | n + 1 => reachableAfter m (reachable m start) n

def slotsAfterSteps (m: Map) (start: Pos) (steps: Nat): Nat :=
  -- dbg_trace s!"start {start.row},{start.col}; steps {steps}"
  let res := reachableAfter m [start] steps |>.length
  -- dbg_trace s!"{res}"
  res

def main : IO Unit := do
  let theMap <- readStdinLines
  -- let strings := theMap.map (String.mk ∘ Array.toList)
  -- strings.forM stdout.putStrLn

  let startRow := theMap.findIdx? (·.contains 'S') |>.get!
  let startCol := theMap.get! startRow |>.findIdx? (· = 'S') |>.get!
  let start := Pos.mk startRow startCol
  IO.println s!"start ({startRow}, {startCol})"

  IO.println "Base full plots..."
  let fullSlotsOdd := slotsAfterSteps theMap start 131
  let fullSlotsEven := slotsAfterSteps theMap start 132

  let fullSteps := 26501365
  -- after the first 65 steps, it repeats into nearby gardens
  let expandingSteps := fullSteps - 65

  --         SUS      <-|
  --        SBEBS       |
  --       SBEOEBS      | N = expandingSteps / 131
  --      SBEOEOEBS     |
  --     SBEOEOEOEBS    |
  --    SBEOEOEOEOEBS <-|
  --    LEOEOEOEOEOER
  --    SBEOEOEOEOEBS
  --     SBEOEOEOEBS
  --      SBEOEOEBS
  --       SBEOEBS
  --        SBEBS
  --         SDS
  -- * U, L, D, R: incomple ones at (131-1) steps, starting from middle of each boder
  -- * S: incomplete ones at (65-1) steps, starting from 4 cornders
  -- * B: incomplete ones at (196-1) steps, starting from 4 cornders
  -- * E: full ones at even steps
  -- * O: full ones at odd steps
  -- For N = expandingSteps / 131, there're:
  -- * N^2 even full ones (E)
  -- * (N-1)^2 odd full ones (O)
  -- * N S ones, at 4 directions: (S1 + S2 + S3 + S4) * N
  -- * N-1 B ones, at 4 directions: (B1 + B2 + B3 + B4) * (N - 1)

  -- apparently this only works with Day 21's full input data
  let N := expandingSteps / 131
  let fullGardensSlots := N * N * fullSlotsEven + (N-1) * (N-1) * fullSlotsOdd

  IO.println "Gardens at 4 corners..."
  let cornerGardensSlots := [(Pos.mk 0 65), (Pos.mk 130 65), (Pos.mk 65 0), (Pos.mk 65 130)].map
    (slotsAfterSteps theMap · (131-1)) |>.foldl (.+.) 0

  IO.println "Small diagnoal gardens..."
  let diagnoalSmallGardensSlots := ([(Pos.mk 0 0), (Pos.mk 0 130), (Pos.mk 130 0), (Pos.mk 130 130)].map
    (slotsAfterSteps theMap · (65-1)) |>.foldl (.+.) 0) * N

  IO.println "Large diagnoal gardens..."
  let diagnoalLargeGardensSlots := ([(Pos.mk 0 0), (Pos.mk 0 130), (Pos.mk 130 0), (Pos.mk 130 130)].map
    (slotsAfterSteps theMap · (196-1)) |>.foldl (.+.) 0) * (N - 1)

  let all := fullGardensSlots + cornerGardensSlots + diagnoalSmallGardensSlots + diagnoalLargeGardensSlots
  IO.println s!"All slots after {fullSteps} steps: {all}"
