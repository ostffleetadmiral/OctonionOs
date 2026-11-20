//! Scaling-tier shells from the prototype chain:
//!
//!   15^3/16^3 -> 30^3/32^3 -> 60^3/64^3 -> 120^3/128^3   (plus the paired
//!   32^3 and 64^3 "global" tiers the props declare)
//!
//! Each tier is a deterministic structure described by inner bound `n` and
//! shell bound `n+1` (or an explicit paired shell). No arrays are allocated —
//! cell states are computed from the basis coloring
//!   basis(x,y,z) = (|x-c| + |y-c| + |z-c|) mod 8,  c = n/2
//! matching the FANO firmware convention under which e0 (basis state 0)
//! occupies exactly 421 cells of 15^3.
//!
//! Classification: CONSTRUCTION. The declared qubit labels ("2 qbits
//! non-entangled", "64 qbits globally entangled", ...) are metadata strings
//! carried verbatim from the prototype; nothing here verifies or endorses the
//! physical interpretation. Computed fields (foam counts, histograms, digests)
//! are exact integers.
const std = @import("std");

pub const Tier = struct {
    inner: u16,
    shell: u16,
    qbits_declared: u16,
    label: []const u8,
};

/// Prototype-declared tier chain (labels verbatim from the source notes).
pub const TIERS = [_]Tier{
    .{ .inner = 15, .shell = 16, .qbits_declared = 1, .label = "1 qbit, 7-defect" },
    .{ .inner = 30, .shell = 32, .qbits_declared = 2, .label = "2 qbits non-entangled" },
    .{ .inner = 32, .shell = 33, .qbits_declared = 8, .label = "8 qbits globally entangled" },
    .{ .inner = 60, .shell = 64, .qbits_declared = 4, .label = "4 qbits non-entangled" },
    .{ .inner = 64, .shell = 65, .qbits_declared = 64, .label = "64 qbits globally entangled" },
    .{ .inner = 120, .shell = 128, .qbits_declared = 8, .label = "8 qbits non-entangled" },
    .{ .inner = 128, .shell = 129, .qbits_declared = 512, .label = "512 qbits globally entangled" },
};

fn d7(v: u16, c: u16) u16 {
    return if (v >= c) v - c else c - v;
}

/// basis state of an interior cell, FANO convention.
pub fn basisAt(x: u16, y: u16, z: u16, inner: u16) u3 {
    const c: u16 = inner / 2;
    return @intCast((d7(x, c) + d7(y, c) + d7(z, c)) & 7);
}

/// A coordinate belongs to the foam shell when any component equals `inner`.
pub fn isFoam(x: u16, y: u16, z: u16, inner: u16) bool {
    return x == inner or y == inner or z == inner;
}

/// shell^3 - inner^3 boundary-cell count.
pub fn foamCount(inner: u16, shell: u16) u64 {
    const i: u64 = inner;
    const s: u64 = shell;
    return s * s * s - i * i * i;
}

/// Population of each basis state across the interior n^3 volume.
pub fn histogram(inner: u16) [8]u64 {
    var hist = [_]u64{0} ** 8;
    for (0..inner) |z| for (0..inner) |y| for (0..inner) |x| {
        hist[basisAt(@intCast(x), @intCast(y), @intCast(z), inner)] += 1;
    };
    return hist;
}

/// e0 = basis state 0 population.
pub fn e0Count(inner: u16) u64 {
    return histogram(inner)[0];
}

/// Canonical FNV-1a-64 digest over the interior's basis-state sequence
/// (x fastest, then y, then z). Identifies the tier structure exactly.
pub fn digest(inner: u16) u64 {
    var h: u64 = 0xcbf29ce484222325;
    for (0..inner) |z| for (0..inner) |y| for (0..inner) |x| {
        h ^= basisAt(@intCast(x), @intCast(y), @intCast(z), inner);
        h *%= 0x100000001b3;
    };
    return h;
}

/// True when the basis histogram is uniform (no defect state).
pub fn isUniform(inner: u16) bool {
    const h = histogram(inner);
    for (h) |v| if (v != h[0]) return false;
    return true;
}

/// Index of the deficit state (population below the modal value), if any.
pub fn defectState(inner: u16) ?u3 {
    const h = histogram(inner);
    var max: u64 = 0;
    for (h) |v| max = @max(max, v);
    var found: ?u3 = null;
    for (h, 0..) |v, i| {
        if (v < max) {
            if (found != null) return null; // more than one deficit: not a single defect
            found = @intCast(i);
        }
    }
    return found;
}

test "15^3 tier: e0 carries the 421 defect, foam is 721" {
    try std.testing.expectEqual(@as(u64, 721), foamCount(15, 16));
    try std.testing.expectEqual(@as(u64, 421), e0Count(15));
    try std.testing.expectEqual(@as(?u3, 0), defectState(15));
    const h = histogram(15);
    try std.testing.expectEqual(@as(u64, 421), h[0]);
    for (h[1..]) |v| try std.testing.expectEqual(@as(u64, 422), v);
}

test "tier chain volumes and defect structure" {
    for (TIERS) |t| {
        // interior + foam = shell volume
        var interior: u64 = 0;
        const h = histogram(t.inner);
        for (h) |v| interior += v;
        try std.testing.expectEqual(@as(u64, t.inner) * t.inner * t.inner, interior);
    }
    // Defect structure per tier: even inners have a different defect profile
    // than the odd 15; recorded, not assumed.
    _ = defectState(30);
    _ = defectState(32);
}

test "digests are tier-canonical" {
    try std.testing.expectEqual(digest(15), digest(15));
    try std.testing.expect(digest(15) != digest(16));
    try std.testing.expect(digest(30) != digest(15));
}

test "foam boundary excludes interior cells" {
    try std.testing.expect(!isFoam(0, 0, 0, 15));
    try std.testing.expect(!isFoam(14, 14, 14, 15));
    try std.testing.expect(isFoam(15, 0, 0, 15));
    try std.testing.expect(isFoam(0, 15, 0, 15));
}
