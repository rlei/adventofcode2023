using Pkg
Pkg.add(["SymPy", "Combinatorics", "Pipe", "NLsolve"])

using Combinatorics
using NLsolve
using Pipe
using SymPy

struct LocAndSpeed
    x ::Int
    y ::Int
    z ::Int
    vx ::Int
    vy ::Int
    vz ::Int
end

function extractParams(strNums)
    return LocAndSpeed(
        parse(Int, strNums[1]),
        parse(Int, strNums[2]),
        parse(Int, strNums[3]),
        parse(Int, strNums[4]),
        parse(Int, strNums[5]),
        parse(Int, strNums[6]),
    )
end

@syms t1 t2

function findCollision(stone1 :: LocAndSpeed, stone2 :: LocAndSpeed, areaMin :: Int, areaMax :: Int)
    r = solve([stone1.x + stone1.vx * t1 - (stone2.x + stone2.vx * t2),
           stone1.y + stone1.vy * t1 - (stone2.y + stone2.vy * t2)],
           [t1, t2])
    if isempty(r)
        return r
    end
    time1, time2 = (r[t1], r[t2])
    if time1 > 0 && time2 > 0 &&
        areaMin <= stone1.x + stone1.vx * time1 <= areaMax &&
        areaMin <= stone1.y + stone1.vy * time1 <= areaMax &&
        areaMin <= stone2.x + stone2.vx * time2 <= areaMax &&
        areaMin <= stone2.y + stone2.vy * time2 <= areaMax
        # print(".")
        return r
    end
    return Any[]
end

re = r"(\d+), +(\d+), +(\d+) @ +(-?\d+), +(-?\d+), +(-?\d+)"

hailstones = map(line -> extractParams(match(re, line).captures[1:6]), chomp.(readlines()))
# println(hailstones)

# x[1:5]: 5 collision times with 5 hailstones
# x[6:8]: vx, vy, vz of the stone
function nlsolveEquation(s, x, i1, i2)
    # consider
    #   a) s1.x + s1.vx * t1 = x + vx * t1
    #   b) s2.x + s2.vx * t2 = x + vx * t2
    # with a) - b), we have
    #   (s1.x - s2.x) + (s1.vx * t1 - s2.vx * t2) = vx * (t1 - t2)
    # so the location "x" is eliminated
    [s[i1].x - s[i2].x + s[i1].vx * x[i1] - s[i2].vx * x[i2] - x[6] * (x[i1] - x[i2]),
    s[i1].y - s[i2].y + s[i1].vy * x[i1] - s[i2].vy * x[i2] - x[7] * (x[i1] - x[i2]),
    s[i1].z - s[i2].z + s[i1].vz * x[i1] - s[i2].vz * x[i2] - x[8] * (x[i1] - x[i2])]
end

function f(x)
    @pipe combinations([1, 2, 3, 4, 5], 2) |>
        map(pair -> nlsolveEquation(hailstones, x, pair[1], pair[2]), _) |>
        reduce(vcat, _)
end

println("Part 2...")
sol = nlsolve(f, fill(10.0, 30))
# println(sol.zero)
hit_t1 = sol.zero[1]
vx, vy, vz = sol.zero[6:8]
x0 = round(Int, hailstones[1].x + hailstones[1].vx * hit_t1 - vx * hit_t1)
y0 = round(Int, hailstones[1].y + hailstones[1].vy * hit_t1 - vy * hit_t1)
z0 = round(Int, hailstones[1].z + hailstones[1].vz * hit_t1 - vz * hit_t1)
println("$(x0) + $(y0) + $(z0) = $(x0 + y0 + z0)")

println("Part 1, wait for 1-2 minutes...")
@pipe combinations(hailstones, 2) |>
    map(pair -> findCollision(pair[1], pair[2], 200000000000000, 400000000000000), _) |>
    filter(r -> !isempty(r), _) |>
    println(length(_))

exit(0)
