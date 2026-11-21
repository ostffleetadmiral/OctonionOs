//! Image-claims probe — executable checks for the supplied diagram set.
//!
//! Three diagram claims admit integer verification in this tree:
//!
//! 1. Möbius panel: the z=0 ↔ z=14 "180° rotation identification" maps
//!    (x,y,0) -> (inner-1-x, inner-1-y, inner-1). Since basisAt depends on
//!    |x-c|+|y-c|+|z-c| mod 8, and |inner-1-x-c| = |x-c| for odd inner,
//!    every cell on the bottom face carries the same label as its twisted
//!    partner on the top face. The identification is label-COMPATIBLE —
//!    and therefore label-INVISIBLE: the coloring cannot distinguish the
//!    Möbius twist from a plain mirror, because the untwisted pairing
//!    (x,y,0) <-> (x,y,14) is equally label-preserving.
//!
//! 2. Qubit self-similarity: the diagrams' scale chain uses canonical-pair
//!    sides — interior 15*2^s, compounding shell 16*2^s — and counts
//!    "qubits" as 8^s. A qubit is one canonical 15^3 block: interior
//!    volume / 3375 = (15*2^s)^3 / 15^3 = 8^s exactly. This indexing
//!    differs from lattice_constant_audit's power-of-two interiors
//!    (scale 2 = 32^3): the audit's interior sides are the image chain's
//!    compounding-shell sides promoted to interiors. Both indexings are
//!    recorded; they must not be conflated. Octant self-similarity at the
//!    histogram level is separately verified in redox_scaling_audit.zig
//!    (each 15^3 octant of 30^3 carries the canonical histogram multiset
//!    with its defect shifted to state (-k mod 8)).
//!
//! 3. Fibonacci cooling (Axiom 5): the bar chart is consistent with a
//!    normalized geometric profile w_z = phi^{-z} / sum_{k=0}^{14} phi^{-k}
//!    over the 15 z-slices. Computed here in Q128 integer fixed-point:
//!    strictly decreasing, ratio 1/phi per slice, weights sum to 1.
//!    This reproduces the profile's shape as integer arithmetic; it is a
//!    candidate per-layer magnitude law, not a validation of the donor's
//!    cooling algorithm or its prediction claims.

const std = @import("std");
const tiers = @import("redox_scaling_tiers.zig");
const fp = @import("fixed_point.zig");
const triad = @import("mound_triad.zig");
const anti = @import("redox_anti_octonion.zig");
const oct = @import("redox_octonion.zig");
const qcomms = @import("qcomms_lattice.zig");
const lattice_mod = @import("lattice.zig");

const Q128 = fp.Q128;
const PHI = triad.PHI;
const PI = triad.PI;

/// Label of the Möbius-twist partner of a bottom-face cell (x,y,0):
/// (x,y,0) -> (inner-1-x, inner-1-y, inner-1).
pub fn mobiusPartnerLabel(x: u16, y: u16, inner: u16) u3 {
    return tiers.basisAt(inner - 1 - x, inner - 1 - y, inner - 1, inner);
}

/// True when every bottom-face cell carries the same label as its
/// 180°-rotated top-face partner (label-compatible identification).
pub fn mobiusIdentificationCompatible(inner: u16) bool {
    var y: u16 = 0;
    while (y < inner) : (y += 1) {
        var x: u16 = 0;
        while (x < inner) : (x += 1) {
            if (tiers.basisAt(x, y, 0, inner) != mobiusPartnerLabel(x, y, inner)) return false;
        }
    }
    return true;
}

/// True when the untwisted face pairing (x,y,0) <-> (x,y,inner-1) is also
/// label-preserving — i.e., the twist is label-invisible.
pub fn mirrorIdentificationCompatible(inner: u16) bool {
    var y: u16 = 0;
    while (y < inner) : (y += 1) {
        var x: u16 = 0;
        while (x < inner) : (x += 1) {
            if (tiers.basisAt(x, y, 0, inner) != tiers.basisAt(x, y, inner - 1, inner)) return false;
        }
    }
    return true;
}

/// One entry of the image's qubit-ladder scale chain (canonical-pair
/// indexing): interior side 15*2^s, shell side 16*2^s, qubits 8^s.
pub const ImageScale = struct {
    index: u8,
    interior_side: u64,
    shell_side: u64,
    interior_volume: u64,
    shell_volume: u64,
    /// 15^3 blocks tiling the interior — the diagram's "qubit" count.
    qubits: u64,
};

/// Image-chain entry for scale index s (0..3 shown on the panels;
/// the formula is exact for any s that fits u64).
pub fn imageScale(s: u8) ImageScale {
    const inner: u64 = @as(u64, 15) << @intCast(s);
    const shell: u64 = @as(u64, 16) << @intCast(s);
    const iv = inner * inner * inner;
    return .{
        .index = s,
        .interior_side = inner,
        .shell_side = shell,
        .interior_volume = iv,
        .shell_volume = shell * shell * shell,
        .qubits = iv / 3375,
    };
}

/// Normalized Fibonacci-cooling weight for z-slice `z` over `layers`
/// slices: w_z = phi^{-z} / sum_{k<layers} phi^{-k}, in Q128.
pub fn coolingWeight(z: u16, layers: u16) Q128 {
    const inv_phi = Q128.one.div(PHI) catch unreachable;
    var w = Q128.one;
    var sum = Q128.one;
    var k: u16 = 1;
    while (k < layers) : (k += 1) {
        w = w.mul(inv_phi);
        sum = sum.add(w);
    }
    var num = Q128.one;
    var j: u16 = 0;
    while (j < z) : (j += 1) num = num.mul(inv_phi);
    return num.div(sum) catch unreachable;
}

/// The 15-slice cooling profile used on the diagram.
pub fn coolingProfile() [15]Q128 {
    var out: [15]Q128 = undefined;
    for (0..15) |z| out[z] = coolingWeight(@intCast(z), 15);
    return out;
}

// -- Second image batch: spectral panels, Axiom-7 triad, helix -----------

/// Metric for radial ring counts on the inner×inner face.
pub const Metric = enum {
    /// Manhattan distance |dx|+|dy| — diamond rings of 4r cells.
    l1,
    /// Chebyshev distance max(|dx|,|dy|) — square rings of 8r cells.
    linf,
};

/// Cells at exactly distance r from the face center under `metric`,
/// on the inner×inner face (center at inner/2).
pub fn faceRingCount(inner: u16, r: u16, metric: Metric) u64 {
    if (r == 0) return 1;
    const c: u16 = inner / 2;
    var count: u64 = 0;
    var y: u16 = 0;
    while (y < inner) : (y += 1) {
        var x: u16 = 0;
        while (x < inner) : (x += 1) {
            const dx = if (x >= c) x - c else c - x;
            const dy = if (y >= c) y - c else c - y;
            const d: u16 = switch (metric) {
                .l1 => dx + dy,
                .linf => @max(dx, dy),
            };
            if (d == r) count += 1;
        }
    }
    return count;
}

/// e0 population on slice z of the inner^3 interior.
pub fn sliceE0Count(inner: u16, z: u16) u64 {
    var count: u64 = 0;
    var y: u16 = 0;
    while (y < inner) : (y += 1) {
        var x: u16 = 0;
        while (x < inner) : (x += 1) {
            if (tiers.basisAt(x, y, z, inner) == 0) count += 1;
        }
    }
    return count;
}

/// The 8 square-dihedral transforms of a face coordinate.
fn d4Partner(inner: u16, x: u16, y: u16, which: u3) struct { x: u16, y: u16 } {
    const m = inner - 1;
    return switch (which) {
        0 => .{ .x = x, .y = y }, // identity
        1 => .{ .x = y, .y = m - x }, // rotate 90
        2 => .{ .x = m - x, .y = m - y }, // rotate 180
        3 => .{ .x = m - y, .y = x }, // rotate 270
        4 => .{ .x = m - x, .y = y }, // reflect x
        5 => .{ .x = x, .y = m - y }, // reflect y
        6 => .{ .x = y, .y = x }, // main diagonal
        7 => .{ .x = m - y, .y = m - x }, // anti diagonal
    };
}

/// True when the label field on slice z is invariant under all 8
/// square-dihedral transforms. A D4-invariant field decomposes into
/// angular harmonics with m = 0 (mod 4) only — so a "dominant m=7
/// harmonic" (the spectral panels' claim for the donor psi field)
/// cannot come from the canonical coloring. Verified for every slice.
pub fn faceFieldD4Invariant(inner: u16, z: u16) bool {
    var y: u16 = 0;
    while (y < inner) : (y += 1) {
        var x: u16 = 0;
        while (x < inner) : (x += 1) {
            const base = tiers.basisAt(x, y, z, inner);
            var w: u8 = 1;
            while (w < 8) : (w += 1) {
                const p = d4Partner(inner, x, y, @intCast(w));
                if (tiers.basisAt(p.x, p.y, z, inner) != base) return false;
            }
        }
    }
    return true;
}

/// The v11.0 ladder panel's tier coordinates, stored as exact rationals
/// over the DISCRETIZED integer H21 = F0 = 21 (Axiom 7's lattice-level
/// integer), not the continuum triad 21.106: c(3)=21/4, c(4)=21/2,
/// c(5)=21, c(6)=42, c(7)=21, c(8Di)=21/2.
pub const LadderCoord = struct { tier: u8, num: u64, den: u64 };
pub const IMAGE_LADDER_COORDS = [_]LadderCoord{
    .{ .tier = 3, .num = 21, .den = 4 }, // 5.25
    .{ .tier = 4, .num = 21, .den = 2 }, // 10.5
    .{ .tier = 5, .num = 21, .den = 1 }, // 21
    .{ .tier = 6, .num = 42, .den = 1 }, // 42
    .{ .tier = 7, .num = 21, .den = 1 }, // 21
    .{ .tier = 8, .num = 21, .den = 2 }, // 10.5
};

// -- Third image batch: shells, hidden spheres, Fano+e8, projection -------

/// Manhattan-octahedral shell population: interior cells with
/// |dx|+|dy|+|dz| = d. The canonical coloring IS these shells — label =
/// L1-distance mod 8, so e_k is the union of shells {k, k+8, k+16}.
/// The panels' "Concentric Spheres (Chebyshev Shells)" title names the
/// wrong metric: the shells are octahedra (diamonds), not L∞ cubes.
pub fn l1ShellCount(inner: u16, d: u16) u64 {
    const c: u16 = inner / 2;
    var count: u64 = 0;
    var z: u16 = 0;
    while (z < inner) : (z += 1) {
        var y: u16 = 0;
        while (y < inner) : (y += 1) {
            var x: u16 = 0;
            while (x < inner) : (x += 1) {
                const dx = if (x >= c) x - c else c - x;
                const dy = if (y >= c) y - c else c - y;
                const dz = if (z >= c) z - c else c - z;
                if (dx + dy + dz == d) count += 1;
            }
        }
    }
    return count;
}

/// Cells at squared Euclidean distance d2 from the interior center.
pub fn squaredRadiusCount(inner: u16, d2: u64) u64 {
    const c: u16 = inner / 2;
    var count: u64 = 0;
    var z: u16 = 0;
    while (z < inner) : (z += 1) {
        var y: u16 = 0;
        while (y < inner) : (y += 1) {
            var x: u16 = 0;
            while (x < inner) : (x += 1) {
                const dx: u64 = if (x >= c) x - c else c - x;
                const dy: u64 = if (y >= c) y - c else c - y;
                const dz: u64 = if (z >= c) z - c else c - z;
                if (dx * dx + dy * dy + dz * dz == d2) count += 1;
            }
        }
    }
    return count;
}

/// The squared radius of the populated shell nearest to target radius r
/// (argmin |d2 - r^2| over shells that exist in the interior).
/// "Hidden spheres" panels: nearest to phi is d2=3 (8 cells), nearest to
/// pi is d2=10 (24 cells).
pub fn nearestRadiusShell(inner: u16, r: Q128) u64 {
    const c: u64 = inner / 2;
    const rsq = r.mul(r);
    var best_d2: u64 = 0;
    var best_err = rsq.abs();
    var d2: u64 = 0;
    while (d2 <= 3 * c * c) : (d2 += 1) {
        if (squaredRadiusCount(inner, d2) == 0) continue;
        const d = Q128.fromInteger(@intCast(d2)).sub(rsq).abs();
        if (Q128.cmp(d, best_err) < 0) {
            best_err = d;
            best_d2 = d2;
        }
    }
    return best_d2;
}

/// The first three ladder tiers carry constants, not F0 rationals:
/// c(0)=0 (point), c(1)=phi (string panel ~1.618), c(2)=pi (~3.142).
pub const ConstantTier = struct { tier: u8, value: Q128 };
pub const IMAGE_LADDER_CONSTANT_TIERS = [_]ConstantTier{
    .{ .tier = 0, .value = Q128.zero },
    .{ .tier = 1, .value = PHI },
    .{ .tier = 2, .value = PI },
};

// -- Fourth image batch: z-layer panels, Cayley-Dickson table, shell
// semantics ---------------------------------------------------------------

/// Digest of the 2D label pattern on slice z — identical for mirrored
/// pairs (z, inner-1-z). basisAt is additive in |z-c|, so the 15 slices
/// are 8 distinct cyclic shifts of one field.
pub fn slicePatternDigest(inner: u16, z: u16) u64 {
    var h: u64 = 0x9e3779b97f4a7c15;
    var y: u16 = 0;
    while (y < inner) : (y += 1) {
        var x: u16 = 0;
        while (x < inner) : (x += 1) {
            h ^= tiers.basisAt(x, y, z, inner);
            h *%= 0x100000001b3;
        }
    }
    return h;
}

/// Number of distinct 2D label patterns across the inner z-slices.
pub fn distinctSlicePatterns(inner: u16) usize {
    var seen: [16]u64 = undefined;
    var n: usize = 0;
    var z: u16 = 0;
    while (z < inner) : (z += 1) {
        const d = slicePatternDigest(inner, z);
        var found = false;
        for (seen[0..n]) |s| {
            if (s == d) found = true;
        }
        if (!found) {
            seen[n] = d;
            n += 1;
        }
    }
    return n;
}

/// The Cayley-Dickson table's Start->End chain: values are exact
/// rationals over integer H21 = 21. The chain is a palindrome peaking
/// at 42 (2*H21) at the 6D mirror: 21/4 -> 21/2 -> 21 -> 42 -> 21 ->
/// 21/2 -> 21/4.
pub const H21ChainNode = struct { num: u64, den: u64 };
pub const H21_CHAIN = [_]H21ChainNode{
    .{ .num = 21, .den = 4 }, // 5.25   (e2 start / e7 end)
    .{ .num = 21, .den = 2 }, // 10.5   (e2 end = e3 start / e6 end)
    .{ .num = 21, .den = 1 }, // 21     (e3 end = e4 start / e5 end = e6 start)
    .{ .num = 42, .den = 1 }, // 42     (e4 end = e5 start — apex at 6D)
    .{ .num = 21, .den = 1 }, // 21
    .{ .num = 21, .den = 2 }, // 10.5
    .{ .num = 21, .den = 4 }, // 5.25
};

/// Face-sharing topology for the "L15 faces touch, L16 faces outward"
/// panel. In a 2x2x2 arrangement of inner^3 blocks inside (2*inner)^3:
/// the interface plane between an offset-0 block and its offset-`inner`
/// neighbor sits at coordinate `inner` — the low block's last interior
/// coordinate `inner-1` and the high block's first coordinate `inner`
/// are adjacent, so the blocks literally share a face plane. Every
/// block touches neighbors on exactly 3 of its 6 faces (one per axis);
/// the other 3 are exterior, where the compounding shell attaches.
pub fn blockInterfaceCoord(inner: u16) u16 {
    return inner;
}

/// Per-block face counts in the 2x2x2 arrangement — 3 touching, 3
/// exterior, regardless of octant.
pub const BLOCK_TOUCHING_FACES: u8 = 3;
pub const BLOCK_EXTERIOR_FACES: u8 = 3;

test "mobius 180-degree identification is label-compatible and label-invisible" {
    try std.testing.expect(mobiusIdentificationCompatible(15));
    // The untwisted pairing is equally label-preserving: the coloring
    // cannot witness the twist.
    try std.testing.expect(mirrorIdentificationCompatible(15));
    // Same at the next odd inner side (31): both identifications hold.
    try std.testing.expect(mobiusIdentificationCompatible(31));
    try std.testing.expect(mirrorIdentificationCompatible(31));
    // Even inner sides are asymmetric about c = inner/2: face pairing
    // z=0 <-> z=inner-1 is NOT label-preserving at all.
    try std.testing.expect(!mobiusIdentificationCompatible(30));
    try std.testing.expect(!mirrorIdentificationCompatible(30));
}

test "image scale chain: 8^s canonical blocks, compounding shells" {
    const s0 = imageScale(0);
    try std.testing.expectEqual(@as(u64, 15), s0.interior_side);
    try std.testing.expectEqual(@as(u64, 16), s0.shell_side);
    try std.testing.expectEqual(@as(u64, 3375), s0.interior_volume);
    try std.testing.expectEqual(@as(u64, 1), s0.qubits);

    const s1 = imageScale(1);
    try std.testing.expectEqual(@as(u64, 30), s1.interior_side);
    try std.testing.expectEqual(@as(u64, 32), s1.shell_side);
    try std.testing.expectEqual(@as(u64, 27000), s1.interior_volume);
    try std.testing.expectEqual(@as(u64, 8), s1.qubits);

    const s2 = imageScale(2);
    try std.testing.expectEqual(@as(u64, 60), s2.interior_side);
    try std.testing.expectEqual(@as(u64, 216000), s2.interior_volume);
    try std.testing.expectEqual(@as(u64, 64), s2.qubits);

    const s3 = imageScale(3);
    try std.testing.expectEqual(@as(u64, 120), s3.interior_side);
    try std.testing.expectEqual(@as(u64, 1728000), s3.interior_volume);
    try std.testing.expectEqual(@as(u64, 512), s3.qubits);
    try std.testing.expectEqual(@as(u64, 128), s3.shell_side);
}

test "audit chain interior sides equal image shell sides shifted by one" {
    // lattice_constant_audit scale k interior (32,64,128,... at k=2..7)
    // is the image chain's compounding-shell side at image-index k-1.
    try std.testing.expectEqual(imageScale(1).shell_side, @as(u64, 32));
    try std.testing.expectEqual(imageScale(2).shell_side, @as(u64, 64));
    try std.testing.expectEqual(imageScale(3).shell_side, @as(u64, 128));
}

test "fibonacci cooling profile is a normalized phi^{-z} geometric" {
    const w = coolingProfile();
    // Strictly decreasing.
    for (1..15) |z| {
        try std.testing.expect(Q128.cmp(w[z], w[z - 1]) < 0);
    }
    // Sum to 1 within Q128 rounding slack (15 adds of ~2^-129 error).
    var sum = Q128.zero;
    for (w) |x| sum = sum.add(x);
    const eps = Q128.fromRatio(1, 1 << 60) catch unreachable;
    const diff = if (Q128.cmp(sum, Q128.one) >= 0) sum.sub(Q128.one) else Q128.one.sub(sum);
    try std.testing.expect(Q128.cmp(diff, eps) < 0);
    // w_0 close to 1/phi^2 = 2-phi ~= 0.381966 (slightly above, since the
    // finite sum is a little under the infinite phi^2 normalizer).
    const two = Q128.fromInteger(2);
    const w0_ref = two.sub(PHI);
    const lo = w0_ref.mul(Q128.fromRatio(999, 1000) catch unreachable);
    const hi = w0_ref.mul(Q128.fromRatio(1001, 1000) catch unreachable);
    try std.testing.expect(Q128.cmp(w[0], lo) > 0);
    try std.testing.expect(Q128.cmp(w[0], hi) < 0);
    // Ratio test: w_z * phi ~= w_{z-1} within Q128 rounding.
    const w1_times_phi = w[1].mul(PHI);
    const d2 = if (Q128.cmp(w1_times_phi, w[0]) >= 0) w1_times_phi.sub(w[0]) else w[0].sub(w1_times_phi);
    try std.testing.expect(Q128.cmp(d2, Q128.fromRatio(1, 1 << 40) catch unreachable) < 0);
}

test "center slice carries exactly 29 e0 cells: center + Manhattan diamond" {
    try std.testing.expectEqual(@as(u64, 29), sliceE0Count(15, 7));
    // The e0 set is the radius-8 Manhattan diamond |dx|+|dy|=8 plus the
    // center — 28 ring cells + 1, not an X pattern (|dx|=|dy| cells).
    try std.testing.expectEqual(@as(u64, 28), faceRingCount(15, 8, .l1));
}

test "face radial ring counts: L1 gives 4r, Linf gives 8r" {
    const l1 = [8]u64{ 1, 4, 8, 12, 16, 20, 24, 28 };
    const linf = [8]u64{ 1, 8, 16, 24, 32, 40, 48, 56 };
    for (0..8) |r| {
        try std.testing.expectEqual(l1[r], faceRingCount(15, @intCast(r), .l1));
        try std.testing.expectEqual(linf[r], faceRingCount(15, @intCast(r), .linf));
    }
}

test "label field is D4-symmetric: m=7 is excluded in the basisAt branch" {
    // Every slice of the interior is square-dihedral invariant, so its
    // angular spectrum has m = 0 (mod 4) content only. This is a
    // branch-scoped theorem about the basisAt instance, not a universal
    // falsification — the panels' m=7 field is a different branch.
    for (0..15) |z| {
        try std.testing.expect(faceFieldD4Invariant(15, @intCast(z)));
    }
}

test "init and legacy colorings are not D4-symmetric: m=7 stays open in those branches" {
    // Superposition scope: the exclusion of m=7 holds only where the D4
    // symmetry holds. The init/legacy ramp colorings preserve at most
    // one of the seven non-identity transforms, so m=7 angular content
    // is structurally POSSIBLE there — the donor claim is a separate
    // live branch, not a falsified one.
    const N: u16 = 15;
    const lattice = lattice_mod.Lattice.init();
    var init_preserved: usize = 0;
    var legacy_preserved: usize = 0;
    for (0..7) |w_idx| {
        const w: u3 = @intCast(w_idx + 1);
        var ok_init = true;
        var ok_legacy = true;
        for (0..N) |y| for (0..N) |x| {
            const p = d4Partner(N, @intCast(x), @intCast(y), w);
            const zi: usize = 7;
            const a = lattice.labels[lattice_mod.Lattice.indexUnsigned(@intCast(x), @intCast(y), zi)];
            const b = lattice.labels[lattice_mod.Lattice.indexUnsigned(p.x, p.y, zi)];
            if (a != b) ok_init = false;
            const la = qcomms.legacyState(@intCast(x), @intCast(y), @intCast(zi));
            const lb = qcomms.legacyState(@intCast(p.x), @intCast(p.y), @intCast(zi));
            if (la != lb) ok_legacy = false;
        };
        if (ok_init) init_preserved += 1;
        if (ok_legacy) legacy_preserved += 1;
    }
    try std.testing.expect(init_preserved <= 1);
    try std.testing.expect(legacy_preserved <= 1);
}

test "v11.0 ladder coordinates are integer rationals over F0 = 21" {
    // The panel values 5.25, 10.5, 21, 42, 21, 10.5 are the discretized
    // integer H21 scaled {1/4, 1/2, 1, 2, 1, 1/2} — verified in milli-
    // units against the stored rationals (not the triad value 21.10567).
    const milli = [6]u64{ 5250, 10500, 21000, 42000, 21000, 10500 };
    for (IMAGE_LADDER_COORDS, 0..) |lc, i| {
        try std.testing.expectEqual(milli[i], (lc.num * 1000) / lc.den);
    }
    try std.testing.expectEqual(@as(u64, 6), IMAGE_LADDER_COORDS.len);
    // c(6)/c(5) = 42/21 = 2 — the panel's C = E6/E5 = 2 identity.
    try std.testing.expectEqual(@as(u64, 2), IMAGE_LADDER_COORDS[3].num / IMAGE_LADDER_COORDS[2].num);
}

test "axiom 7 discretization: triad rounds to F0 = 21" {
    const t = try triad.evaluate(5, 2, -4);
    try std.testing.expect(!t.underflowed);
    // 20.5 < T < 21.5  =>  round(T) = 21.
    const lo = Q128.fromRatio(41, 2) catch unreachable;
    const hi = Q128.fromRatio(43, 2) catch unreachable;
    try std.testing.expect(Q128.cmp(t.magnitude, lo) > 0);
    try std.testing.expect(Q128.cmp(t.magnitude, hi) < 0);
    // "discretize 0.5%": |T-21|/21 ~= 0.503%  -> in (0.0045, 0.0055).
    const disc = t.magnitude.sub(Q128.fromInteger(21)).abs().div(Q128.fromInteger(21)) catch unreachable;
    try std.testing.expect(Q128.cmp(disc, Q128.fromRatio(45, 10000) catch unreachable) > 0);
    try std.testing.expect(Q128.cmp(disc, Q128.fromRatio(55, 10000) catch unreachable) < 0);
    // "measure 0.002%": |T-21.106114|/21.106114 ~= 0.0021% -> in (1e-5, 4e-5).
    const meas = Q128.fromRatio(21106114, 1000000) catch unreachable;
    const merr = t.magnitude.sub(meas).abs().div(meas) catch unreachable;
    try std.testing.expect(Q128.cmp(merr, Q128.fromRatio(1, 100000) catch unreachable) > 0);
    try std.testing.expect(Q128.cmp(merr, Q128.fromRatio(4, 100000) catch unreachable) < 0);
}

test "e-labels are Manhattan-octahedral shells, not Chebyshev cubes" {
    // Exact populations for inner=15, d=0..21 (clipped past d=7).
    const pops = [22]u64{
        1,   6,   18,  38,  66,  102, 146, 198,
        252, 296, 324, 336, 332, 312, 276, 224,
        168, 120, 80,  48,  24,  8,
    };
    var hist = [_]u64{0} ** 8;
    for (pops, 0..) |p, d| {
        try std.testing.expectEqual(p, l1ShellCount(15, @intCast(d)));
        hist[d % 8] += p;
    }
    // The mod-8 folding of shell populations IS the canonical histogram.
    try std.testing.expectEqual(tiers.histogram(15), hist);
    // e0 = shells {0,8,16} = 1+252+168 = 421 — the defect is the
    // observer singleton (pop 1 vs the 4d^2+2 octahedral pattern).
    try std.testing.expectEqual(@as(u64, 421), hist[0]);
    try std.testing.expectEqual(@as(u64, 6), l1ShellCount(15, 1));
    // Unclipped octahedron law 4d^2+2 holds through the radius-7 shell.
    for (1..8) |d| {
        const du: u64 = @intCast(d);
        try std.testing.expectEqual(4 * du * du + 2, l1ShellCount(15, @intCast(d)));
    }
}

test "hidden spheres: nearest shells to phi and pi are d2=3 (8) and d2=10 (24)" {
    try std.testing.expectEqual(@as(u64, 8), squaredRadiusCount(15, 3));
    try std.testing.expectEqual(@as(u64, 24), squaredRadiusCount(15, 10));
    try std.testing.expectEqual(@as(u64, 3), nearestRadiusShell(15, PHI));
    try std.testing.expectEqual(@as(u64, 10), nearestRadiusShell(15, PI));
    // Runner-up checks pin the argmin: next shells are strictly worse.
    // d2=2 -> 12 cells at sqrt2 (|1.414-1.618|=0.204), d2=9 -> 30 cells
    // at r=3 (|3-3.1416|=0.142).
    try std.testing.expectEqual(@as(u64, 12), squaredRadiusCount(15, 2));
    try std.testing.expectEqual(@as(u64, 30), squaredRadiusCount(15, 9));
}

test "fano e8 panel claims match the implemented anti-octonion algebra" {
    // "E8=E0 at Boundary": e8^2 = +e0.
    const e8sq = anti.mul(anti.unit(8), anti.unit(8));
    try std.testing.expectEqual(anti.unit(0), e8sq);
    // "E8=E1 Closure": e8 acts as identity on octonion units — e8*e1 = e1.
    try std.testing.expectEqual(anti.unit(1), anti.mul(anti.unit(8), anti.unit(1)));
    try std.testing.expectEqual(anti.unit(1), anti.mul(anti.unit(1), anti.unit(8)));
    // Boundary correction: e8 commutes with EVERY octonion unit — the
    // panel's "all commutativity lost" is contradicted by the algebra.
    for (0..8) |i| {
        try std.testing.expect(std.meta.eql(anti.zero(), anti.commutator(anti.unit(8), anti.unit(i))));
    }
}

test "constant tiers carry phi and pi, rational tiers carry F0=21" {
    try std.testing.expectEqual(Q128.zero, IMAGE_LADDER_CONSTANT_TIERS[0].value);
    try std.testing.expectEqual(PHI.raw, IMAGE_LADDER_CONSTANT_TIERS[1].value.raw);
    try std.testing.expectEqual(PI.raw, IMAGE_LADDER_CONSTANT_TIERS[2].value.raw);
}

test "all-15-layer panel: 8 distinct patterns, mirrored pairs" {
    try std.testing.expectEqual(@as(usize, 8), distinctSlicePatterns(15));
    // Mirrored slices carry identical patterns (z <-> 14-z).
    for (0..15) |z| {
        try std.testing.expectEqual(
            slicePatternDigest(15, @intCast(z)),
            slicePatternDigest(15, @intCast(14 - z)),
        );
    }
    // Additive law: label(x,y,z) = (2D-L1(x,y) + |z-7|) mod 8 — the
    // slices are cyclic shifts of the center slice's field.
    const z: u16 = 3;
    var x: u16 = 0;
    while (x < 15) : (x += 1) {
        var y: u16 = 0;
        while (y < 15) : (y += 1) {
            const shifted: u3 = @intCast((tiers.basisAt(x, y, 7, 15) + (7 - z)) & 7);
            try std.testing.expectEqual(shifted, tiers.basisAt(x, y, z, 15));
        }
    }
}

test "cayley-dickson Start->End chain is a palindrome peaking at 6D" {
    // Chain nodes: 5.25, 10.5, 21, 42, 21, 10.5, 5.25 — mirror at index 3.
    try std.testing.expectEqual(@as(usize, 7), H21_CHAIN.len);
    for (0..7) |i| {
        const j = 6 - i;
        try std.testing.expectEqual(H21_CHAIN[i].num, H21_CHAIN[j].num);
        try std.testing.expectEqual(H21_CHAIN[i].den, H21_CHAIN[j].den);
    }
    // Apex is 42 = 2*H21 at the 6D mirror — exactly 8x the chain ends
    // (42 / 5.25 = 8, the octonion dimension).
    try std.testing.expectEqual(@as(u64, 42), H21_CHAIN[3].num);
    try std.testing.expectEqual(@as(u64, 8), (H21_CHAIN[3].num * H21_CHAIN[0].den) / (H21_CHAIN[0].num * H21_CHAIN[3].den));
    // Matches the ladder coordinates: chain nodes 0..5 are c(3)..c(8)
    // offset — c(3)=21/4, c(4)=21/2, c(5)=21, c(6)=42, c(7)=21, c(8)=21/2.
    for (IMAGE_LADDER_COORDS, 0..) |lc, i| {
        try std.testing.expectEqual(H21_CHAIN[i].num, lc.num);
        try std.testing.expectEqual(H21_CHAIN[i].den, lc.den);
    }
}

test "E8 root presentations: standard 112+128 vs octavian 16+112+112" {
    // Both decompositions are exact for the 240-root system; the image
    // uses the textbook D8+half-spin split, the overlay is Fano-derived.
    try std.testing.expectEqual(@as(u64, 240), 112 + 128);
    try std.testing.expectEqual(@as(u64, 240), 16 + 112 + 112);
    try std.testing.expectEqual(@as(u64, 240), 15 * 16); // 15*16 = 240 anchor
}

test "e7->e2 closure is the Fano line (2,5,7) cyclic product e5*e7 = +e2" {
    const p = oct.mul(5, 7);
    try std.testing.expectEqual(@as(i2, 1), p.sign);
    try std.testing.expectEqual(@as(oct.Unit, 2), p.unit);
    // Full cycle e2->e5->e7->e2: e2*e5 = +e7 and e7*e2 = +e5.
    try std.testing.expectEqual(@as(oct.Unit, 7), oct.mul(2, 5).unit);
    try std.testing.expectEqual(@as(oct.Unit, 5), oct.mul(7, 2).unit);
}

test "L15/L16 face topology: adjacent blocks share the inner face plane" {
    // 2x2x2 arrangement in 30^3: interface at coord 15 between the
    // offset-0 block (x in 0..14) and the offset-15 block (x in 15..29).
    try std.testing.expectEqual(@as(u16, 15), blockInterfaceCoord(15));
    // Each block: 3 touching + 3 exterior faces.
    try std.testing.expectEqual(@as(u8, 3), BLOCK_TOUCHING_FACES);
    try std.testing.expectEqual(@as(u8, 3), BLOCK_EXTERIOR_FACES);
    // Exterior sits at arrangement bounds 0 and 29; the compounding shell
    // attaches at coord 30 (= 2*inner).
    const inner: u16 = 15;
    try std.testing.expectEqual(@as(u16, 30), 2 * inner);
}
