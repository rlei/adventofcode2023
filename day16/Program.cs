using Pos = (int row, int col);

List<char[]> board = [];
string? line;
while ((line = Console.ReadLine()) != null && line.Length > 0)
{
    board.Add(line.ToCharArray());
}

var rows = board.Count;
var cols = board[0].Length;

char[,] energizedMap = new char[rows, cols];

rayTrace((0, 0), Move.Right);

/*
for (int row = 0; row < energizedMap.GetLength(0); row++) {
    for (int col = 0; col < energizedMap.GetLength(1); col++) {
        var ch = energizedMap[row, col];
        Console.Write(ch == 0 ? '.' : ch);
    }
    Console.WriteLine("");
}
*/
Console.WriteLine(countTiles(energizedMap));

// Part 2
int maxTiles = 0;
for (int col = 0; col < cols; col++)
{
    energizedMap = new char[rows, cols];
    rayTrace((0, col), Move.Down);
    maxTiles = Math.Max(maxTiles, countTiles(energizedMap));

    energizedMap = new char[rows, cols];
    rayTrace((rows - 1, col), Move.Up);
    maxTiles = Math.Max(maxTiles, countTiles(energizedMap));
}
for (int row = 0; row < board.Count; row++)
{
    energizedMap = new char[rows, cols];
    rayTrace((row, 0), Move.Right);
    maxTiles = Math.Max(maxTiles, countTiles(energizedMap));

    energizedMap = new char[rows, cols];
    rayTrace((row, cols - 1), Move.Left);
    maxTiles = Math.Max(maxTiles, countTiles(energizedMap));
}
Console.WriteLine(maxTiles);

void rayTrace(in Pos pos, in Move move)
{
    (var row, var col) = pos;
    if (row < 0 || row >= board.Count || col < 0 || col >= board[0].Length)
    {
        return;
    }
    if (energizedMap[row, col] == '\0')
    {
        energizedMap[row, col] = board[row][col] == '.' ? '#' : (char)move;
        switch (board[row][col])
        {
            case '|':
                if (move == Move.Left || move == Move.Right)
                {
                    // split
                    traceRotateClockwise(pos, move);
                    traceRotateCounterClockwise(pos, move);
                }
                else
                {
                    // continue
                    rayTrace(nextPos(pos, move), move);
                }
                break;
            case '-':
                if (move == Move.Up || move == Move.Down)
                {
                    // split
                    traceRotateClockwise(pos, move);
                    traceRotateCounterClockwise(pos, move);
                }
                else
                {
                    // continue
                    rayTrace(nextPos(pos, move), move);
                }
                break;
            case '/':
                reflectMirrorSlash(pos, move);
                break;
            case '\\':
                reflectMirrorBackslash(pos, move);
                break;
            default:
                rayTrace(nextPos(pos, move), move);
                break;
        }
    }
    else
    {
        var lastVisit = energizedMap[row, col];
        if (lastVisit == 'B')
        {
            // '/' and '\' that have been visited both ways
            return;
        }
        switch (board[row][col])
        {
            case '|':
            case '-':
                return;

            case '/':
                if (isOppositeMove([Move.Up, Move.Left], (Move)lastVisit, move))
                {
                    energizedMap[row, col] = 'B';
                    reflectMirrorSlash(pos, move);
                }
                break;
            case '\\':
                if (isOppositeMove([Move.Up, Move.Right], (Move)lastVisit, move))
                {
                    energizedMap[row, col] = 'B';
                    reflectMirrorBackslash(pos, move);
                }
                break;
            default:
                rayTrace(nextPos(pos, move), move);
                break;

        }
    }

    void reflectMirrorSlash(in Pos pos, in Move move)
    {
        switch (move)
        {
            case Move.Up:
            case Move.Down:
                traceRotateClockwise(pos, move);
                break;
            case Move.Left:
            case Move.Right:
                traceRotateCounterClockwise(pos, move);
                break;
        }
    }

    void reflectMirrorBackslash(in Pos pos, in Move move)
    {
        switch (move)
        {
            case Move.Up:
            case Move.Down:
                traceRotateCounterClockwise(pos, move);
                break;
            case Move.Left:
            case Move.Right:
                traceRotateClockwise(pos, move);
                break;
        }
    }
}

bool isOppositeMove(in Move[] moves, Move move1, Move move2)
{
    return moves.Any(m => m == move1) ^ moves.Any(m => m == move2);
}

Pos nextPos(in Pos currPos, in Move move)
{
    (var row, var col) = currPos;
    return move switch
    {
        Move.Up => (row - 1, col),
        Move.Down => (row + 1, col),
        Move.Left => (row, col - 1),
        Move.Right => (row, col + 1),
        _ => throw new ArgumentException("impossible enum value"),
    };
}

void traceRotateClockwise(in Pos currPos, in Move move)
{
    var rotatedMove = move switch
    {
        Move.Up => Move.Right,
        Move.Down => Move.Left,
        Move.Left => Move.Up,
        Move.Right => Move.Down,
        _ => throw new ArgumentException("impossible enum value"),
    };
    rayTrace(nextPos(currPos, rotatedMove), rotatedMove);
}

void traceRotateCounterClockwise(in Pos currPos, in Move move)
{
    var rotatedMove = move switch
    {
        Move.Up => Move.Left,
        Move.Down => Move.Right,
        Move.Left => Move.Down,
        Move.Right => Move.Up,
        _ => throw new ArgumentException("impossible enum value"),
    };
    rayTrace(nextPos(currPos, rotatedMove), rotatedMove);
}

int countTiles(char[,] map)
{
    return Enumerable.Range(0, map.GetLength(0))
        .SelectMany(i => Enumerable.Range(0, map.GetLength(1))
        .Select(j => map[i, j] != 0 ? 1 : 0))
        .Sum();
}

enum Move : ushort
{
    Up = 'U',
    Down = 'D',
    Left = 'L',
    Right = 'R'
};
