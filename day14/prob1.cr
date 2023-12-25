alias RockMap = Array(Array(Char))

def tilt(theMap : RockMap) : RockMap
    theMap.map{ |line|
        line.reduce({new_line: Array(Char).new, pos: 0}) { |state, current|
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
    }
end

map = RockMap.new
STDIN.each_line do |line|
    # puts line
    map << line.chars
end

num_rows = map.size

tilted = tilt(map.transpose)
# tilted.each { |line| puts line}
puts tilted.map{ |line|
    line.map_with_index{ |rock, i|
        rock == 'O' ? num_rows - i : 0
    }.sum
}.sum
