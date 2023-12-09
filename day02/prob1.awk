BEGIN { idSum = 0; max["red"] = 12; max["green"] = 13; max["blue"] = 14; }
{
    split($0, gameAndSets, ":")
    split(gameAndSets[1], gameAndId, " ")
    split(gameAndSets[2], sets, ";")
    for (i in sets) {
        split(sets[i], colors, ",")
        for (j in colors) {
            split(colors[j], numAndColor, " ")
            if (max[numAndColor[2]] < numAndColor[1]) {
                next
            }
        }
    }
    gameId = gameAndId[2]
    # print "valid game", gameId
    idSum += gameId
}
END {
    print "sum:", idSum;
}