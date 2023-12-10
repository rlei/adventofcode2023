
local function faster_ways(time, distance)
    for i=0, time//2 do
        if i * (time - i) > distance then
            return (time // 2 - i + 1) * 2 - (1 - time % 2)
        end
    end
    return 0 
end

-- local time_and_disatnces = { {7, 9}, {15, 40}, {30, 200} }
local time_and_disatnces = { {45, 305}, {97, 1062}, {72, 1110}, {95, 1695} }
local product = 1

for _,v in ipairs(time_and_disatnces) do
    product = product * faster_ways(v[1], v[2])
end

print(product)

print(faster_ways(45977295, 305106211101695))
