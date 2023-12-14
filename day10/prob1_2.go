package main

import (
	"bufio"
	"fmt"
	"os"
	"reflect"
	"slices"
)

type position struct {
	row int
	col int
}

type tile struct {
	pipe        rune
	connectedTo []position
}

func createTile(row, col int, pipe rune) tile {
	switch pipe {
	case '|':
		return tile{pipe, []position{{row - 1, col}, {row + 1, col}}}
	case '-':
		return tile{pipe, []position{{row, col - 1}, {row, col + 1}}}
	case 'L':
		return tile{pipe, []position{{row - 1, col}, {row, col + 1}}}
	case 'J':
		return tile{pipe, []position{{row - 1, col}, {row, col - 1}}}
	case '7':
		return tile{pipe, []position{{row + 1, col}, {row, col - 1}}}
	case 'F':
		return tile{pipe, []position{{row + 1, col}, {row, col + 1}}}
	case '.':
		fallthrough
	case 'S':
		// special case
		fallthrough
	default:
		return tile{}
	}
}

func detectPipe(start position, connectedTo []position) rune {
	row, col := start.row, start.col
	tileCandidates := []tile{
		{'|', []position{{row - 1, col}, {row + 1, col}}},
		{'-', []position{{row, col - 1}, {row, col + 1}}},
		{'L', []position{{row - 1, col}, {row, col + 1}}},
		{'J', []position{{row - 1, col}, {row, col - 1}}},
		{'7', []position{{row + 1, col}, {row, col - 1}}},
		{'F', []position{{row + 1, col}, {row, col + 1}}},
	}
	for _, candidate := range tileCandidates {
		if reflect.DeepEqual(candidate.connectedTo, connectedTo) ||
			reflect.DeepEqual(candidate.connectedTo, []position{connectedTo[1], connectedTo[0]}) {
			return candidate.pipe
		}
	}
	panic("pipe not detected")
}

func connected(theMap [][]tile, row, col, nextRow, nextCol int) bool {
	if nextRow < 0 || nextRow >= len(theMap) {
		return false
	}
	if nextCol < 0 || nextCol >= len(theMap[0]) {
		return false
	}
	return slices.Contains(theMap[nextRow][nextCol].connectedTo, position{row, col})
}

func nextConnectedTile(theMap [][]tile, pos, fromPos position) position {
	tile := theMap[pos.row][pos.col]
	if tile.connectedTo[0] == fromPos {
		return tile.connectedTo[1]
	}
	if tile.connectedTo[1] != fromPos {
		panic(fmt.Sprintf("tile %v is not connected to %v", pos, fromPos))
	}
	return tile.connectedTo[0]
}

func main() {
	// reader := bufio.NewReader(os.Stdin)

	var lines []string
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	theMap := make([][]tile, len(lines))

	startRow := -1
	startCol := -1

	for row, line := range lines {
		// fmt.Println(line)
		theMap[row] = make([]tile, len(line))

		for col, pipe := range line {
			theMap[row][col] = createTile(row, col, pipe)
			if pipe == 'S' {
				startRow = row
				startCol = col
				fmt.Printf("Start found at row %d, col %d\n", startRow, startCol)
			}
		}
	}

	var connectedToStart []position
	for _, neighbors := range [][2]int{{-1, 0}, {0, 1}, {1, 0}, {0, -1}} {
		if connected(theMap, startRow, startCol, startRow+neighbors[0], startCol+neighbors[1]) {
			connectedToStart = append(connectedToStart, position{startRow + neighbors[0], startCol + neighbors[1]})
		}
	}
	if len(connectedToStart) != 2 {
		panic("couldn't find 2 connected pipes to the start point")
	}
	start := position{startRow, startCol}
	// Fix 'S' tile!
	startPipe := tile{detectPipe(start, connectedToStart), connectedToStart}
	theMap[startRow][startCol] = startPipe

	fmt.Printf("Start is pipe %c connected to %v\n", startPipe.pipe, connectedToStart)

	var pathSet = make(map[position]struct{})
	pathSet[start] = struct{}{}
	from, current := start, connectedToStart[0]
	for current != start {
		// fmt.Printf("visiting %v\n", current)
		pathSet[current] = struct{}{}
		next := nextConnectedTile(theMap, current, from)
		from, current = current, next
	}
	steps := len(pathSet)
	fmt.Printf("Total steps %d, farthest %d\n", steps, (steps+1)/2)

	fmt.Printf("Enclosed area %d\n", calculateEnclosedArea(theMap, pathSet))
}

func calculateEnclosedArea(theMap [][]tile, pathSet map[position]struct{}) int {
	inside := false
	area := 0
	for row, tileLine := range theMap {
		col := 0
		for col < len(tileLine) {
			if _, ok := pathSet[position{row, col}]; ok {
				// only possible pipes here are F, | and L
				startPipe := tileLine[col].pipe
				switch startPipe {
				case '|':
					inside = !inside
				default:
					currentPipe := tileLine[col].pipe
					for currentPipe != '7' && currentPipe != 'J' {
						col++
						currentPipe = tileLine[col].pipe
					}
					if (startPipe == 'F' && currentPipe == 'J') ||
						(startPipe == 'L' && currentPipe == '7') {
						inside = !inside
					}
				}
			} else {
				if inside {
					area++
				}
			}
			col++
		}
	}
	return area
}
