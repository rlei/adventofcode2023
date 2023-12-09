BEGIN { powerSum = 0;  }
{
    max["red"] = 0
    max["green"] = 0
    max["blue"] = 0

    split($0, gameAndSets, ":")
    split(gameAndSets[2], sets, ";")
    for (i in sets) {
        split(sets[i], colors, ",")
        for (j in colors) {
            split(colors[j], numAndColor, " ")
            color = numAndColor[2]
            num = numAndColor[1]
            if (max[color] < num) {
                max[color] = num
            }
        }
    }
    power = max["red"] * max["green"] * max["blue"]
    # print "power", power
    powerSum += power
}
END {
    print "power sum:", powerSum;
}