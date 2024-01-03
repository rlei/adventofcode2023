import std/algorithm
import std/sequtils, std/strformat, std/strscans
import std/tables

type
  Row = int32
  Col = int32
  Pos = tuple[row: Row, col: Col]

  Dir = enum Up, Right, Down, Left

  FoldState = tuple[inside: bool, acc: int, lastShape: char, lastCol: Col]

var posToMove = tables.newTable[Pos, Dir]()
var posToTurn = tables.newTable[Pos, char]()
var rowToCols = tables.newTable[Row, seq[Col]]()

proc updatePosToTurn(pos: Pos, dir: Dir) =
    if posToMove.hasKey(pos):
        let (lastMove, thisMove) = 
            if pos != (row: 0i32, col: 0i32): (posToMove[pos], dir)
            else: (dir, posToMove[pos])
        assert(lastMove != thisMove)
        posToTurn[pos] = case lastMove
            of Dir.Up:
                if thisMove == Dir.Left: '7' else: 'F'
            of Dir.Down:
                if thisMove == Dir.Left: 'J' else: 'L'
            of Dir.Left:
                if thisMove == Dir.Up : 'L' else: 'F'
            of Dir.Right:
                if thisMove == Dir.Up : 'J' else: '7'
    else:
        posToMove[pos] = dir

proc isReverseTurn(last: char, this: char) : bool =
   (last == 'F' and this == 'J') or (last == 'L' and this == '7') 

proc walkInOrOut(state: FoldState, row: Row, col: Col): FoldState =
    let (inside, acc, lastShape, lastCol) = state
    let pos = (row: row, col: col)
    # if it's not a corner, it must be '|'
    let thisShape = posToTurn.getOrDefault(pos, '|')

    if not inside:
        let goingIn = thisShape == '|' or isReverseTurn(lastShape, thisShape)
        # outside or on the border
        (inside: goingIn, acc: acc, lastShape: thisShape, lastCol: col)
    else:
        if thisShape == '|':
            # inside => outside
            (inside: false, acc: acc + col - lastCol - 1, lastShape: '.', lastCol: -1)
        elif isReverseTurn(lastShape, thisShape):
            # on horizontal border => outside
            (inside: false, acc: acc, lastShape: '.', lastCol: -1)
        else:
            if lastCol != -1:
                # inside => on horizontal border
                (inside: true, acc: acc + col - lastCol - 1, lastShape: thisShape, lastCol: -1)
            else:
                # on horizontal border => inside
                (inside: true, acc: acc, lastShape: '.', lastCol: col)

var currPos: Pos = (row: 0, col: 0)

var borderLen = 0;
for line in stdin.lines:
    var dummy1: char
    var dummy2, color: int
    if line.scanf("$c $i (#$h)", dummy1, dummy2, color):
        var distance = int32(color div 16)
        borderLen += distance
        var dir = case color mod 16
            of 0: Dir.Right
            of 1: Dir.Down
            of 2: Dir.Left
            of 3: Dir.Up
            else: raise newException(ValueError, fmt"Invalid move direction {color mod 16}!")

        updatePosToTurn(currPos, dir)
        
        if dir == Dir.Up or dir == Dir.Left:
            distance = -distance

        if dir == Dir.Up or dir == Dir.Down:
            let endRow = currPos.row + distance
            let (startR, endR) = (if distance > 0: (currPos.row, endRow) else: (endRow, currPos.row))

            for row in startR..endR:
                if not rowToCols.hasKey row:
                    rowToCols[row] = @[]
                rowToCols[row].add(currPos.col)
            currPos.row = endRow
        else:
            currPos.col = currPos.col + distance

        # again at the next position, as two moves form a turn.
        updatePosToTurn(currPos, dir)

let (finalRow, finalCol) = currPos
if finalRow != 0 or finalCol != 0:
    raise newException(ValueError, "Not a closed shape")

var sum = 0
for row, cols in rowToCols:
    let startState: FoldState = (inside: false, acc: 0, lastShape: '.', lastCol: -1)
    let (_, covered, _, _) = foldl(sorted(cols), walkInOrOut(a, row, b), startState)
    sum += covered
    # echo fmt"covered {covered} at row {row}"

echo fmt"covered {sum + borderLen}"
