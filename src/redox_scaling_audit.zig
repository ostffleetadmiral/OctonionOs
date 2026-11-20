//! Audit of the scaling-tier mechanics spec: volumetric doubling,
//! foam-boundary exclusion, defect dispersal, and the claimed
//! recursive nesting between octave tiers.
//!
//! All values are measured from `redox_scaling_tiers.basisAt` — the
//! canonical FANO coloring — with integer arithmetic only.
//!
//! Key results (all derived below, asserted in tests):
//!   * boundary ratio (shell^3 - inner^3)/inner^3 is EXACTLY 721/3375
//!     at every tier pair, because shell/inner = 16/15 uniformly.
//!   * the unique 7-defect at 15^3 disperses irregularly: 30^3 splits
//!     it across states {6,7}; 60^3 spreads it over all 8 states;
//!     120^3 over six; powers-of-two tiers are perfectly uniform.
//!   * literal nesting is FALSIFIED: only 422 of 3375 even-coordinate
//!     cells carry the same state under the 15^3 and 30^3 colorings —
//!     each tier re-centers basisAt rather than subdividing the
//!     parent coloring.
const std = @import("std");
const tiers = @import("redox_scaling_tiers.zig");
const vec3 = @import("redox_vector3.zig");
const bridge = @import("redox_algebra_bridge.zig");

pub const TierPair = struct { inner: u16, shell: u16 };

pub const PAIRS = [4]TierPair{
    .{ .inner = 15, .shell = 16 },
    .{ .inner = 30, .shell = 32 },
    .{ .inner = 60, .shell = 64 },
    .{ .inner = 120, .shell = 128 },
};

/// Interior volumes of the four doubling tiers.
pub const VOLUMES = [4]u64{ 3375, 27_000, 216_000, 1_728_000 };

/// Foam (boundary) cell counts per tier pair: 721, 5768, 46144, 369152.
pub const FOAM = [4]u64{ 721, 5_768, 46_144, 369_152 };

/// Exact proportional boundary ratio check:
/// (shell^3 - inner^3) * 3375 == 721 * inner^3 — no division anywhere.
pub fn boundaryRatioExact(inner: u16, shell: u16) bool {
    const foam = tiers.foamCount(inner, shell);
    const i128_foam: u128 = foam;
    const i128_inner: u128 = @as(u128, inner) * inner * inner;
    return i128_foam * 3375 == 721 * i128_inner;
}

/// Per-state imbalance in the exact form 8*hist[s] - inner^3.
/// Zero at every state iff the coloring is uniform; the signed values
/// record both deficit and surplus exactly.
pub fn imbalance(inner: u16) [8]i64 {
    const h = tiers.histogram(inner);
    const total: i64 = @intCast(@as(u64, inner) * inner * inner);
    var out: [8]i64 = undefined;
    for (0..8) |s| {
        out[s] = 8 * @as(i64, @intCast(h[s])) - total;
    }
    return out;
}

/// Count of cells whose canonical 15^3 state equals the 30^3 state of
/// the doubled even-coordinate image (2x, 2y, 2z). Measured: 422.
pub fn nestingAgreement() u32 {
    var agree: u32 = 0;
    for (0..15) |z| {
        for (0..15) |y| {
            for (0..15) |x| {
                const a = tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), 15);
                const b = tiers.basisAt(@intCast(2 * x), @intCast(2 * y), @intCast(2 * z), 30);
                if (a == b) agree += 1;
            }
        }
    }
    return agree;
}

/// Count cells satisfying the foam predicate on shell^3. The predicate
/// marks the inner-facing plane (coord == inner): equals the volumetric
/// boundary only when the shell is one cell thick (the canonical pair).
pub fn foamPartitionCount(inner: u16, shell: u16) u64 {
    var count: u64 = 0;
    for (0..shell) |z| {
        for (0..shell) |y| {
            for (0..shell) |x| {
                if (tiers.isFoam(@intCast(x), @intCast(y), @intCast(z), inner)) count += 1;
            }
        }
    }
    return count;
}

/// Sum of |imbalance| across states — the dispersal "spread" measure.
/// 15^3 gives 14 (7 defect + 7 one-surpluses); powers of two give 0.
pub fn dispersalMagnitude(inner: u16) u64 {
    const im = imbalance(inner);
    var sum: u64 = 0;
    for (im) |v| sum += @intCast(@abs(v));
    return sum;
}

// ---------------------------------------------------------------------------
// Tests — every spec claim measured
// ---------------------------------------------------------------------------

test "volumes: 15^3, 30^3, 60^3, 120^3 interiors and shells" {
    for (PAIRS, VOLUMES, FOAM) |p, vol, foam| {
        const iv: u64 = @as(u64, p.inner) * p.inner * p.inner;
        const sv: u64 = @as(u64, p.shell) * p.shell * p.shell;
        try std.testing.expectEqual(vol, iv);
        try std.testing.expectEqual(sv - iv, tiers.foamCount(p.inner, p.shell));
        try std.testing.expectEqual(foam, tiers.foamCount(p.inner, p.shell));
    }
}

test "boundary ratio is EXACTLY 721/3375 at all four tier pairs" {
    for (PAIRS) |p| {
        try std.testing.expect(boundaryRatioExact(p.inner, p.shell));
    }
}

test "15^3 defect: unique 7-cell deficit at state 0" {
    const im = imbalance(15);
    try std.testing.expectEqual(@as(i64, -7), im[0]);
    for (1..8) |s| {
        try std.testing.expectEqual(@as(i64, 1), im[s]);
    }
}

test "30^3: deficit disperses to states 6 and 7 only" {
    const im = imbalance(30);
    try std.testing.expectEqual([8]i64{ 0, 8, 8, 8, 8, 0, -16, -16 }, im);
}

test "60^3: imbalance spreads over all 8 states" {
    const im = imbalance(60);
    try std.testing.expectEqual([8]i64{ 56, 64, 56, 16, -56, -96, -56, 16 }, im);
}

test "120^3: six-state dispersal, states 0 and 4 exact" {
    const im = imbalance(120);
    try std.testing.expectEqual([8]i64{ 0, -160, -224, -160, 0, 160, 224, 160 }, im);
}

test "powers-of-two tiers are perfectly uniform" {
    for ([_]u16{ 16, 32, 64, 128 }) |n| {
        const im = imbalance(n);
        for (im) |v| {
            try std.testing.expectEqual(@as(i64, 0), v);
        }
    }
}

test "literal nesting is falsified: only 422/3375 even-coord agreements" {
    const agree = nestingAgreement();
    try std.testing.expectEqual(@as(u32, 422), agree);
    try std.testing.expect(agree < 3375);
}

test "foam predicate partitions the canonical pair but diverges at doubled tiers" {
    // isFoam marks cells with coord == inner — the inner-facing plane
    // of the shell. At 15/16 the shell is one cell thick so this is
    // the whole boundary (721). At doubled tiers the shell is two
    // cells thick and isFoam covers only shell^3-(shell-1)^3 of it.
    const iso_counts = [4]u64{ 721, 2_977, 12_097, 48_769 };
    for (PAIRS, iso_counts) |p, expected| {
        const measured = foamPartitionCount(p.inner, p.shell);
        try std.testing.expectEqual(expected, measured);
        const s: u64 = p.shell;
        try std.testing.expectEqual(s * s * s - (s - 1) * (s - 1) * (s - 1), measured);
    }
    // The divergence between the predicate and the volumetric shell.
    try std.testing.expect(foamPartitionCount(30, 32) < tiers.foamCount(30, 32));
    try std.testing.expectEqual(tiers.foamCount(15, 16), foamPartitionCount(15, 16));
}

test "phase drift: tier digests are deterministic across evaluation" {
    for (PAIRS) |p| {
        const d1 = tiers.digest(p.inner);
        const d2 = tiers.digest(p.inner);
        try std.testing.expectEqual(d1, d2);
    }
    // And all four tier digests are pairwise distinct.
    const d = [_]u64{ tiers.digest(15), tiers.digest(30), tiers.digest(60), tiers.digest(120) };
    for (0..4) |i| {
        for (i + 1..4) |j| {
            try std.testing.expect(d[i] != d[j]);
        }
    }
}

test "dispersal magnitude grows with tier depth" {
    try std.testing.expectEqual(@as(u64, 14), dispersalMagnitude(15));
    try std.testing.expectEqual(@as(u64, 64), dispersalMagnitude(30));
    try std.testing.expectEqual(@as(u64, 416), dispersalMagnitude(60));
    try std.testing.expectEqual(@as(u64, 1088), dispersalMagnitude(120));
    try std.testing.expectEqual(@as(u64, 0), dispersalMagnitude(16));
}

// ---------------------------------------------------------------------------
// Revised-spec audit: foam-number falsification, unit stacking, vector3 duality
// ---------------------------------------------------------------------------

/// Foam-boundary numbers claimed by the revised spec. Claims 2-4 match
/// neither the volumetric shell nor the isFoam plane.
pub const SPEC_FOAM_CLAIMS = [4]u64{ 721, 2_752, 21_760, 171_776 };

/// Agreement between the canonical inner-block coloring and the block
/// at offset (ox,oy,oz) inside the doubled host tier.
pub fn blockAgreement(ox: u16, oy: u16, oz: u16, inner: u16, host: u16) u32 {
    var agree: u32 = 0;
    for (0..inner) |z| {
        for (0..inner) |y| {
            for (0..inner) |x| {
                const a = tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), inner);
                const b = tiers.basisAt(@intCast(x + ox), @intCast(y + oy), @intCast(z + oz), host);
                if (a == b) agree += 1;
            }
        }
    }
    return agree;
}

/// Scan every offset for the best-matching canonical sublattice.
/// Returns the agreement count and offset.
pub fn bestNestingOffset(inner: u16, host: u16) struct { agree: u32, ox: u16, oy: u16, oz: u16 } {
    var best: u32 = 0;
    var bx: u16 = 0;
    var by: u16 = 0;
    var bz: u16 = 0;
    const span = host - inner;
    for (0..@as(usize, span) + 1) |oz| {
        for (0..@as(usize, span) + 1) |oy| {
            for (0..@as(usize, span) + 1) |ox| {
                const a = blockAgreement(@intCast(ox), @intCast(oy), @intCast(oz), inner, host);
                if (a > best) {
                    best = a;
                    bx = @intCast(ox);
                    by = @intCast(oy);
                    bz = @intCast(oz);
                }
            }
        }
    }
    return .{ .agree = best, .ox = bx, .oy = by, .oz = bz };
}

// ---------------------------------------------------------------------------
// Vector3 (E3) spatial/structural duality
// ---------------------------------------------------------------------------

/// Sign-canonicalize a direction vector: negate if the first nonzero
/// component is negative. Used to measure the cross-product closure.
fn canonDir(v: vec3.V3) vec3.V3 {
    for (v) |c| {
        if (c > 0) return v;
        if (c < 0) return .{ -v[0], -v[1], -v[2] };
    }
    return v;
}

/// Dimension of the direction-space closure of {e1,e2,e3} under the
/// cross product. Measured: 3 — the cross product closes inside so(3),
/// not the 6-dimensional so(4) the spec assigns to E3. SO(4) is the
/// left/right quaternion multiplication group (E4), not vector3's.
pub fn crossClosureDim() usize {
    var dirs: [8]vec3.V3 = undefined;
    var n: usize = 0;
    for (0..3) |i| {
        dirs[n] = canonDir(vec3.unit(i));
        n += 1;
    }
    var changed = true;
    while (changed) {
        changed = false;
        var i: usize = 0;
        while (i < n) : (i += 1) {
            var j: usize = 0;
            while (j < n) : (j += 1) {
                const c = canonDir(vec3.cross(dirs[i], dirs[j]));
                if (vec3.normSquared(c) == 0) continue;
                var known = false;
                for (dirs[0..n]) |d| {
                    if (d[0] == c[0] and d[1] == c[1] and d[2] == c[2]) {
                        known = true;
                        break;
                    }
                }
                if (!known and n < dirs.len) {
                    dirs[n] = c;
                    n += 1;
                    changed = true;
                }
            }
        }
    }
    return n;
}

/// Number of declared DAG edges pointing INTO an algebra (promotion
/// sources) and OUT of it (promotion targets).
pub fn dagDegree(a: bridge.Algebra) struct { incoming: usize, outgoing: usize } {
    var inc: usize = 0;
    var out: usize = 0;
    for (std.meta.tags(bridge.Algebra)) |b| {
        if (b == a) continue;
        if (bridge.edgeKind(b, a) != null) inc += 1;
        if (bridge.edgeKind(a, b) != null) out += 1;
    }
    return .{ .incoming = inc, .outgoing = out };
}

// ---------------------------------------------------------------------------
// Revised-spec tests
// ---------------------------------------------------------------------------

test "revised spec foam numbers are falsified: 2752/21760/171776 match nothing" {
    // Correct volumetric shell counts.
    const correct = [4]u64{ 721, 5_768, 46_144, 369_152 };
    for (PAIRS, correct, SPEC_FOAM_CLAIMS) |p, want, claimed| {
        const measured = tiers.foamCount(p.inner, p.shell);
        try std.testing.expectEqual(want, measured);
        // Claim 1 (721) is correct; claims 2-4 are falsified.
        if (p.inner == 15) {
            try std.testing.expectEqual(claimed, measured);
        } else {
            try std.testing.expect(claimed != measured);
        }
    }
}

test "unit stacking: one canonical 15^3 sublattice nests at the center of 30^3" {
    // The centered block (offset 8 per axis) is a perfect embedding.
    try std.testing.expectEqual(@as(u32, 3375), blockAgreement(8, 8, 8, 15, 30));
    // Best over ALL offsets is the centered block.
    const best = bestNestingOffset(15, 30);
    try std.testing.expectEqual(@as(u32, 3375), best.agree);
    try std.testing.expectEqual(@as(u16, 8), best.ox);
    try std.testing.expectEqual(@as(u16, 8), best.oy);
    try std.testing.expectEqual(@as(u16, 8), best.oz);
}

test "unit stacking: octant-aligned blocks do NOT carry canonical coloring" {
    // Measured per-octant agreements (offsets {0,15} per axis).
    const octants = [8]u32{ 1101, 0, 0, 758, 0, 758, 758, 0 };
    var idx: usize = 0;
    for ([_]u16{ 0, 15 }) |oz| {
        for ([_]u16{ 0, 15 }) |oy| {
            for ([_]u16{ 0, 15 }) |ox| {
                try std.testing.expectEqual(octants[idx], blockAgreement(ox, oy, oz, 15, 30));
                idx += 1;
            }
        }
    }
    // Volume fits 8 units; only the central one is canonically colored.
}

test "scaling table arithmetic: linear factor 2, volume factor 8" {
    // 30^3 / 15^3 = 8 volumetrically; linear ratio is 2.
    try std.testing.expectEqual(@as(u64, 8), 27_000 / 3_375);
    try std.testing.expectEqual(@as(u64, 8), 216_000 / 27_000);
    try std.testing.expectEqual(@as(u64, 8), 1_728_000 / 216_000);
}

test "vector3 duality: same coordinate space, different algebra" {
    // Lattice coordinates embed exactly in V3 (i512 components).
    const c = vec3.V3{ 7, 15, 127 };
    try std.testing.expectEqual(@as(i512, 7), c[0]);
    // Anti-commutative on the shared space: e1 x e2 = -e2 x e1.
    const a = vec3.cross(vec3.unit(0), vec3.unit(1));
    const b = vec3.cross(vec3.unit(1), vec3.unit(0));
    try std.testing.expectEqual(-a[0], b[0]);
    try std.testing.expectEqual(-a[1], b[1]);
    try std.testing.expectEqual(-a[2], b[2]);
    // Zero divisor on self: x x x = 0.
    const self_cross = vec3.cross(c, c);
    try std.testing.expectEqual(@as(i512, 0), vec3.normSquared(self_cross));
}

test "vector3 is so(3), not so(4): cross-closure dimension = 3" {
    try std.testing.expectEqual(@as(usize, 3), crossClosureDim());
}

test "vector3 is a DAG source node: edges out, none in" {
    const d = dagDegree(.vector3);
    try std.testing.expectEqual(@as(usize, 0), d.incoming);
    try std.testing.expectEqual(@as(usize, 2), d.outgoing); // -> quaternion, -> octonion
}

// ---------------------------------------------------------------------------
// Octant sub-qubit model — the corrected nesting picture
// ---------------------------------------------------------------------------

/// Histogram of the 15^3 octant block at offset (ox,oy,oz) in {0,15}
/// inside 30^3. Measured: every octant is a histogram-identical copy
/// of the canonical block with the defect cyclically shifted to state
/// (-popcount) & 7 — octant (0,0,0) keeps state-0 defect; each offset
/// axis shifts the defect down one state.
pub fn octantHistogram(ox: u16, oy: u16, oz: u16, inner: u16, host: u16) [8]u32 {
    var h = [_]u32{0} ** 8;
    for (0..inner) |z| {
        for (0..inner) |y| {
            for (0..inner) |x| {
                const s = tiers.basisAt(@intCast(x + ox), @intCast(y + oy), @intCast(z + oz), host);
                h[s] += 1;
            }
        }
    }
    return h;
}

/// The defect state a k-fold offset octant carries: (-k) mod 8.
pub fn octantDefectState(k: usize) u3 {
    return @intCast((8 - (k % 8)) % 8);
}

/// State carried by an octant block's local center — equals its defect.
pub fn octantCenterState(ox: u16, oy: u16, oz: u16, host: u16) u3 {
    return tiers.basisAt(ox + 7, oy + 7, oz + 7, host);
}

/// Split the volumetric shell (any coord >= inner) into the outer
/// surface (some coord == shell-1) and the inner-facing plane (some
/// coord == inner, none == shell-1). At the canonical pair the shell
/// is one cell thick so everything is "outer".
pub fn shellLayerCounts(inner: u16, shell: u16) struct { inner_plane: u64, outer_plane: u64 } {
    var inner_plane: u64 = 0;
    var outer_plane: u64 = 0;
    for (0..shell) |z| {
        for (0..shell) |y| {
            for (0..shell) |x| {
                const xi: u16 = @intCast(x);
                const yi: u16 = @intCast(y);
                const zi: u16 = @intCast(z);
                const outermost = xi == shell - 1 or yi == shell - 1 or zi == shell - 1;
                const innermost = xi == inner or yi == inner or zi == inner;
                if (outermost) {
                    outer_plane += 1;
                } else if (innermost) {
                    inner_plane += 1;
                }
            }
        }
    }
    return .{ .inner_plane = inner_plane, .outer_plane = outer_plane };
}

/// Interior cells of the canonical 15^3 touching the +faces (adjacent
/// to the coord-15 shell) vs the -faces (exposed on the box surface).
pub fn coveredExposedCounts() struct { covered: u64, exposed: u64 } {
    var covered: u64 = 0;
    var exposed: u64 = 0;
    for (0..15) |z| {
        for (0..15) |y| {
            for (0..15) |x| {
                if (x == 14 or y == 14 or z == 14) covered += 1;
                if (x == 0 or y == 0 or z == 0) exposed += 1;
            }
        }
    }
    return .{ .covered = covered, .exposed = exposed };
}

// ---------------------------------------------------------------------------
// Octant-model tests
// ---------------------------------------------------------------------------

test "octant tiling: 8 disjoint 15^3 blocks cover 30^3 exactly" {
    // The offset grid {0,15}^3 is disjoint and spans 0..29 per axis.
    var covered: u64 = 0;
    var octants: u32 = 0;
    for ([_]u16{ 0, 15 }) |oz| {
        for ([_]u16{ 0, 15 }) |oy| {
            for ([_]u16{ 0, 15 }) |ox| {
                octants += 1;
                // Per-axis coverage of the block.
                for (0..15) |i| {
                    try std.testing.expect(@as(u16, @intCast(i)) + ox < 30);
                    try std.testing.expect(@as(u16, @intCast(i)) + oy < 30);
                    try std.testing.expect(@as(u16, @intCast(i)) + oz < 30);
                }
                covered += 15 * 15 * 15;
            }
        }
    }
    try std.testing.expectEqual(@as(u32, 8), octants);
    try std.testing.expectEqual(@as(u64, 27_000), covered);
}

test "every octant is a canonical-histogram copy with shifted defect" {
    for ([_]u16{ 0, 15 }) |oz| {
        for ([_]u16{ 0, 15 }) |oy| {
            for ([_]u16{ 0, 15 }) |ox| {
                const k: usize = @as(usize, @intFromBool(ox == 15)) + @as(usize, @intFromBool(oy == 15)) + @as(usize, @intFromBool(oz == 15));
                const h = octantHistogram(ox, oy, oz, 15, 30);
                const defect = octantDefectState(k);
                for (0..8) |s| {
                    const want: u32 = if (s == defect) 421 else 422;
                    try std.testing.expectEqual(want, h[s]);
                }
            }
        }
    }
}

test "each octant's local center carries its defect state" {
    for ([_]u16{ 0, 15 }) |oz| {
        for ([_]u16{ 0, 15 }) |oy| {
            for ([_]u16{ 0, 15 }) |ox| {
                const k: usize = @as(usize, @intFromBool(ox == 15)) + @as(usize, @intFromBool(oy == 15)) + @as(usize, @intFromBool(oz == 15));
                try std.testing.expectEqual(octantDefectState(k), octantCenterState(ox, oy, oz, 30));
            }
        }
    }
}

test "doubled-tier shell splits into inner plane + outer surface" {
    // 30/32: 2791 cells at coord 30 (inner-facing) + 2977 at coord 31.
    const c = shellLayerCounts(30, 32);
    try std.testing.expectEqual(@as(u64, 2_791), c.inner_plane);
    try std.testing.expectEqual(@as(u64, 2_977), c.outer_plane);
    try std.testing.expectEqual(tiers.foamCount(30, 32), c.inner_plane + c.outer_plane);
    // Canonical pair: single layer — everything is outer surface.
    const c0 = shellLayerCounts(15, 16);
    try std.testing.expectEqual(@as(u64, 0), c0.inner_plane);
    try std.testing.expectEqual(@as(u64, 721), c0.outer_plane);
}

test "3-covered / 3-exposed face counts at scale 0" {
    const ce = coveredExposedCounts();
    try std.testing.expectEqual(@as(u64, 631), ce.covered);
    try std.testing.expectEqual(@as(u64, 631), ce.exposed);
    // Overlap: cells touching both a +face and a -face are counted in
    // both — total face-adjacent interior cells = 1262 - overlap.
}
