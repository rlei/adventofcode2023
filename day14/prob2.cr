alias RockMap = Array(Array(Char))

def tilt(theMap : RockMap) : RockMap
    theMap.map{ |line|
        after = line.reduce({new_line: Array(Char).new, pos: 0}) { |state, current|
            new_line = state[:new_line]
            pos = state[:pos]
            case current
            when 'O'
                new_line << 'O'
            when '#'
                new_line += Array.new(pos - new_line.size, '.')
                new_line << '#'
            when '.'
                # do nothing
            end
            {new_line: new_line, pos: pos + 1}
        }[:new_line]
        after += Array.new(line.size - after.size, '.')
    }
end

def tilt_west(theMap : RockMap) : RockMap
    tilt(theMap)
end

def tilt_north(theMap : RockMap) : RockMap
    tilt(theMap.transpose).transpose
end

def tilt_east(theMap : RockMap) : RockMap
    tilt(theMap.map{|line| line.reverse}).map{|line| line.reverse}
end

def tilt_south(theMap : RockMap) : RockMap
    tilt(theMap.transpose.map{|line| line.reverse}).map{|line| line.reverse}.transpose
end

map = RockMap.new
STDIN.each_line do |line|
    # puts line
    map << line.chars
end

num_rows = map.size

hash = Hash(RockMap, Int32).new

nextMap = map
rounds = 1_000_000_000
remaining = rounds
while remaining > 0
    nextMap = tilt_east(tilt_south(tilt_west(tilt_north(nextMap))))
    if hash.has_key?(nextMap)
        # puts "found dup pattern at round #{rounds - remaining}, last seen at #{rounds - hash[nextMap]}"
        remaining %= hash.[nextMap] - remaining
        # puts "fast forwarding to last #{remaining} rounds"
    else
        hash[nextMap] = remaining
    end
    remaining -= 1
end

# last transpose for the north beam load
puts nextMap.transpose.map{ |line|
    line.map_with_index{ |rock, i|
        rock == 'O' ? num_rows - i : 0
    }.sum
}.sum
