// φ/π dimensional-position contract v1 — declared positional semantics.
//
// User-supplied positioning (recorded in CYBER-PHYSICS.md and the
// audit ledger): π is centered at E0 (the geometric origin / True-
// Origin site); the state's 1D φ coordinate is carried inward along
// all six cardinal directions (±X, ±Y, ±Z); beyond the interior
// boundary the exterior scales by φ. EU/MOUND donors assign c(1)=φ to
// the 1D timeline and c(2)=π to the 2D phase space.
//
// Compounding law (user-supplied): the 16³ domain matters ONLY when
// compounding. On the bare 15³ lattice the shell coordinates have no
// interactions; the +1 shell is added to every 15³ precisely when
// scaling/compounding tiers. The shell sites below are that compounding
// layer — inert boundary medium on the bare lattice, active only in
// scaled configurations.
//
// This module encodes POSITION ONLY: which constant-role each domain
// site carries and which way the φ field points. It does not assign
// magnitudes, does not evolve the state, and does not bridge position
// to equations — that derivation remains the open elevation path.

const std = @import("std");

pub const DOMAIN_SIDE: usize = 16;
pub const DOMAIN_SITES: usize = DOMAIN_SIDE * DOMAIN_SIDE * DOMAIN_SIDE;
pub const INTERIOR_SIDE: usize = 15;
pub const CENTER: usize = 7;
pub const CARDINAL_RAY_SITES: usize = 42;

/// Unsigned domain coordinate, matching `quantum/lattice_hamiltonian`'s
/// canonical frame: interior coords are 0..14 (the 15³), shell is any
/// coord == 15 (the +1 compounding faces). Signed interior coords map
/// as signed = unsigned - 7.
pub const UCoord = struct { x: usize, y: usize, z: usize };

pub const Role = enum {
    /// The geometric origin (7,7,7 unsigned = signed 0,0,0): π centered
    /// at E0.
    pi_anchor,
    /// 15³ interior minus origin: φ carried inward toward center.
    phi_inward,
    /// 16³ shell (any coord == 15): the +1 compounding layer. Inert on
    /// the bare 15³; exists only when scaling/compounding.
    phi_compounding,
};

/// One of the six cardinal directions as seen FROM the center:
/// +X/-X/+Y/-Y/+Z/-Z rays.
pub const Direction = enum(u3) {
    pos_x = 0,
    neg_x = 1,
    pos_y = 2,
    neg_y = 3,
    pos_z = 4,
    neg_z = 5,

    pub fn axis(self: Direction) usize {
        return @intFromEnum(self) / 2;
    }

    /// +1 toward increasing unsigned coord, -1 toward decreasing.
    pub fn sign(self: Direction) i8 {
        return if (@intFromEnum(self) & 1 == 0) 1 else -1;
    }
};

/// True for the 721 shell sites: any coord on a +1 face (== 15).
/// These coordinates have no interactions on the bare 15³ lattice.
pub fn isCompoundingShell(coord: UCoord) bool {
    return coord.x == DOMAIN_SIDE - 1 or coord.y == DOMAIN_SIDE - 1 or coord.z == DOMAIN_SIDE - 1;
}

/// Positional role of an unsigned domain coordinate.
pub fn roleOf(coord: UCoord) Role {
    if (coord.x == CENTER and coord.y == CENTER and coord.z == CENTER) return .pi_anchor;
    if (!isCompoundingShell(coord)) return .phi_inward;
    return .phi_compounding;
}

fn coordOnAxis(coord: UCoord, axis: usize) bool {
    return switch (axis) {
        0 => coord.y == CENTER and coord.z == CENTER,
        1 => coord.x == CENTER and coord.z == CENTER,
        else => coord.x == CENTER and coord.y == CENTER,
    };
}

fn coordValue(coord: UCoord, axis: usize) usize {
    return switch (axis) {
        0 => coord.x,
        1 => coord.y,
        else => coord.z,
    };
}

/// The six-direction ray a site belongs to, if any: exactly two coords
/// at center and the third inside the interior but off-center. Returns
/// the direction pointing FROM center TO the site (the outward ray
/// direction; the inward φ flow travels the opposite way).
pub fn cardinalRay(coord: UCoord) ?Direction {
    if (isCompoundingShell(coord)) return null;
    var axis: usize = undefined;
    var off_center: usize = 0;
    for (0..3) |a| {
        if (!coordOnAxis(coord, a)) continue;
        axis = a;
        off_center = @intFromBool(coordValue(coord, a) != CENTER);
    }
    if (off_center == 0) return null;
    const value = coordValue(coord, axis);
    const base: u3 = @intFromEnum(Direction.pos_x) + @as(u3, @intCast(axis)) * 2;
    return @enumFromInt(if (value > CENTER) base else base + 1);
}

/// Unit step toward the geometric origin along the unique dominant
/// axis — the inward φ direction. Returns null at the origin and where
/// no single axis dominates (ties carry no unique inward step under
/// this contract).
pub fn inwardStep(coord: UCoord) ?Direction {
    if (coord.x == CENTER and coord.y == CENTER and coord.z == CENTER) return null;
    const center_i: i32 = @intCast(CENTER);
    const deltas = [_]i32{ @as(i32, @intCast(coord.x)) - center_i, @as(i32, @intCast(coord.y)) - center_i, @as(i32, @intCast(coord.z)) - center_i };
    var max_abs: u32 = 0;
    for (deltas) |d| max_abs = @max(max_abs, @abs(d));
    var count: u3 = 0;
    var chosen: Direction = undefined;
    for (deltas, 0..) |d, axis| {
        if (@abs(d) == max_abs and d != 0) {
            if (count != 0) return null;
            // Inward = toward center: offset d>0 means inward is the
            // negative-direction enum entry (base+1), d<0 the positive.
            const outward_base: u3 = @intFromEnum(Direction.pos_x) + @as(u3, @intCast(axis)) * 2;
            chosen = @enumFromInt(outward_base + @as(u3, @intFromBool(d > 0)));
            count += 1;
        }
    }
    if (count == 0) return null;
    return chosen;
}

/// Signed step applied to an unsigned coordinate along a direction.
/// Caller must keep results inside 0..15; this contract does not bounds-
/// check stepping (it describes directions, not motion legality).
pub fn step(coord: UCoord, direction: Direction) UCoord {
    var next = coord;
    const delta: i32 = direction.sign();
    switch (direction.axis()) {
        0 => next.x = @intCast(@as(i32, @intCast(next.x)) + delta),
        1 => next.y = @intCast(@as(i32, @intCast(next.y)) + delta),
        else => next.z = @intCast(@as(i32, @intCast(next.z)) + delta),
    }
    return next;
}

pub const Census = struct { pi_anchor: usize, phi_inward: usize, phi_compounding: usize, cardinal_rays: usize };

/// Domain census over the full 16³ unsigned volume. Interior is
/// coords 0..14 (3375 sites); the +1 compounding shell is 721 sites.
pub fn census() Census {
    var result = Census{ .pi_anchor = 0, .phi_inward = 0, .phi_compounding = 0, .cardinal_rays = 0 };
    for (0..DOMAIN_SIDE) |x| {
        for (0..DOMAIN_SIDE) |y| {
            for (0..DOMAIN_SIDE) |z| {
                const coord = UCoord{ .x = x, .y = y, .z = z };
                switch (roleOf(coord)) {
                    .pi_anchor => result.pi_anchor += 1,
                    .phi_inward => result.phi_inward += 1,
                    .phi_compounding => result.phi_compounding += 1,
                }
                if (cardinalRay(coord) != null) result.cardinal_rays += 1;
            }
        }
    }
    return result;
}

test "role census partitions the 16^3 domain exactly" {
    const c = census();
    try std.testing.expectEqual(@as(usize, 1), c.pi_anchor);
    try std.testing.expectEqual(@as(usize, 3374), c.phi_inward);
    try std.testing.expectEqual(@as(usize, 721), c.phi_compounding);
    try std.testing.expectEqual(DOMAIN_SITES, c.pi_anchor + c.phi_inward + c.phi_compounding);
    try std.testing.expectEqual(CARDINAL_RAY_SITES, c.cardinal_rays);
}

test "bare 15^3 view has no compounding sites" {
    for (0..INTERIOR_SIDE) |x| {
        for (0..INTERIOR_SIDE) |y| {
            for (0..INTERIOR_SIDE) |z| {
                const coord = UCoord{ .x = x, .y = y, .z = z };
                try std.testing.expect(!isCompoundingShell(coord));
            }
        }
    }
    try std.testing.expect(isCompoundingShell(.{ .x = 15, .y = 0, .z = 0 }));
    try std.testing.expect(isCompoundingShell(.{ .x = 0, .y = 15, .z = 0 }));
    try std.testing.expect(isCompoundingShell(.{ .x = 0, .y = 0, .z = 15 }));
    try std.testing.expect(!isCompoundingShell(.{ .x = 14, .y = 14, .z = 14 }));
}

test "origin is the pi anchor and interior sites carry phi inward" {
    try std.testing.expectEqual(Role.pi_anchor, roleOf(.{ .x = CENTER, .y = CENTER, .z = CENTER }));
    try std.testing.expectEqual(Role.phi_inward, roleOf(.{ .x = 10, .y = 3, .z = 14 }));
    try std.testing.expectEqual(Role.phi_inward, roleOf(.{ .x = 0, .y = 0, .z = 0 }));
}

test "compounding shell sites are the phi-outward exterior" {
    try std.testing.expectEqual(Role.phi_compounding, roleOf(.{ .x = 15, .y = 7, .z = 7 }));
    try std.testing.expectEqual(Role.phi_compounding, roleOf(.{ .x = 7, .y = 15, .z = 0 }));
    try std.testing.expectEqual(Role.phi_compounding, roleOf(.{ .x = 0, .y = 0, .z = 15 }));
}

test "six cardinal directions each carry seven interior ray sites per side" {
    const directions = [_]Direction{ .pos_x, .neg_x, .pos_y, .neg_y, .pos_z, .neg_z };
    for (directions) |direction| {
        var count: usize = 0;
        var distance: usize = 1;
        while (distance <= 7) : (distance += 1) {
            // Walk outward from center along the ray direction.
            var coord = UCoord{ .x = CENTER, .y = CENTER, .z = CENTER };
            for (0..distance) |_| coord = step(coord, direction);
            try std.testing.expect(coord.x < INTERIOR_SIDE and coord.y < INTERIOR_SIDE and coord.z < INTERIOR_SIDE);
            try std.testing.expectEqual(direction, cardinalRay(coord).?);
            try std.testing.expectEqual(Role.phi_inward, roleOf(coord));
            count += 1;
        }
        try std.testing.expectEqual(@as(usize, 7), count);
    }
}

test "inward step points toward the origin on unique-dominant-axis sites" {
    // coord 12 on x (offset +5 from center 7): inward is -x = neg_x.
    try std.testing.expectEqual(Direction.neg_x, inwardStep(.{ .x = 12, .y = CENTER, .z = CENTER }).?);
    // coord 2 on x (offset -5): inward is +x = pos_x.
    try std.testing.expectEqual(Direction.pos_x, inwardStep(.{ .x = 2, .y = CENTER, .z = CENTER }).?);
    try std.testing.expectEqual(Direction.neg_z, inwardStep(.{ .x = CENTER, .y = CENTER, .z = 11 }).?);
    try std.testing.expect(inwardStep(.{ .x = CENTER, .y = CENTER, .z = CENTER }) == null);
    // Tied dominant axes carry no unique inward step.
    try std.testing.expect(inwardStep(.{ .x = 12, .y = 12, .z = CENTER }) == null);
}
