import std.stdio, std.array, std.algorithm, std.math, std.string;

struct Pos {
    int row;
    int col;
}

long distance(Pos p1, Pos p2) {
    return abs(p1.row - p2.row) + abs(p1.col - p2.col);
}

void updateMissingMap(ref int[int] theMap) {
    int maxNo = theMap.keys.maxElement;

    for (int missingSoFar = 0, i = 0; i <= maxNo; i++) {
        if (i in theMap) {
            theMap[i] = missingSoFar;
        } else {
            missingSoFar++;
        }
    }
}

void main() {
    // Row # to number of missing rows up until this row
    int[int] rowMap;
    // Col # to number of missing cols up until this col
    int[int] colMap;
    Pos[] galaxies;

    int row = 0;
    foreach (line; stdin.byLine) {
        int col = 0;
        foreach (c; line) {
            if (c == '#') {
                rowMap[row] = 0;
                colMap[col] = 0;
                galaxies ~= Pos(row, col);
            }
            col++;
        }
        row++;
    }
    updateMissingMap(rowMap);
    updateMissingMap(colMap);

    auto expandedGalaxies = galaxies
        .map!(pos => Pos(pos.row + rowMap[pos.row], pos.col + colMap[pos.col]))
        .array;
    
    auto pairs = cartesianProduct(expandedGalaxies, expandedGalaxies);

    // It's a cartesian product so all pairs are counted twice, hence / 2.
    writeln("distance sum ", pairs.map!(pair => distance(pair[0], pair[1])).sum() / 2);

    auto expandedGalaxies2 = galaxies
        .map!(pos => Pos(pos.row + rowMap[pos.row] * 999_999, pos.col + colMap[pos.col] * 999_999))
        .array;
    writeln("after one million times larger growth - distance sum ",
        cartesianProduct(expandedGalaxies2, expandedGalaxies2)
            .map!(pair => distance(pair[0], pair[1])).sum() / 2);
}
