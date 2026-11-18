const std = @import("std");

pub const SIDE: usize = 15;
pub const LAYERS: usize = SIDE;
pub const NODE_COUNT: usize = SIDE * SIDE * SIDE;
pub const SLICE_NODE_COUNT: usize = SIDE * SIDE;
pub const COORD_MIN: i8 = -7;
pub const COORD_MAX: i8 = 7;
pub const DEFECT_COUNT: u8 = 7;
pub const PHASE_STEPS_PER_CYCLE: u8 = 8;

pub const Coord = struct {
    x: i8,
    y: i8,
    z: i8,
};

pub const Layer = struct {
    index: u4,
    z: i8,
    pivot: u3,
    mirror_index: u4,
    is_central: bool,
};

pub const Phase = struct {
    eighth_turns: u3 = 0,

    pub fn transit(self: *Phase) void {
        self.eighth_turns = @truncate((@as(u4, self.eighth_turns) + 1) % PHASE_STEPS_PER_CYCLE);
    }
};

pub const DefectMetadata = struct {
    count: u8 = DEFECT_COUNT,
    source_identity: u8 = 2 * 2 * 2 - 1,
    placement_defined: bool = false,
};

pub const Lattice = struct {
    labels: [NODE_COUNT]u3,

    pub fn init() Lattice {
        var lattice: Lattice = .{ .labels = undefined };
        for (0..SIDE) |layer_index| {
            const layer_number: i32 = @intCast(layer_index + 1);
            const pivot: i32 = if (layer_number <= 8)
                @mod(8 - layer_number, 8)
            else
                @mod(layer_number - 8, 8);
            for (0..SIDE) |y| {
                const row_base = centeredStep(pivot, @as(i32, @intCast(y)) - 7);
                for (0..SIDE) |x| {
                    const label = centeredStep(row_base, @as(i32, @intCast(x)) - 7);
                    lattice.labels[indexUnsigned(x, y, layer_index)] = @intCast(label);
                }
            }
        }
        return lattice;
    }

    fn centeredStep(base: i32, offset: i32) i32 {
        return @mod(base + offset, 8);
    }

    pub fn indexUnsigned(x: usize, y: usize, z: usize) usize {
        return (z * SIDE + y) * SIDE + x;
    }

    pub fn index(coord: Coord) ?usize {
        if (!inBounds(coord.x) or !inBounds(coord.y) or !inBounds(coord.z)) return null;
        return indexUnsigned(
            @intCast(@as(i16, coord.x) + 7),
            @intCast(@as(i16, coord.y) + 7),
            @intCast(@as(i16, coord.z) + 7),
        );
    }

    pub fn coordFromIndex(flat: usize) ?Coord {
        if (flat >= NODE_COUNT) return null;
        const x: i16 = @intCast(flat % SIDE);
        const y: i16 = @intCast((flat / SIDE) % SIDE);
        const z: i16 = @intCast(flat / SLICE_NODE_COUNT);
        return .{
            .x = @intCast(x - 7),
            .y = @intCast(y - 7),
            .z = @intCast(z - 7),
        };
    }

    pub fn labelAt(self: *const Lattice, coord: Coord) ?u3 {
        const flat = index(coord) orelse return null;
        return self.labels[flat];
    }

    pub fn labelAtIndex(self: *const Lattice, x: usize, y: usize, z: usize) u3 {
        return self.labels[indexUnsigned(x, y, z)];
    }

    pub fn layer(self: *const Lattice, layer_index: usize) ?Layer {
        if (layer_index >= LAYERS) return null;
        const z: i8 = @intCast(@as(i16, @intCast(layer_index)) - 7);
        const mirror: usize = SIDE - 1 - layer_index;
        return .{
            .index = @intCast(layer_index),
            .z = z,
            .pivot = self.labelAtIndex(7, 7, layer_index),
            .mirror_index = @intCast(mirror),
            .is_central = layer_index == 7,
        };
    }

    pub fn countLabel(self: *const Lattice, label: u3) usize {
        var count: usize = 0;
        for (self.labels) |value| {
            if (value == label) count += 1;
        }
        return count;
    }

    pub fn hasLayerMirrorSymmetry(self: *const Lattice) bool {
        for (0..7) |layer_index| {
            const mirror = SIDE - 1 - layer_index;
            for (0..SLICE_NODE_COUNT) |slice_index| {
                const x = slice_index % SIDE;
                const y = slice_index / SIDE;
                if (self.labelAtIndex(x, y, layer_index) != self.labelAtIndex(x, y, mirror)) return false;
            }
        }
        return true;
    }

    pub fn cardinalAxesCoverImaginaryLabels(self: *const Lattice) bool {
        var seen = [_]bool{false} ** 8;
        for (1..8) |distance| {
            const d: i16 = @intCast(distance);
            const points = [_]Coord{
                .{ .x = @intCast(d), .y = 0, .z = 0 },
                .{ .x = @intCast(-d), .y = 0, .z = 0 },
                .{ .x = 0, .y = @intCast(d), .z = 0 },
                .{ .x = 0, .y = @intCast(-d), .z = 0 },
                .{ .x = 0, .y = 0, .z = @intCast(d) },
                .{ .x = 0, .y = 0, .z = @intCast(-d) },
            };
            for (points) |point| seen[self.labelAt(point).?] = true;
        }
        for (1..8) |label| {
            if (!seen[label]) return false;
        }
        return true;
    }

    pub fn validate(self: *const Lattice) bool {
        if (self.labels.len != NODE_COUNT) return false;
        if (self.labelAt(.{ .x = 0, .y = 0, .z = 0 }) == null) return false;
        return self.countLabel(0) == 421 and self.hasLayerMirrorSymmetry();
    }
};

fn inBounds(value: i8) bool {
    return value >= COORD_MIN and value <= COORD_MAX;
}

test "lattice stores 3375 Fano labels and exactly 421 e0 entries" {
    const lattice = Lattice.init();
    try std.testing.expectEqual(NODE_COUNT, lattice.labels.len);
    try std.testing.expectEqual(@as(usize, 421), lattice.countLabel(0));
    try std.testing.expect(lattice.validate());
}

test "signed coordinate and flat-index conversion round trip" {
    for (0..NODE_COUNT) |flat| {
        const coord = Lattice.coordFromIndex(flat).?;
        try std.testing.expectEqual(flat, Lattice.index(coord).?);
    }
    try std.testing.expectEqual(@as(usize, 7 * SLICE_NODE_COUNT + 7 * SIDE + 7), Lattice.index(.{ .x = 0, .y = 0, .z = 0 }).?);
    try std.testing.expect(Lattice.index(.{ .x = 8, .y = 0, .z = 0 }) == null);
}

test "origin and six cardinal endpoints are exactly radius seven" {
    const points = [_]Coord{
        .{ .x = 7, .y = 0, .z = 0 }, .{ .x = -7, .y = 0, .z = 0 },
        .{ .x = 0, .y = 7, .z = 0 }, .{ .x = 0, .y = -7, .z = 0 },
        .{ .x = 0, .y = 0, .z = 7 }, .{ .x = 0, .y = 0, .z = -7 },
    };
    const origin = Coord{ .x = 0, .y = 0, .z = 0 };
    for (points) |point| {
        const distance: i16 = @intCast(@abs(@as(i16, point.x) - origin.x) + @abs(@as(i16, point.y) - origin.y) + @abs(@as(i16, point.z) - origin.z));
        try std.testing.expectEqual(@as(i16, 7), distance);
        try std.testing.expect(Lattice.index(point) != null);
    }
}

test "layer pivots and mirror state match the translated Fano tensor" {
    const lattice = Lattice.init();
    const expected = [_]u3{ 7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7 };
    for (expected, 0..) |pivot, layer_index| {
        const layer_value = lattice.layer(layer_index).?;
        try std.testing.expectEqual(pivot, layer_value.pivot);
        try std.testing.expectEqual(@as(i8, @intCast(@as(i16, @intCast(layer_index)) - 7)), layer_value.z);
        try std.testing.expectEqual(@as(usize, 14 - layer_index), layer_value.mirror_index);
        try std.testing.expectEqual(layer_index == 7, layer_value.is_central);
    }
    try std.testing.expect(lattice.hasLayerMirrorSymmetry());
}

test "six cardinal rays cover all seven imaginary Fano labels" {
    const lattice = Lattice.init();
    try std.testing.expect(lattice.cardinalAxesCoverImaginaryLabels());
}

test "phase advances one eighth turn and closes after eight transits" {
    var phase = Phase{};
    for (1..8) |step| {
        phase.transit();
        try std.testing.expectEqual(@as(u3, @intCast(step)), phase.eighth_turns);
    }
    phase.transit();
    try std.testing.expectEqual(@as(u3, 0), phase.eighth_turns);
}

test "7-defect metadata is explicit and arithmetically defined" {
    const metadata = DefectMetadata{};
    try std.testing.expectEqual(@as(u8, 7), metadata.count);
    try std.testing.expectEqual(metadata.count, metadata.source_identity);
    try std.testing.expect(!metadata.placement_defined);
}
