const std = @import("std");
const lattice_mod = @import("lattice.zig");

pub const State = struct {
    amplitudes: [lattice_mod.NODE_COUNT]i8,

    pub fn basis(flat_index: usize) error{InvalidBasisIndex}!State {
        if (flat_index >= lattice_mod.NODE_COUNT) return error.InvalidBasisIndex;
        var state = State{ .amplitudes = [_]i8{0} ** lattice_mod.NODE_COUNT };
        state.amplitudes[flat_index] = 1;
        return state;
    }

    pub fn normSquared(self: State) u32 {
        var norm: u32 = 0;
        for (self.amplitudes) |amplitude| {
            const value: i16 = amplitude;
            norm += @intCast(value * value);
        }
        return norm;
    }

    pub fn supportCount(self: State) usize {
        var count: usize = 0;
        for (self.amplitudes) |amplitude| count += @intFromBool(amplitude != 0);
        return count;
    }
};

pub const LocalEvolution = struct {
    lattice: *const lattice_mod.Lattice,

    pub fn apply(self: LocalEvolution, input: State, output: *State) error{InvalidState}!void {
        const source_state = input;
        output.* = .{ .amplitudes = [_]i8{0} ** lattice_mod.NODE_COUNT };
        for (0..lattice_mod.SIDE) |z| {
            for (0..lattice_mod.SIDE) |y| {
                for (0..lattice_mod.SIDE) |x| {
                    const source = lattice_mod.Lattice.indexUnsigned(x, y, z);
                    const amplitude = source_state.amplitudes[source];
                    if (amplitude == 0) continue;
                    const neighbors = [_]struct { x: isize, y: isize, z: isize }{
                        .{ .x = @as(isize, @intCast(x)) - 1, .y = @intCast(y), .z = @intCast(z) },
                        .{ .x = @as(isize, @intCast(x)) + 1, .y = @intCast(y), .z = @intCast(z) },
                        .{ .x = @intCast(x), .y = @as(isize, @intCast(y)) - 1, .z = @intCast(z) },
                        .{ .x = @intCast(x), .y = @as(isize, @intCast(y)) + 1, .z = @intCast(z) },
                        .{ .x = @intCast(x), .y = @intCast(y), .z = @as(isize, @intCast(z)) - 1 },
                        .{ .x = @intCast(x), .y = @intCast(y), .z = @as(isize, @intCast(z)) + 1 },
                    };

                    for (neighbors) |neighbor| {
                        if (neighbor.x < 0 or neighbor.x >= lattice_mod.SIDE or
                            neighbor.y < 0 or neighbor.y >= lattice_mod.SIDE or
                            neighbor.z < 0 or neighbor.z >= lattice_mod.SIDE) continue;
                        const nx: usize = @intCast(neighbor.x);
                        const ny: usize = @intCast(neighbor.y);
                        const nz: usize = @intCast(neighbor.z);
                        const destination = lattice_mod.Lattice.indexUnsigned(nx, ny, nz);
                        const label_delta = @as(i16, self.lattice.labels[destination]) -
                            @as(i16, self.lattice.labels[source]);
                        if (@mod(label_delta, 8) != 1) continue;
                        output.amplitudes[destination] = std.math.add(i8, output.amplitudes[destination], amplitude) catch return error.InvalidState;
                    }
                }
            }
        }
    }
};

test "single-site directed adjacency maps e0 to four neighbors and fails norm preservation" {
    const lattice = lattice_mod.Lattice.init();
    const origin = lattice_mod.Lattice.index(.{ .x = 0, .y = 0, .z = 0 }).?;
    const input = try State.basis(origin);
    var output: State = undefined;
    try (LocalEvolution{ .lattice = &lattice }).apply(input, &output);

    try std.testing.expectEqual(@as(u32, 1), input.normSquared());
    try std.testing.expectEqual(@as(usize, 1), input.supportCount());
    try std.testing.expectEqual(@as(usize, 4), output.supportCount());
    try std.testing.expectEqual(@as(u32, 4), output.normSquared());
    try std.testing.expectEqual(@as(u3, 0), lattice.labelAt(.{ .x = 0, .y = 0, .z = 0 }).?);
    try std.testing.expectEqual(@as(i8, 0), output.amplitudes[origin]);
    var expected_support: usize = 0;
    for ([_]lattice_mod.Coord{
        .{ .x = 1, .y = 0, .z = 0 },
        .{ .x = 0, .y = 1, .z = 0 },
        .{ .x = 0, .y = 0, .z = 1 },
        .{ .x = 0, .y = 0, .z = -1 },
    }) |coord| {
        const index = lattice_mod.Lattice.index(coord).?;
        const delta = @mod(@as(i16, lattice.labels[index]) - @as(i16, lattice.labels[origin]), 8);
        const admitted = delta == 1;
        try std.testing.expectEqual(@as(i8, @intFromBool(admitted)), output.amplitudes[index]);
        expected_support += @intFromBool(admitted);
        try std.testing.expectEqual(@as(u3, 1), lattice.labels[index]);
    }
    try std.testing.expectEqual(expected_support, output.supportCount());
    try std.testing.expectEqual(@as(usize, 4), expected_support);
}

test "directed label-admitted transitions are counted per axis" {
    const lattice = lattice_mod.Lattice.init();
    var admitted = [_]usize{0} ** 3;
    for (0..lattice_mod.NODE_COUNT) |source| {
        const source_coord = lattice_mod.Lattice.coordFromIndex(source).?;
        const candidates = [_]struct { coord: lattice_mod.Coord, axis: usize }{
            .{ .coord = .{ .x = source_coord.x -| 1, .y = source_coord.y, .z = source_coord.z }, .axis = 0 },
            .{ .coord = .{ .x = source_coord.x +| 1, .y = source_coord.y, .z = source_coord.z }, .axis = 0 },
            .{ .coord = .{ .x = source_coord.x, .y = source_coord.y -| 1, .z = source_coord.z }, .axis = 1 },
            .{ .coord = .{ .x = source_coord.x, .y = source_coord.y +| 1, .z = source_coord.z }, .axis = 1 },
            .{ .coord = .{ .x = source_coord.x, .y = source_coord.y, .z = source_coord.z -| 1 }, .axis = 2 },
            .{ .coord = .{ .x = source_coord.x, .y = source_coord.y, .z = source_coord.z +| 1 }, .axis = 2 },
        };
        for (candidates) |candidate| {
            const destination = lattice_mod.Lattice.index(candidate.coord) orelse continue;
            const delta = @mod(
                @as(i16, lattice.labels[destination]) - @as(i16, lattice.labels[source]),
                8,
            );
            if (delta == 1) admitted[candidate.axis] += 1;
        }
    }
    try std.testing.expectEqual([_]usize{ 3_150, 3_150, 3_150 }, admitted);
}

test "E0 mask local degree distribution is measured without normalization" {
    const lattice = lattice_mod.Lattice.init();
    var directed_count = [_]usize{0} ** 3;
    for (0..lattice_mod.NODE_COUNT) |source| {
        if (lattice.labels[source] != 0) continue;
        const coord = lattice_mod.Lattice.coordFromIndex(source).?;
        const neighbors = [_]struct { coord: lattice_mod.Coord, axis: usize }{
            .{ .coord = .{ .x = coord.x -| 1, .y = coord.y, .z = coord.z }, .axis = 0 },
            .{ .coord = .{ .x = coord.x +| 1, .y = coord.y, .z = coord.z }, .axis = 0 },
            .{ .coord = .{ .x = coord.x, .y = coord.y -| 1, .z = coord.z }, .axis = 1 },
            .{ .coord = .{ .x = coord.x, .y = coord.y +| 1, .z = coord.z }, .axis = 1 },
            .{ .coord = .{ .x = coord.x, .y = coord.y, .z = coord.z -| 1 }, .axis = 2 },
            .{ .coord = .{ .x = coord.x, .y = coord.y, .z = coord.z +| 1 }, .axis = 2 },
        };
        for (neighbors) |neighbor| {
            const destination = lattice_mod.Lattice.index(neighbor.coord) orelse continue;
            if (@mod(@as(i16, lattice.labels[destination]), 8) == 1) {
                directed_count[neighbor.axis] += 1;
            }
        }
    }

    try std.testing.expectEqual(@as(usize, 393), directed_count[0]);
    try std.testing.expectEqual(@as(usize, 393), directed_count[1]);
    try std.testing.expectEqual(@as(usize, 394), directed_count[2]);
    try std.testing.expectEqual(@as(usize, 1_180), directed_count[0] + directed_count[1] + directed_count[2]);
}

test "local evolution rejects non-unit basis-amplitude states" {
    const lattice = lattice_mod.Lattice.init();
    var input = try State.basis(0);
    input.amplitudes[0] = 2;
    var output: State = undefined;
    try (LocalEvolution{ .lattice = &lattice }).apply(input, &output);
    try std.testing.expect(output.normSquared() != input.normSquared());
}

test "local adjacency is linear for two independent basis inputs" {
    const lattice = lattice_mod.Lattice.init();
    const evolution = LocalEvolution{ .lattice = &lattice };
    const left_index = lattice_mod.Lattice.index(.{ .x = 0, .y = 0, .z = 0 }).?;
    const right_index = lattice_mod.Lattice.index(.{ .x = 0, .y = 0, .z = 7 }).?;
    var left = try State.basis(left_index);
    left.amplitudes[right_index] = 1;
    var output: State = undefined;

    try evolution.apply(left, &output);
    try std.testing.expectEqual(@as(u32, 2), left.normSquared());
    try std.testing.expectEqual(@as(u32, 6), output.normSquared());
}

test "local adjacency expands the central seven-site control" {
    const lattice = lattice_mod.Lattice.init();
    var input = State{ .amplitudes = [_]i8{0} ** lattice_mod.NODE_COUNT };
    const coordinates = [_]lattice_mod.Coord{
        .{ .x = 0, .y = 0, .z = 0 },
        .{ .x = 1, .y = 0, .z = 0 },
        .{ .x = -1, .y = 0, .z = 0 },
        .{ .x = 0, .y = 1, .z = 0 },
        .{ .x = 0, .y = -1, .z = 0 },
        .{ .x = 0, .y = 0, .z = 1 },
        .{ .x = 0, .y = 0, .z = -1 },
    };
    for (coordinates) |coord| {
        input.amplitudes[lattice_mod.Lattice.index(coord).?] = 1;
    }
    var output: State = undefined;

    try (LocalEvolution{ .lattice = &lattice }).apply(input, &output);
    try std.testing.expectEqual(@as(u32, 7), input.normSquared());
    try std.testing.expectEqual(@as(u32, 38), output.normSquared());
    try std.testing.expect(output.supportCount() > input.supportCount());
}
