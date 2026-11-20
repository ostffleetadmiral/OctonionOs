//! QComms lattice labels aligned to the Octonion-OS True-Origin tensor.
const std = @import("std");
const canonical = @import("redox_scaling_tiers.zig");

pub const Inner = 15;
pub const Shell = 16;
pub const Foam: u8 = 8;
pub const LABELING_VERSION: u16 = 2;

pub fn layerShift(layer: u8) u8 {
    if (layer < 1 or layer > Inner) return 0;
    const effective: u8 = if (layer <= 8) layer else 16 - layer;
    return (effective - 1) % 8;
}

/// Octonion-OS canonical e0..e7 label. Coordinates are zero-based indices
/// into the 15^3 interior, with the geometric origin at (7, 7, 7).
pub fn state(x: u8, y: u8, z: u8) u8 {
    if (x >= Inner or y >= Inner or z >= Inner) return Foam;
    return canonical.basisAt(x, y, z, Inner);
}

/// Legacy pre-alignment coloring, retained for archived-run reproduction.
pub fn legacyState(x: u8, y: u8, z: u8) u8 {
    if (x >= Inner or y >= Inner or z >= Inner) return Foam;
    return @intCast((@as(u16, x) + y + layerShift(z + 1)) % 8);
}

pub fn shellState(x: u8, y: u8, z: u8) u8 {
    if (x >= Shell or y >= Shell or z >= Shell) return Foam;
    return state(x, y, z);
}

pub fn legacyShellState(x: u8, y: u8, z: u8) u8 {
    if (x >= Shell or y >= Shell or z >= Shell) return Foam;
    return legacyState(x, y, z);
}

pub fn digest() u64 {
    var hash: u64 = 0xcbf29ce484222325;
    for (0..Shell) |z| for (0..Shell) |y| for (0..Shell) |x| {
        hash ^= shellState(@intCast(x), @intCast(y), @intCast(z));
        hash *%= 0x100000001b3;
    };
    return hash;
}

pub fn legacyDigest() u64 {
    var hash: u64 = 0xcbf29ce484222325;
    for (0..Shell) |z| for (0..Shell) |y| for (0..Shell) |x| {
        hash ^= legacyShellState(@intCast(x), @intCast(y), @intCast(z));
        hash *%= 0x100000001b3;
    };
    return hash;
}

test "canonical QComms coloring matches the 15^3 E0-centered contract" {
    var histogram = [_]usize{0} ** 8;
    for (0..Inner) |z| for (0..Inner) |y| for (0..Inner) |x| {
        const label = state(@intCast(x), @intCast(y), @intCast(z));
        histogram[label] += 1;
        try std.testing.expectEqual(canonical.basisAt(@intCast(x), @intCast(y), @intCast(z), Inner), label);
    };
    try std.testing.expectEqual([_]usize{ 421, 422, 422, 422, 422, 422, 422, 422 }, histogram);
    try std.testing.expectEqual(@as(u8, 0), state(7, 7, 7));
    try std.testing.expectEqual(Foam, state(Inner, 7, 7));
}

test "legacy QComms coloring remains available for archived-run reproduction" {
    var histogram = [_]usize{0} ** 8;
    for (0..Inner) |z| for (0..Inner) |y| for (0..Inner) |x| {
        histogram[legacyState(@intCast(x), @intCast(y), @intCast(z))] += 1;
    };
    try std.testing.expectEqual([_]usize{ 422, 422, 422, 422, 422, 421, 422, 422 }, histogram);
    try std.testing.expectEqual(@as(u64, 0x44d79e25e207220e), legacyDigest());
    try std.testing.expect(legacyDigest() != digest());
}

test "lattice mirror and shell invariants" {
    try std.testing.expectEqual(@as(u16, 2), LABELING_VERSION);
    try std.testing.expectEqual(@as(u8, 0), layerShift(1));
    try std.testing.expectEqual(@as(u8, 7), layerShift(8));
    try std.testing.expectEqual(@as(u8, 0), layerShift(15));
    for (1..8) |layer| try std.testing.expectEqual(layerShift(@intCast(layer)), layerShift(@intCast(16 - layer)));
    var foam: usize = 0;
    for (0..Shell) |z| {
        for (0..Shell) |y| {
            for (0..Shell) |x| {
                if (shellState(@intCast(x), @intCast(y), @intCast(z)) == Foam) foam += 1;
            }
        }
    }
    try std.testing.expectEqual(@as(usize, 721), foam);
    try std.testing.expectEqual(@as(usize, 721), canonical.foamCount(Inner, Shell));
}
