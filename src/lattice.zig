const std = @import("std");
const octonion = @import("octonion.zig");

pub const SIDE: usize = 15;
pub const LAYERS: usize = SIDE;
pub const NODE_COUNT: usize = SIDE * SIDE * SIDE;
pub const SLICE_NODE_COUNT: usize = SIDE * SIDE;
pub const COORD_MIN: i8 = -7;
pub const COORD_MAX: i8 = 7;
pub const DEFECT_COUNT: u8 = 7;
pub const PHASE_STEPS_PER_CYCLE: u8 = 8;

pub const PhaseConvention = enum(u8) {
    quarter_turn_per_transit = 1,
    three_quarter_turn_per_transit = 3,

    pub fn incrementEighthTurns(self: PhaseConvention) u3 {
        return @intCast(@intFromEnum(self));
    }
};

/// Declared contract choice v1, selected by source spec: the Module-2
/// engineering directive (recorded in `1.md`) specifies "geometric
/// phase accumulation of 3π/4 per transit with closure at 8 transits" —
/// 3π/4 = 3 eighth-turns, i.e. `.three_quarter_turn_per_transit`.
/// `.quarter_turn_per_transit` (+1, the minimal generator of Z/8) is
/// retained as the covering-preimage variant: the +3 sequence is the
/// element-wise ×3 mod 8 image of the +1 sequence, and ×3 is not an
/// octonion automorphism, so label-coupled consumers can distinguish
/// the conventions. The choice is contract metadata (serialization
/// still requires an explicit convention), not a physical claim.
pub const CANONICAL_PHASE_CONVENTION: PhaseConvention = .three_quarter_turn_per_transit;

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

    pub fn transit(self: *Phase, convention: PhaseConvention) void {
        self.eighth_turns = @truncate((@as(u4, self.eighth_turns) + convention.incrementEighthTurns()) % PHASE_STEPS_PER_CYCLE);
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

    /// Canonical cell label in signed True-Origin coordinates. The center
    /// of the 15^3 lattice maps to array index (7, 7, 7).
    pub fn labelAtSigned(self: *const Lattice, coord: Coord) ?u3 {
        const flat = index(coord) orelse return null;
        return self.labels[flat];
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
        if (self.labelAtSigned(.{ .x = 0, .y = 0, .z = 0 }) != 0) return false;
        if (!self.hasLayerMirrorSymmetry()) return false;
        const counts = self.labelCounts();
        if (counts[0] != 421) return false;
        for (counts[1..]) |count| {
            if (count != 422) return false;
        }
        return self.cardinalAxesCoverImaginaryLabels();
    }

    /// Exact e0..e7 population census for this lattice instance.
    pub fn labelCounts(self: *const Lattice) [8]usize {
        var counts = [_]usize{0} ** 8;
        for (self.labels) |label| counts[label] += 1;
        return counts;
    }

    /// Check the signed coordinate/index bijection and the complete z-slice
    /// mirror invariant for this instance.
    pub fn hasCanonicalCoordinatesAndMirrors(self: *const Lattice) bool {
        for (0..NODE_COUNT) |flat| {
            const coord = coordFromIndex(flat) orelse return false;
            if (index(coord) != flat) return false;
        }
        return self.hasLayerMirrorSymmetry();
    }

    pub fn hasCanonicalLabels(self: *const Lattice) bool {
        const expected = Lattice.init();
        return std.mem.eql(u3, &self.labels, &expected.labels);
    }
};

fn inBounds(value: i8) bool {
    return value >= COORD_MIN and value <= COORD_MAX;
}

test "lattice stores 3375 Fano labels and exactly 421 e0 entries" {
    const lattice = Lattice.init();
    try std.testing.expectEqual(NODE_COUNT, lattice.labels.len);
    try std.testing.expectEqual(@as(usize, 421), lattice.countLabel(0));
    try std.testing.expectEqual([_]usize{ 421, 422, 422, 422, 422, 422, 422, 422 }, lattice.labelCounts());
    try std.testing.expect(lattice.validate());
}

test "signed coordinate and flat-index conversion round trip" {
    for (0..NODE_COUNT) |flat| {
        const coord = Lattice.coordFromIndex(flat).?;
        try std.testing.expectEqual(flat, Lattice.index(coord).?);
    }
    try std.testing.expectEqual(@as(usize, 7 * SLICE_NODE_COUNT + 7 * SIDE + 7), Lattice.index(.{ .x = 0, .y = 0, .z = 0 }).?);
    try std.testing.expect(Lattice.index(.{ .x = 8, .y = 0, .z = 0 }) == null);
    const lattice = Lattice.init();
    try std.testing.expect(lattice.hasCanonicalCoordinatesAndMirrors());
    try std.testing.expectEqual(@as(?u3, 0), lattice.labelAtSigned(.{ .x = 0, .y = 0, .z = 0 }));
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
    try std.testing.expect(lattice.hasCanonicalLabels());
}

test "validation rejects mutations to the canonical origin and label census" {
    var lattice = Lattice.init();
    lattice.labels[Lattice.indexUnsigned(7, 7, 7)] = 1;
    try std.testing.expect(!lattice.validate());

    lattice = Lattice.init();
    lattice.labels[Lattice.indexUnsigned(0, 0, 0)] = 0;
    try std.testing.expect(!lattice.validate());
}

test "six cardinal rays cover all seven imaginary Fano labels" {
    const lattice = Lattice.init();
    try std.testing.expect(lattice.cardinalAxesCoverImaginaryLabels());
}

test "phase conventions are explicit and each closes after eight transits" {
    const cases = [_]struct { convention: PhaseConvention, expected: [8]u3 }{
        .{ .convention = .quarter_turn_per_transit, .expected = .{ 1, 2, 3, 4, 5, 6, 7, 0 } },
        .{ .convention = .three_quarter_turn_per_transit, .expected = .{ 3, 6, 1, 4, 7, 2, 5, 0 } },
    };
    for (cases) |case| {
        var phase = Phase{};
        var visited = [_]bool{false} ** 8;
        for (case.expected, 0..) |expected, step| {
            phase.transit(case.convention);
            try std.testing.expectEqual(expected, phase.eighth_turns);
            if (step != 7) {
                try std.testing.expect(!visited[expected]);
                visited[expected] = true;
            }
        }
        try std.testing.expectEqual(@as(u3, 0), phase.eighth_turns);
        try std.testing.expect(!visited[0]);
        for (visited[1..]) |seen| try std.testing.expect(seen);
    }
}

fn sigma3(position: u3) u3 {
    return @intCast((@as(u8, position) *% 3) % PHASE_STEPS_PER_CYCLE);
}

test "three-quarter sequence is the sigma3 relabeling of the quarter-turn sequence" {
    var canonical = Phase{};
    var dual = Phase{};
    for (0..PHASE_STEPS_PER_CYCLE) |_| {
        canonical.transit(.quarter_turn_per_transit);
        dual.transit(.three_quarter_turn_per_transit);
        try std.testing.expectEqual(sigma3(canonical.eighth_turns), dual.eighth_turns);
    }
}

test "sigma3 relabeling is not an octonion automorphism" {
    // sigma fixes e0 and permutes the imaginary units; if it were an
    // algebra automorphism it would preserve products. It does not:
    // sigma(e1 * e2) = sigma(e3) = e1, but sigma(e1) * sigma(e2) =
    // e3 * e6 = e5.
    const product = octonion.multiply(@intCast(sigma3(1)), @intCast(sigma3(2)));
    try std.testing.expectEqual(@as(octonion.Unit, 5), product.unit);
    try std.testing.expectEqual(@as(octonion.Unit, 1), sigma3(3));
    try std.testing.expect(product.unit != sigma3(3));
}

test "both phase conventions share cycle invariants" {
    const conventions = [_]PhaseConvention{ .quarter_turn_per_transit, .three_quarter_turn_per_transit };
    for (conventions) |convention| {
        var phase = Phase{};
        var previous: ?u3 = null;
        for (0..PHASE_STEPS_PER_CYCLE) |step| {
            phase.transit(convention);
            if (previous) |prior| {
                try std.testing.expect((@as(u8, prior) ^ @as(u8, phase.eighth_turns)) & 1 == 1);
            }
            previous = phase.eighth_turns;
            if (step + 1 == 4) try std.testing.expectEqual(@as(u3, 4), phase.eighth_turns);
        }
        try std.testing.expectEqual(@as(u3, 0), phase.eighth_turns);
    }
}

test "canonical phase convention matches the Module-2 spec increment" {
    try std.testing.expectEqual(PhaseConvention.three_quarter_turn_per_transit, CANONICAL_PHASE_CONVENTION);
    try std.testing.expectEqual(@as(u3, 3), CANONICAL_PHASE_CONVENTION.incrementEighthTurns());
    var phase = Phase{};
    for (0..4) |_| phase.transit(CANONICAL_PHASE_CONVENTION);
    try std.testing.expectEqual(@as(u3, 4), phase.eighth_turns);
}

test "7-defect metadata is explicit and arithmetically defined" {
    const metadata = DefectMetadata{};
    try std.testing.expectEqual(@as(u8, 7), metadata.count);
    try std.testing.expectEqual(metadata.count, metadata.source_identity);
    try std.testing.expect(!metadata.placement_defined);
}
