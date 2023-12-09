const std = @import("std");

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    // const stdout = std.io.getStdOut().writer();

    const Pos = struct {
        row: i32,
        col: i32,
    };

    var buffer: [1]u8 = undefined;

    var row: i32 = 0;
    var col: i32 = 0;

    // we assign unique IDs to each part number found
    var numberId: usize = 0;
    var currentNumber: ?usize = null;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    var allocator = gpa.allocator();

    var posToNumberId = std.AutoHashMap(Pos, usize).init(allocator);
    defer posToNumberId.deinit();

    var idToNumber = std.AutoHashMap(usize, usize).init(allocator);
    defer idToNumber.deinit();

    var possibleGears = std.ArrayList(Pos).init(allocator);
    defer possibleGears.deinit();

    while (true) {
        const read_result = try stdin.read(buffer[0..1]);
        if (read_result == 0) break;

        var ch = buffer[0];
        if ((ch >= '0') and (ch <= '9')) {
            if (currentNumber) |num| {
                currentNumber = num * 10 + ch - '0';
            } else {
                // found a new number
                numberId += 1;
                currentNumber = ch - '0';
            }

            try posToNumberId.put(Pos{.row=row, .col=col}, numberId);

            // std.debug.print("number ID {d} => ({d}, {d})\n", .{numberId, row, col});
        } else {
            if (currentNumber) |num| {
                try idToNumber.put(numberId, num);
                // std.debug.print("number ID {d} is {d}\n", .{numberId, num});
                currentNumber = null;
            }
            if (ch == '\n') {
                row += 1;
                col = 0;
                continue;
            }
            if (ch == '*') {
                try possibleGears.append(Pos{.row=row, .col=col});
                // std.debug.print("possible gear {c} at ({d}, {d})\n", .{ch, row, col});
            }
        }
        col += 1;
    }
    
    var sum: usize = 0;

    var neighbors = [_]i32{-1, 0, 1};
    for (possibleGears.items) |pos| {
        var partNumberIdSet = std.AutoHashMap(usize, void).init(allocator);
        defer partNumberIdSet.deinit();

        for (neighbors) |dr| {
            for (neighbors) |dc| {
                var checkPos = Pos{.row=pos.row+dr, .col=pos.col+dc};
                if (posToNumberId.get(checkPos)) |partNumberId| {
                    try partNumberIdSet.put(partNumberId, {});
                    // std.debug.print("number id {d} at ({d}, {d})\n", .{partNumberId, checkPos.row, checkPos.col});
                }

            }
        }
        if (partNumberIdSet.count() == 2) {
            var iter = partNumberIdSet.keyIterator();
            var gearRatio: usize = 1;
            while (iter.next()) |partNumberId| {
                var part = idToNumber.get(partNumberId.*).?;
                gearRatio *= part;
            }
            // std.debug.print("gearRatio {d}\n", .{gearRatio});
            sum += gearRatio;
        }
    }
    std.debug.print("sum {d}\n", .{sum});
}
