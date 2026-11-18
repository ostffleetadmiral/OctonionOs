const std = @import("std");

pub const CORE_SIDE: i32 = 15;
pub const SHELL_SIDE: i32 = 16;
pub const CORE_VOLUME: u32 = 3_375;
pub const SHELL_VOLUME: u32 = 4_096;
pub const SHELL_CELL_COUNT: u32 = SHELL_VOLUME - CORE_VOLUME;
pub const MAX_TIER_SIDE: i32 = 128;

pub const ScalingTier = struct {
    qbits: u16,
    dimensions: u16,
    universes: u32,
    base_side: i32,
    padded_side: i32,
    counts_are_supplied_metadata: bool = true,
};

pub const LadderShell = struct {
    dimension: u8,
    designation: []const u8,
    algebra: []const u8,
    padding_side: i32,
    status: enum { model_metadata, unresolved },
};

pub const LADDER_SHELLS = [_]LadderShell{
    .{ .dimension = 9, .designation = "e9", .algebra = "anti-octonion / quantum foam wrapper", .padding_side = SHELL_SIDE, .status = .model_metadata },
    .{ .dimension = 10, .designation = "dual bi-complex", .algebra = "touching-shell compound seam", .padding_side = 0, .status = .unresolved },
};

pub const MAX_PLACEMENTS: usize = 512;
pub const MAX_SEAM_CONTACTS: usize = MAX_PLACEMENTS * (MAX_PLACEMENTS - 1) / 2;

pub const TIERS = [_]ScalingTier{
    .{ .qbits = 1, .dimensions = 8, .universes = 1, .base_side = 15, .padded_side = 16 },
    .{ .qbits = 2, .dimensions = 16, .universes = 8, .base_side = 30, .padded_side = 32 },
    .{ .qbits = 4, .dimensions = 32, .universes = 64, .base_side = 60, .padded_side = 64 },
    .{ .qbits = 8, .dimensions = 64, .universes = 512, .base_side = 120, .padded_side = 128 },
};

pub const Axis = enum(u2) { x, y, z };
pub const PaddingDirection = enum(u1) { negative, positive };
pub const ContactKind = enum(u1) { face_adjacent, shared_cell };
pub const FacingSide = enum(u1) { negative, positive };
pub const SeamConvention = enum(u1) { container_face, shared_core_cell };

pub const Point3 = struct {
    x: i32,
    y: i32,
    z: i32,

    pub fn get(self: Point3, axis: Axis) i32 {
        return switch (axis) {
            .x => self.x,
            .y => self.y,
            .z => self.z,
        };
    }

    pub fn set(self: *Point3, axis: Axis, value: i32) void {
        switch (axis) {
            .x => self.x = value,
            .y => self.y = value,
            .z => self.z = value,
        }
    }
};

pub const Bounds3 = struct {
    min: Point3,
    max: Point3,

    pub fn overlaps(a: Bounds3, b: Bounds3) bool {
        return overlaps1d(a.min.x, a.max.x, b.min.x, b.max.x) and
            overlaps1d(a.min.y, a.max.y, b.min.y, b.max.y) and
            overlaps1d(a.min.z, a.max.z, b.min.z, b.max.z);
    }

    pub fn contains(self: Bounds3, point: Point3) bool {
        return point.x >= self.min.x and point.x <= self.max.x and
            point.y >= self.min.y and point.y <= self.max.y and
            point.z >= self.min.z and point.z <= self.max.z;
    }
};

fn overlaps1d(a_min: i32, a_max: i32, b_min: i32, b_max: i32) bool {
    return a_min <= b_max and a_max >= b_min;
}

pub const ShellMetadata = struct {
    inner_side: i32 = CORE_SIDE,
    outer_side: i32 = SHELL_SIDE,
    core_volume: u32 = CORE_VOLUME,
    container_volume: u32 = SHELL_VOLUME,
    sparse_added_cell_count: u32 = SHELL_CELL_COUNT,
    selected_wall_planes_per_axis: u8 = 1,
    selected_face_cell_count: u32 = 3 * SHELL_SIDE * SHELL_SIDE,
    selected_face_unique_cell_count: u32 = 3 * SHELL_SIDE * SHELL_SIDE - 3 * SHELL_SIDE + 1,
    algebraic_label: []const u8 = "e9",
    boundary_semantics: []const u8 = "sparse shell boundary; transfer behavior unspecified",
    state_transfer_defined: bool = false,

    pub fn validate(self: ShellMetadata) bool {
        return self.inner_side == CORE_SIDE and
            self.outer_side == SHELL_SIDE and
            self.core_volume == CORE_VOLUME and
            self.container_volume == SHELL_VOLUME and
            self.sparse_added_cell_count == SHELL_CELL_COUNT and
            self.selected_wall_planes_per_axis == 1 and
            self.selected_face_cell_count == 3 * SHELL_SIDE * SHELL_SIDE and
            self.selected_face_unique_cell_count == 3 * SHELL_SIDE * SHELL_SIDE - 3 * SHELL_SIDE + 1 and
            self.selected_face_unique_cell_count == SHELL_CELL_COUNT and
            std.mem.eql(u8, self.algebraic_label, "e9") and
            !self.state_transfer_defined;
    }
};

pub fn tierIndex(tier: ScalingTier) ?usize {
    for (TIERS, 0..) |candidate, index| {
        if (std.meta.eql(candidate, tier)) return index;
    }
    return null;
}

pub fn cubeCount(side: i32) ?u32 {
    if (side < 0) return null;
    const n: u64 = @intCast(side);
    const volume = n * n * n;
    if (volume > std.math.maxInt(u32)) return null;
    return @intCast(volume);
}

pub fn nextPowerOfTwo(value: i32) ?i32 {
    if (value <= 0 or value > MAX_TIER_SIDE) return null;
    var result: i32 = 1;
    while (result < value) result *= 2;
    return result;
}

pub fn validateTier(tier: ScalingTier) bool {
    if (!tier.counts_are_supplied_metadata or tier.base_side <= 0) return false;
    if (@rem(tier.base_side, CORE_SIDE) != 0) return false;
    return nextPowerOfTwo(tier.base_side) == tier.padded_side;
}

pub fn validateAllTiers() bool {
    if (cubeCount(CORE_SIDE) != CORE_VOLUME or cubeCount(SHELL_SIDE) != SHELL_VOLUME) return false;
    for (TIERS) |tier| {
        if (!validateTier(tier)) return false;
    }
    return SHELL_VOLUME - CORE_VOLUME == SHELL_CELL_COUNT;
}

pub const CorePlacement = struct {
    id: u16,
    container_origin: Point3,
    padding: [3]PaddingDirection,

    pub fn coreBounds(self: CorePlacement) ?Bounds3 {
        var min = self.container_origin;
        var max = self.container_origin;
        for (0..3) |axis_index| {
            const axis: Axis = @enumFromInt(axis_index);
            const direction = self.padding[axis_index];
            const start = self.container_origin.get(axis);
            const core_start = if (direction == .negative)
                std.math.add(i32, start, 1) catch return null
            else
                start;
            const core_end = std.math.add(i32, core_start, CORE_SIDE - 1) catch return null;
            min.set(axis, core_start);
            max.set(axis, core_end);
        }
        return .{ .min = min, .max = max };
    }

    pub fn containerBounds(self: CorePlacement) ?Bounds3 {
        var min = self.container_origin;
        var max = self.container_origin;
        for (0..3) |axis_index| {
            const axis: Axis = @enumFromInt(axis_index);
            const start = self.container_origin.get(axis);
            min.set(axis, start);
            max.set(axis, std.math.add(i32, start, SHELL_SIDE - 1) catch return null);
        }
        return .{ .min = min, .max = max };
    }

    pub fn coreBoundsGlobal(self: CorePlacement) ?Bounds3 {
        return self.coreBounds();
    }

    pub fn containerBoundsGlobal(self: CorePlacement) ?Bounds3 {
        return self.containerBounds();
    }

    pub fn shellCellsOnAxis(self: CorePlacement, axis: Axis) ?Bounds3 {
        const container = self.containerBounds() orelse return null;
        const core = self.coreBounds() orelse return null;
        const added = if (paddingOn(self, axis) == .positive)
            std.math.add(i32, core.max.get(axis), 1) catch return null
        else
            std.math.sub(i32, core.min.get(axis), 1) catch return null;
        var min = container.min;
        var max = container.max;
        min.set(axis, added);
        max.set(axis, added);
        return .{ .min = min, .max = max };
    }

    pub fn localCoreIndexForAxis(self: CorePlacement, axis: Axis, signed_coordinate: i8) ?u5 {
        return self.localCoreIndexOnAxis(axis, signed_coordinate);
    }

    pub fn localCoreIndex3(self: CorePlacement, signed_coordinate: Point3) ?Point3 {
        if (signed_coordinate.x < -7 or signed_coordinate.x > 7 or
            signed_coordinate.y < -7 or signed_coordinate.y > 7 or
            signed_coordinate.z < -7 or signed_coordinate.z > 7) return null;
        return .{
            .x = self.localCoreIndexOnAxis(.x, @intCast(signed_coordinate.x)) orelse return null,
            .y = self.localCoreIndexOnAxis(.y, @intCast(signed_coordinate.y)) orelse return null,
            .z = self.localCoreIndexOnAxis(.z, @intCast(signed_coordinate.z)) orelse return null,
        };
    }

    pub fn globalContainerIndex(self: CorePlacement, signed_coordinate: Point3) ?Point3 {
        const local = self.localCoreIndex3(signed_coordinate) orelse return null;
        return .{
            .x = std.math.add(i32, self.container_origin.x, local.x) catch return null,
            .y = std.math.add(i32, self.container_origin.y, local.y) catch return null,
            .z = std.math.add(i32, self.container_origin.z, local.z) catch return null,
        };
    }

    pub fn localCoreIndexOnAxis(self: CorePlacement, axis: Axis, signed_coordinate: i8) ?u5 {
        if (signed_coordinate < -7 or signed_coordinate > 7) return null;
        const offset: i32 = if (paddingOn(self, axis) == .negative) 1 else 0;
        return @intCast(@as(i32, signed_coordinate) + 7 + offset);
    }

    pub fn trueOriginLocalIndex(self: CorePlacement) [3]u5 {
        return .{
            if (self.padding[0] == .negative) 8 else 7,
            if (self.padding[1] == .negative) 8 else 7,
            if (self.padding[2] == .negative) 8 else 7,
        };
    }

    pub fn globalCoreOrigin(self: CorePlacement) ?Point3 {
        return self.globalContainerIndex(.{ .x = 0, .y = 0, .z = 0 });
    }

    pub fn validateArithmetic(self: CorePlacement) bool {
        return self.coreBounds() != null and self.containerBounds() != null and
            self.globalCoreOrigin() != null and self.localCoreIndexOnAxis(.x, 7) != null and
            self.localCoreIndexOnAxis(.y, -7) != null and self.localCoreIndexOnAxis(.z, 0) != null;
    }
};

pub const SeamContact = struct {
    core_a: u16,
    core_b: u16,
    axis: Axis,
    interface_plane: i32,
    side_a: FacingSide = .positive,
    side_b: FacingSide = .negative,
    kind: ContactKind = .face_adjacent,
    convention: SeamConvention = .container_face,
};

pub const PlacementError = error{
    TooManyPlacements,
    InvalidTier,
    DuplicateCoreId,
    CoreOutOfTierBounds,
    CoreInteriorOverlap,
    ShellContainerOverlap,
    UnknownCoreId,
    InvalidSeamContact,
    NonComplementaryOrientation,
    InvalidGlobalBounds,
};

pub fn validatePlacements(tier: ScalingTier, placements: []const CorePlacement) PlacementError!void {
    if (!validateTier(tier)) return error.InvalidTier;
    if (placements.len > MAX_PLACEMENTS) return error.TooManyPlacements;

    _ = tierIndex(tier) orelse return error.InvalidTier;
    const global_frame = tierGlobalBounds(tier);
    const tier_min = global_frame.min.x;
    const tier_max = global_frame.max.x;
    for (placements, 0..) |placement, i| {
        if (!placement.validateArithmetic()) return error.CoreOutOfTierBounds;
        const core_bounds = placement.coreBounds() orelse return error.CoreOutOfTierBounds;
        const shell_bounds = placement.containerBounds() orelse return error.CoreOutOfTierBounds;
        for (placements[0..i]) |previous| {
            if (placement.id == previous.id) return error.DuplicateCoreId;
            const previous_core = previous.coreBounds() orelse return error.CoreOutOfTierBounds;
            const previous_shell = previous.containerBounds() orelse return error.CoreOutOfTierBounds;
            if (core_bounds.overlaps(previous_core)) return error.CoreInteriorOverlap;
            if (shell_bounds.overlaps(previous_shell)) return error.ShellContainerOverlap;
        }
        if (!inBounds(core_bounds, global_frame) or !inBounds(shell_bounds, global_frame) or
            !inTier(core_bounds, tier_min, tier_max) or !inTier(shell_bounds, tier_min, tier_max)) return error.CoreOutOfTierBounds;
    }
}

pub fn tierGlobalBounds(tier: ScalingTier) Bounds3 {
    const min: i32 = 0;
    const max = tier.padded_side - 1;
    return .{ .min = .{ .x = min, .y = min, .z = min }, .max = .{ .x = max, .y = max, .z = max } };
}

fn inBounds(bounds: Bounds3, container: Bounds3) bool {
    return container.contains(bounds.min) and container.contains(bounds.max);
}

fn inTier(bounds: Bounds3, min: i32, max: i32) bool {
    return bounds.min.x >= min and bounds.min.y >= min and bounds.min.z >= min and
        bounds.max.x <= max and bounds.max.y <= max and bounds.max.z <= max;
}

fn findPlacement(placements: []const CorePlacement, id: u16) ?CorePlacement {
    for (placements) |placement| {
        if (placement.id == id) return placement;
    }
    return null;
}

fn validAxis(axis: Axis) bool {
    return @intFromEnum(axis) <= @intFromEnum(Axis.z);
}

fn paddingOn(placement: CorePlacement, axis: Axis) PaddingDirection {
    return placement.padding[@intFromEnum(axis)];
}

pub fn validateSeamContacts(placements: []const CorePlacement, contacts: []const SeamContact) PlacementError!void {
    if (contacts.len > MAX_SEAM_CONTACTS) return error.TooManyPlacements;
    for (contacts) |contact| {
        if (contact.core_a == contact.core_b) return error.InvalidSeamContact;
        const a = findPlacement(placements, contact.core_a) orelse return error.UnknownCoreId;
        const b = findPlacement(placements, contact.core_b) orelse return error.UnknownCoreId;
        const a_core = a.coreBounds() orelse return error.InvalidSeamContact;
        const b_core = b.coreBounds() orelse return error.InvalidSeamContact;
        switch (contact.kind) {
            .face_adjacent => {
                if (contact.convention != .container_face) return error.InvalidSeamContact;
                const a_container = a.containerBounds() orelse return error.InvalidSeamContact;
                const b_container = b.containerBounds() orelse return error.InvalidSeamContact;
                if (!validAxis(contact.axis)) return error.InvalidSeamContact;
                const a_is_lower = a_container.min.get(contact.axis) < b_container.min.get(contact.axis);
                const lower_max = if (a_is_lower) a_container.max.get(contact.axis) else b_container.max.get(contact.axis);
                const upper_min = if (a_is_lower) b_container.min.get(contact.axis) else a_container.min.get(contact.axis);
                if (lower_max == std.math.maxInt(i32) or upper_min != lower_max + 1) return error.InvalidSeamContact;
                if (contact.interface_plane != lower_max) return error.InvalidSeamContact;
                if (!tangentialOverlap(a_container, b_container, contact.axis)) return error.InvalidSeamContact;
                if (!complementaryFaces(a, b, contact.axis, a_is_lower, contact.side_a, contact.side_b)) return error.NonComplementaryOrientation;
                if (a_core.overlaps(b_core)) return error.CoreInteriorOverlap;
            },
            .shared_cell => {
                if (contact.convention != .shared_core_cell) return error.InvalidSeamContact;
                if (!validAxis(contact.axis)) return error.InvalidSeamContact;
                if (!tangentialOverlap(a_core, b_core, contact.axis)) return error.InvalidSeamContact;
                if (!a_core.overlaps(b_core)) return error.InvalidSeamContact;
                if (!planeInOverlap(a_core, b_core, contact.axis, contact.interface_plane)) return error.InvalidSeamContact;
            },
        }
    }
}

fn complementaryFaces(
    a: CorePlacement,
    b: CorePlacement,
    axis: Axis,
    a_is_lower: bool,
    side_a: FacingSide,
    side_b: FacingSide,
) bool {
    const expected_a = if (a_is_lower) FacingSide.positive else FacingSide.negative;
    const expected_b = if (a_is_lower) FacingSide.negative else FacingSide.positive;
    if (side_a != expected_a or side_b != expected_b) return false;
    const a_padding = paddingOn(a, axis);
    const b_padding = paddingOn(b, axis);
    return (a_padding == .positive) == (side_a == .positive) and
        (b_padding == .positive) == (side_b == .positive);
}

fn tangentialOverlap(ab: Bounds3, bb: Bounds3, axis: Axis) bool {
    return switch (axis) {
        .x => overlaps1d(ab.min.y, ab.max.y, bb.min.y, bb.max.y) and overlaps1d(ab.min.z, ab.max.z, bb.min.z, bb.max.z),
        .y => overlaps1d(ab.min.x, ab.max.x, bb.min.x, bb.max.x) and overlaps1d(ab.min.z, ab.max.z, bb.min.z, bb.max.z),
        .z => overlaps1d(ab.min.x, ab.max.x, bb.min.x, bb.max.x) and overlaps1d(ab.min.y, ab.max.y, bb.min.y, bb.max.y),
    };
}

fn planeInOverlap(a: Bounds3, b: Bounds3, axis: Axis, plane: i32) bool {
    const low = @max(a.min.get(axis), b.min.get(axis));
    const high = @min(a.max.get(axis), b.max.get(axis));
    return plane >= low and plane <= high;
}

test "tier registry and sparse wrapper arithmetic match supplied configuration" {
    try std.testing.expect(validateAllTiers());
    try std.testing.expectEqual(@as(u32, 721), SHELL_CELL_COUNT);
    try std.testing.expectEqual(@as(u32, 4_096), SHELL_VOLUME);
    const shell: ShellMetadata = .{};
    try std.testing.expect(shell.validate());
    try std.testing.expectEqual(@as(u32, 768), shell.selected_face_cell_count);
    try std.testing.expectEqual(@as(u32, 721), shell.selected_face_unique_cell_count);
    try std.testing.expectEqual(@as(i32, 16), nextPowerOfTwo(15).?);
    try std.testing.expectEqual(@as(i32, 32), nextPowerOfTwo(30).?);
    try std.testing.expectEqual(@as(i32, 64), nextPowerOfTwo(60).?);
    try std.testing.expectEqual(@as(i32, 128), nextPowerOfTwo(120).?);
}

test "corner padding maps signed core and primary origin for all orientation masks" {
    for (0..8) |mask| {
        const direction = [_]PaddingDirection{
            if (mask & 1 == 0) .positive else .negative,
            if (mask & 2 == 0) .positive else .negative,
            if (mask & 4 == 0) .positive else .negative,
        };
        const placement = CorePlacement{ .id = 1, .container_origin = .{ .x = 0, .y = 0, .z = 0 }, .padding = direction };
        const core_bounds = placement.coreBounds().?;
        const container_bounds = placement.containerBounds().?;
        const origin = placement.trueOriginLocalIndex();
        for (0..3) |axis_index| {
            const expected: u5 = if (direction[axis_index] == .negative) 8 else 7;
            try std.testing.expectEqual(expected, origin[axis_index]);
        }
        try std.testing.expectEqual(@as(i32, 16), container_bounds.max.x - container_bounds.min.x + 1);
        try std.testing.expectEqual(@as(i32, 15), core_bounds.max.x - core_bounds.min.x + 1);
        for (0..3) |axis_index| {
            const axis: Axis = @enumFromInt(axis_index);
            try std.testing.expectEqual(@as(?u5, if (direction[axis_index] == .negative) 8 else 7), placement.localCoreIndexForAxis(axis, 0));
            try std.testing.expectEqual(@as(?u5, if (direction[axis_index] == .negative) 1 else 0), placement.localCoreIndexForAxis(axis, -7));
            try std.testing.expectEqual(@as(?u5, if (direction[axis_index] == .negative) 15 else 14), placement.localCoreIndexForAxis(axis, 7));
        }
        const global = placement.globalContainerIndex(.{ .x = 0, .y = 0, .z = 0 }).?;
        try std.testing.expectEqual(placement.container_origin.x + origin[0], global.x);
        try std.testing.expectEqual(placement.container_origin.y + origin[1], global.y);
        try std.testing.expectEqual(placement.container_origin.z + origin[2], global.z);
    }
}

test "corner shell bounds place added plane on selected wall" {
    const positive = CorePlacement{ .id = 1, .container_origin = .{ .x = 10, .y = 20, .z = 30 }, .padding = .{ .positive, .positive, .positive } };
    const negative = CorePlacement{ .id = 2, .container_origin = .{ .x = 10, .y = 20, .z = 30 }, .padding = .{ .negative, .negative, .negative } };
    try std.testing.expectEqual(@as(i32, 10), positive.coreBounds().?.min.x);
    try std.testing.expectEqual(@as(i32, 24), positive.coreBounds().?.max.x);
    try std.testing.expectEqual(@as(i32, 25), positive.containerBounds().?.max.x);
    try std.testing.expectEqual(@as(i32, 10), negative.containerBounds().?.min.x);
    try std.testing.expectEqual(@as(i32, 11), negative.coreBounds().?.min.x);
    try std.testing.expectEqual(@as(?u5, 8), negative.localCoreIndexOnAxis(.x, 0));
    try std.testing.expectEqual(@as(?u5, 7), positive.localCoreIndexOnAxis(.y, 0));
    try std.testing.expectEqual(@as(i32, 25), positive.shellCellsOnAxis(.x).?.min.x);
}

test "face-adjacent placements permit independent tangential padding" {
    const placements = [_]CorePlacement{
        .{ .id = 1, .container_origin = .{ .x = 0, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } },
        .{ .id = 2, .container_origin = .{ .x = 16, .y = 0, .z = 0 }, .padding = .{ .negative, .negative, .negative } },
    };
    try validatePlacements(TIERS[1], &placements);
    const seam = [_]SeamContact{.{ .core_a = 1, .core_b = 2, .axis = .x, .interface_plane = 15 }};
    try validateSeamContacts(&placements, &seam);
    const wrong = [_]CorePlacement{
        placements[0],
        .{ .id = 2, .container_origin = .{ .x = 16, .y = 0, .z = 0 }, .padding = .{ .positive, .negative, .negative } },
    };
    try std.testing.expectError(error.NonComplementaryOrientation, validateSeamContacts(&wrong, &seam));
}

test "shell containers must not overlap even when core interiors do not" {
    const placements = [_]CorePlacement{
        .{ .id = 1, .container_origin = .{ .x = 0, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } },
        .{ .id = 2, .container_origin = .{ .x = 8, .y = 0, .z = 0 }, .padding = .{ .negative, .positive, .positive } },
    };
    try std.testing.expectError(error.CoreInteriorOverlap, validatePlacements(TIERS[3], &placements));
}

test "caller placements validate bounds, distinct cores and orientation-complementary seam" {
    const placements = [_]CorePlacement{
        .{ .id = 1, .container_origin = .{ .x = 0, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } },
        .{ .id = 2, .container_origin = .{ .x = 16, .y = 0, .z = 0 }, .padding = .{ .negative, .negative, .positive } },
    };
    try validatePlacements(TIERS[2], &placements);
    const seams = [_]SeamContact{.{ .core_a = 1, .core_b = 2, .axis = .x, .interface_plane = 15, .side_a = .positive, .side_b = .negative }};
    try validateSeamContacts(&placements, &seams);
    const wrong_parity = [_]CorePlacement{
        placements[0],
        .{ .id = 2, .container_origin = placements[1].container_origin, .padding = .{ .positive, .negative, .positive } },
    };
    try std.testing.expectError(error.NonComplementaryOrientation, validateSeamContacts(&wrong_parity, &seams));
}

test "placement validation rejects overlap, duplicate IDs and tier overflow" {
    const overlap = [_]CorePlacement{
        .{ .id = 1, .container_origin = .{ .x = 0, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } },
        .{ .id = 2, .container_origin = .{ .x = 3, .y = 0, .z = 0 }, .padding = .{ .negative, .positive, .positive } },
    };
    try std.testing.expectError(error.CoreInteriorOverlap, validatePlacements(TIERS[3], &overlap));
    const duplicate = [_]CorePlacement{
        .{ .id = 1, .container_origin = .{ .x = 0, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } },
        .{ .id = 1, .container_origin = .{ .x = 17, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } },
    };
    try std.testing.expectError(error.DuplicateCoreId, validatePlacements(TIERS[3], &duplicate));
    const outside = [_]CorePlacement{.{ .id = 1, .container_origin = .{ .x = 50, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } }};
    try std.testing.expectError(error.CoreOutOfTierBounds, validatePlacements(TIERS[1], &outside));
    const overflow = [_]CorePlacement{.{ .id = 2, .container_origin = .{ .x = std.math.maxInt(i32), .y = 0, .z = 0 }, .padding = .{ .negative, .positive, .positive } }};
    try std.testing.expectError(error.CoreOutOfTierBounds, validatePlacements(TIERS[3], &overflow));
}

test "seam validation rejects invalid core references and axis geometry" {
    const placements = [_]CorePlacement{
        .{ .id = 1, .container_origin = .{ .x = 0, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } },
        .{ .id = 2, .container_origin = .{ .x = 16, .y = 0, .z = 0 }, .padding = .{ .negative, .negative, .positive } },
    };
    const unknown = [_]SeamContact{.{ .core_a = 1, .core_b = 9, .axis = .x, .interface_plane = 15 }};
    try std.testing.expectError(error.UnknownCoreId, validateSeamContacts(&placements, &unknown));
    const wrong_plane = [_]SeamContact{.{ .core_a = 1, .core_b = 2, .axis = .x, .interface_plane = 14 }};
    try std.testing.expectError(error.InvalidSeamContact, validateSeamContacts(&placements, &wrong_plane));
}
