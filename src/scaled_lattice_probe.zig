//! Scaled lattice probe — exact state histograms for inner sides up to 512
//! without materializing the volume.
//!
//! The RedOx canonical coloring is
//!   basis(x,y,z) = (|x-c| + |y-c| + |z-c|) mod 8,  c = inner/2
//! over x,y,z in 0..inner-1 (redox_scaling_tiers.basisAt). Because the
//! final state depends only on each axis distance mod 8, the full
//! histogram is the triple convolution of the one-axis residue
//! histogram — O(inner) work instead of O(inner^3), exact in u64.
//!
//! Verified anchors: inner 15 gives the unique 7-defect at state 0
//! (421 e0 cells, 422 each of e1..e7); every power-of-two inner is
//! uniform. Canonical pairs preserve shell/inner = 16/15 through 512.
const std = @import("std");
const precision = @import("precision_ladder.zig");

/// One-axis residue histogram: count of x in 0..n-1 with |x - n/2| ≡ m (mod 8).
fn axisResidues(n: u16) [8]u64 {
    var hist = [_]u64{0} ** 8;
    const c: i32 = @intCast(n / 2);
    for (0..n) |x_i| {
        const x: i32 = @intCast(x_i);
        const d = if (x >= c) x - c else c - x;
        hist[@intCast(@mod(d, 8))] += 1;
    }
    return hist;
}

/// Exact per-state population over the n^3 interior.
pub fn stateHistogram(inner: u16) [8]u64 {
    const r = axisResidues(inner);
    var pair = [_]u64{0} ** 8;
    for (0..8) |a| {
        for (0..8) |b| {
            pair[(a + b) % 8] += r[a] * r[b];
        }
    }
    var out = [_]u64{0} ** 8;
    for (0..8) |t| {
        for (0..8) |c| {
            out[(t + c) % 8] += pair[t] * r[c];
        }
    }
    return out;
}

/// e0 = state-0 population (the observer/defect carrier).
pub fn e0Count(inner: u16) u64 {
    return stateHistogram(inner)[0];
}

/// Index of the unique deficit state, or null when uniform/multi-defect.
pub fn defectState(inner: u16) ?u3 {
    const h = stateHistogram(inner);
    var max: u64 = 0;
    for (h) |v| max = @max(max, v);
    var found: ?u3 = null;
    for (h, 0..) |v, i| {
        if (v < max) {
            if (found != null) return null;
            found = @intCast(i);
        }
    }
    return found;
}

pub fn volume(side: u16) u64 {
    return precision.volume(side);
}

pub fn foamCount(inner: u16, shell: u16) u64 {
    return precision.foamCount(inner, shell);
}

/// Imbalance form 8*hist[s] - n^3 (exact signed defect/surplus ledger).
pub fn imbalance(inner: u16) [8]i64 {
    const h = stateHistogram(inner);
    const total: i64 = @intCast(@as(u64, inner) * inner * inner);
    var out: [8]i64 = undefined;
    for (0..8) |s| out[s] = 8 * @as(i64, @intCast(h[s])) - total;
    return out;
}

test "15^3 histogram carries the unique 7-defect at state 0" {
    const h = stateHistogram(15);
    try std.testing.expectEqual(@as(u64, 421), h[0]);
    for (h[1..]) |v| try std.testing.expectEqual(@as(u64, 422), v);
    try std.testing.expectEqual(@as(u64, 421), e0Count(15));
    try std.testing.expectEqual(@as(?u3, 0), defectState(15));
    try std.testing.expectEqual([8]i64{ -7, 1, 1, 1, 1, 1, 1, 1 }, imbalance(15));
}

fn axisDist(v: usize, c: i32) i32 {
    const vi: i32 = @intCast(v);
    return if (vi >= c) vi - c else c - vi;
}

test "histogram matches brute-force coloring on small sides" {
    // Cross-check the O(n) convolution against direct O(n^3) evaluation.
    const brute = struct {
        fn f(n: u16) [8]u64 {
            var h = [_]u64{0} ** 8;
            const c: i32 = @intCast(n / 2);
            for (0..n) |z_i| {
                for (0..n) |y_i| {
                    for (0..n) |x_i| {
                        const s = @mod(axisDist(x_i, c) + axisDist(y_i, c) + axisDist(z_i, c), 8);
                        h[@intCast(s)] += 1;
                    }
                }
            }
            return h;
        }
    }.f;
    for ([_]u16{ 2, 4, 8, 15, 16 }) |n| {
        try std.testing.expectEqual(brute(n), stateHistogram(n));
    }
}

test "30^3 disperses the defect across states 6 and 7" {
    try std.testing.expectEqual([8]i64{ 0, 8, 8, 8, 8, 0, -16, -16 }, imbalance(30));
}

test "power-of-two inners are uniform through 512" {
    for (precision.LATTICE_SIDES) |side| {
        const h = stateHistogram(side);
        for (h) |v| try std.testing.expectEqual(h[0], v);
        try std.testing.expectEqual(@as(?u3, null), defectState(side));
    }
}

test "canonical inner sides run 15,30,60,120,240,480" {
    const pairs = precision.canonicalPairs();
    const expected = [_]u16{ 15, 30, 60, 120, 240, 480 };
    for (pairs, expected) |p, inner| {
        try std.testing.expectEqual(inner, p.inner);
        // shell/inner = 16/15 exactly, so inner^3 = (15/16)^3 * shell^3.
        try std.testing.expectEqual(@as(u32, 16) * p.inner, @as(u32, 15) * p.shell);
    }
    // interior volumes scale by 8 each doubling
    try std.testing.expectEqual(@as(u64, 27_000), volume(30));
    try std.testing.expectEqual(@as(u64, 216_000), volume(60));
    try std.testing.expectEqual(@as(u64, 1_728_000), volume(120));
    try std.testing.expectEqual(@as(u64, 13_824_000), volume(240));
    try std.testing.expectEqual(@as(u64, 110_592_000), volume(480));
    // foam counts: 721, 5768, 46144, 369152, 2953216, 23625728
    try std.testing.expectEqual(@as(u64, 721), foamCount(15, 16));
    try std.testing.expectEqual(@as(u64, 5_768), foamCount(30, 32));
    try std.testing.expectEqual(@as(u64, 46_144), foamCount(60, 64));
    try std.testing.expectEqual(@as(u64, 369_152), foamCount(120, 128));
    try std.testing.expectEqual(@as(u64, 2_953_216), foamCount(240, 256));
    try std.testing.expectEqual(@as(u64, 23_625_728), foamCount(480, 512));
}

test "480^3 is uniform under the mod-8 coloring (measured)" {
    // The deepest canonical inner: the mod-8 coloring balances exactly,
    // so the 7-defect does not survive doubling to 480. Recorded, not assumed.
    const im = imbalance(480);
    for (im) |v| try std.testing.expectEqual(@as(i64, 0), v);
    const h = stateHistogram(480);
    const expected_each = @as(u64, 480) * 480 * 480 / 8;
    for (h) |v| try std.testing.expectEqual(expected_each, v);
}

test "scaled probe is deterministic" {
    try std.testing.expectEqual(stateHistogram(120), stateHistogram(120));
    try std.testing.expectEqual(e0Count(240), e0Count(240));
}
