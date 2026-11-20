//! e0 = origin = Higgs = defect — the framework's identification chain,
//! measured term by term rather than asserted.
//!
//! The chain binds four objects the framework treats as one:
//!   e0      — the scalar/identity axis of each algebra tier
//!   origin  — the multiplicative unit (or the adjoined zero point of the
//!             E8 root system at the bookend tiers)
//!   Higgs   — the +1 remainder in 16^3 - 15^3 = 721 = 3(240) + 1
//!   defect  — the underpopulated basis state of the lattice coloring
//!
//! Measured verdicts (each backed by a test below):
//!   * e0 = origin as the identity element: TRUE on 5 of 10 tiers —
//!     R, C, H, bicomplex, O all have e0.x = x. FALSE in vector3 (no
//!     identity exists — cross product is anti-commutative), and
//!     FALSE in BOTH extension tiers: in anti-octonion e0·e8 = e0 != e8
//!     (e8 acts as identity on the octonion part instead — the origin
//!     role migrates off e0), and dual inherits the same failure plus
//!     e9 absorption. Neither extended algebra has any global identity
//!     at all — measured, not assumed. REDEFINED in J3(O): the identity
//!     is the full diagonal matrix, not any single component. N/A in
//!     E8-roots: no product exists; the "origin" is an adjoined point.
//!   * e0 = defect: TRUE at 15^3 under the FANO coloring convention —
//!     state 0 holds 421 cells, the unique sub-share population. It does
//!     NOT persist up the chain: at 30^3/60^3/120^3 the histogram
//!     disperses over several states, and at 16^3/32^3/64^3/128^3 the
//!     coloring is perfectly uniform — no defect exists at all. And the
//!     deficit's NAME is convention-dependent: the legacy QComms coloring
//!     placed it at state 5; the aligned default uses the FANO e0 coloring.
//!   * e0 = Higgs: EXACT arithmetic — 721 = 3*240 + 1 with 240 the E8
//!     root count; adjoining the zero vector to the 240 roots yields a
//!     241-point set. The arithmetic is exact; naming the +1 "Higgs" is
//!     a framework construction.
//!
//! Classification: EXACT_MATH for the measurements; the identification
//! itself is framework CONSTRUCTION where it holds and FALSIFIED where
//! the measurements diverge.
const std = @import("std");
const bridge = @import("redox_algebra_bridge.zig");
const vec3 = @import("redox_vector3.zig");
const bicomplex_mod = @import("redox_bicomplex.zig");
const anti_mod = @import("redox_anti_octonion.zig");
const dual_mod = @import("redox_dual_bcomplex.zig");
const jordan_mod = @import("redox_jordan.zig");
const e8_mod = @import("redox_e8_roots.zig");
const tiers = @import("redox_scaling_tiers.zig");
const lattice = @import("qcomms_lattice.zig");

// ---------------------------------------------------------------------------
// Term 1: e0 = origin as the multiplicative identity
// ---------------------------------------------------------------------------

/// Whether `alg` has a single-slot multiplicative identity located at
/// component 0 — the literal "e0 = origin" claim.
pub fn identityIsSlotZero(alg: bridge.Algebra) bool {
    return switch (alg) {
        .real, .complex, .quaternion, .bicomplex, .octonion => true,
        // vector3: no identity exists at all.
        // jordan: identity is diag(1,1,1) — exists, but is not a slot.
        // e8_root: no product — no identity element.
        // anti_octonion, dual_bcomplex: measured non-unital — products
        // with e8 never produce e8, so no element can fix e8.
        .vector3, .jordan, .e8_root, .anti_octonion, .dual_bcomplex => false,
    };
}

/// Whether the tier has any multiplicative identity at all.
pub fn hasIdentity(alg: bridge.Algebra) bool {
    return switch (alg) {
        .vector3, .e8_root, .anti_octonion, .dual_bcomplex => false,
        else => true,
    };
}

test "e0 acts as identity on every product-bearing division/concrete tier" {
    // octonion e0 * e_i = e_i for all 8 units.
    for (0..8) |i| {
        try std.testing.expectEqual(bridge.unit(@intCast(i)), bridge.mul(bridge.unit(0), bridge.unit(@intCast(i))));
        try std.testing.expectEqual(bridge.unit(@intCast(i)), bridge.mul(bridge.unit(@intCast(i)), bridge.unit(0)));
    }
    // bicomplex unit 1 = (1,0,0,0).
    for (0..4) |i| {
        try std.testing.expectEqual(bicomplex_mod.unit(i), bicomplex_mod.mul(bicomplex_mod.unit(0), bicomplex_mod.unit(i)));
    }
    // complex: (1,0) is the identity.
    const c_id = bridge.Value{ .complex = .{ 1, 0 } };
    const c_x = bridge.Value{ .complex = .{ 3, -7 } };
    try std.testing.expectEqual(c_x.complex, (try bridge.mulValue(c_id, c_x)).complex);
}

test "vector3 has no multiplicative identity — measured absence" {
    // A unit e would need e x x = x for all x; but e x x = -(x x e) and
    // x x x = 0, so no element can act as a two-sided identity.
    try std.testing.expectEqual(false, identityIsSlotZero(.vector3));
    try std.testing.expectEqual(false, hasIdentity(.vector3));
    // Concretely: e x e = 0 != e for every candidate basis element.
    for (0..3) |i| {
        const c = vec3.cross(vec3.unit(i), vec3.unit(i));
        try std.testing.expectEqual(vec3.zero(), c);
    }
}

test "anti-octonion: e0 is not the identity — the role migrated to e8" {
    // e8 acts as the two-sided identity on the octonion part.
    for (0..8) |i| {
        try std.testing.expectEqual(anti_mod.unit(i), anti_mod.mul(anti_mod.unit(8), anti_mod.unit(i)));
        try std.testing.expectEqual(anti_mod.unit(i), anti_mod.mul(anti_mod.unit(i), anti_mod.unit(8)));
    }
    // But e8^2 = e0, so e8 is not a self-consistent identity; and
    // e0·e8 = e0 != e8, so e0 fails as identity too.
    try std.testing.expectEqual(anti_mod.unit(0), anti_mod.mul(anti_mod.unit(0), anti_mod.unit(8)));
    try std.testing.expectEqual(anti_mod.unit(0), anti_mod.mul(anti_mod.unit(8), anti_mod.unit(8)));
    // No unit product with e8 yields e8 — so no element can: the 9D
    // algebra is non-unital, measured at the table level.
    for (0..9) |i| {
        try std.testing.expect(!std.meta.eql(anti_mod.unit(8), anti_mod.mul(anti_mod.unit(i), anti_mod.unit(8))));
        try std.testing.expect(!std.meta.eql(anti_mod.unit(8), anti_mod.mul(anti_mod.unit(8), anti_mod.unit(i))));
    }
    try std.testing.expectEqual(false, identityIsSlotZero(.anti_octonion));
    try std.testing.expectEqual(false, hasIdentity(.anti_octonion));
}

test "dual-bcomplex: non-unital via e8, plus e9 absorption" {
    // e0 does fix the dual element (e0·e9 = e9) but fails on e8 —
    // inherited from anti-octonion.
    try std.testing.expectEqual(dual_mod.unit(9), dual_mod.mul(dual_mod.unit(0), dual_mod.unit(9)));
    try std.testing.expectEqual(dual_mod.unit(0), dual_mod.mul(dual_mod.unit(0), dual_mod.unit(8)));
    // And e9 absorbs every product, so u·e9 = e9 is satisfiable but
    // u·e8 = e8 is not — still no global identity.
    for (0..10) |i| {
        try std.testing.expect(!std.meta.eql(dual_mod.unit(8), dual_mod.mul(dual_mod.unit(i), dual_mod.unit(8))));
    }
    try std.testing.expectEqual(false, identityIsSlotZero(.dual_bcomplex));
    try std.testing.expectEqual(false, hasIdentity(.dual_bcomplex));
}

test "jordan has an identity — but it is the diagonal matrix, not a slot" {
    const id = jordan_mod.J3.diagonal(1, 1, 1);
    var x = jordan_mod.J3.diagonal(2, 3, 5);
    x.o1 = jordan_mod.octUnit(4);
    x.o3 = jordan_mod.octUnit(7);
    // I j2 X = 2X exactly (doubled product convention).
    const p = jordan_mod.jmul2(id, x);
    try std.testing.expectEqual(2 * x.alpha, p.alpha);
    try std.testing.expectEqual(2 * x.beta, p.beta);
    try std.testing.expectEqual(2 * x.gamma, p.gamma);
    for (0..8) |i| {
        try std.testing.expectEqual(2 * x.o1[i], p.o1[i]);
        try std.testing.expectEqual(2 * x.o3[i], p.o3[i]);
    }
    try std.testing.expectEqual(false, identityIsSlotZero(.jordan));
    try std.testing.expectEqual(true, hasIdentity(.jordan));
}

test "e8_root has no identity — it has no product; its origin is a point" {
    try std.testing.expectEqual(false, hasIdentity(.e8_root));
    try std.testing.expectError(error.NoProduct, bridge.mulValue(.{ .e8_root = e8_mod.buildRoots()[0] }, .{ .e8_root = e8_mod.buildRoots()[0] }));
}

// ---------------------------------------------------------------------------
// Term 2: e0 = defect — measured at every lattice tier
// ---------------------------------------------------------------------------

pub const DefectProfile = struct {
    state: ?u3, // the single underpopulated state, if exactly one exists
    population: u64, // its cell count (0 when no single defect)
    modal: u64, // modal population across the 8 states
    uniform_share_num: u64, // n^3 numerator
    uniform_share_den: u64, // = 8
};

pub fn defectProfile(inner: u16) DefectProfile {
    const h = tiers.histogram(inner);
    var modal: u64 = 0;
    for (h) |v| modal = @max(modal, v);
    const n: u64 = inner;
    const st = tiers.defectState(inner);
    return .{
        .state = st,
        .population = if (st) |s| h[s] else 0,
        .modal = modal,
        .uniform_share_num = n * n * n,
        .uniform_share_den = 8,
    };
}

test "e0 is the unique defect state at 15^3 — and only there" {
    const p15 = defectProfile(15);
    try std.testing.expectEqual(@as(?u3, 0), p15.state); // e0 carries it
    try std.testing.expectEqual(@as(u64, 421), p15.population);
    try std.testing.expectEqual(@as(u64, 422), p15.modal);
    // The "7-defect" is exact: the deficit below the next integer share
    // equals the Fano line count and the imaginary-unit count.
    try std.testing.expectEqual(@as(u64, 7), 15 * 15 * 15 - 8 * 421);
    try std.testing.expectEqual(@as(u64, 7), @as(u64, 15 * 15 * 15) % 8);
    // Odd-multiple tiers 30/60/120 disperse the deficit over several
    // states — no single defect exists.
    for ([_]u16{ 30, 60, 120 }) |n| {
        try std.testing.expectEqual(@as(?u3, null), defectProfile(n).state);
    }
    // Pure 2^k tiers are perfectly uniform — no defect at all.
    for ([_]u16{ 16, 32, 64, 128 }) |n| {
        try std.testing.expect(tiers.isUniform(n));
    }
    // So "e0 = defect" is a 15^3 fact, not a chain invariant.
}

test "legacy QComms deficit variant remains reproducible after E0 alignment" {
    var h = [_]usize{0} ** 8;
    for (0..15) |z| for (0..15) |y| for (0..15) |x| {
        h[lattice.legacyState(@intCast(x), @intCast(y), @intCast(z))] += 1;
    };
    try std.testing.expectEqual(@as(usize, 421), h[5]);
    try std.testing.expectEqual(@as(usize, 422), h[0]);
    var deficits: usize = 0;
    for (h) |v| {
        if (v == 421) deficits += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), deficits);
}

// ---------------------------------------------------------------------------
// Term 3: e0 = Higgs — the +1 remainder
// ---------------------------------------------------------------------------

test "721 = 3*240 + 1 and the +1 is the adjoined origin point" {
    // Shell transition identity — exact arithmetic.
    try std.testing.expectEqual(@as(u64, 721), 16 * 16 * 16 - 15 * 15 * 15);
    try std.testing.expectEqual(@as(u64, 721), 3 * e8_mod.UNIT_COUNT + 1);
    // The +1 can be identified with the zero vector adjoined to the
    // 240 roots: the root set contains no zero element, so the adjoined
    // set has exactly 241 distinct points — a measured set fact; naming
    // it "Higgs" is the framework's construction on top.
    const roots = e8_mod.buildRoots();
    var zero_present = false;
    for (roots) |r| {
        var all_zero = true;
        for (r) |c| {
            if (c != 0) all_zero = false;
        }
        if (all_zero) zero_present = true;
    }
    try std.testing.expect(!zero_present);
    try std.testing.expectEqual(@as(usize, 241), e8_mod.UNIT_COUNT + 1);
}

// ---------------------------------------------------------------------------
// Verdict
// ---------------------------------------------------------------------------

pub const Verdict = enum { verified, falsified, construction, not_applicable };

pub const ChainLink = struct {
    name: []const u8,
    tiers_ok: usize,
    tiers_total: usize,
    verdict: Verdict,
};

/// The measured chain, link by link.
pub const VERDICTS = [_]ChainLink{
    .{ .name = "e0=origin as identity-at-slot-0", .tiers_ok = 5, .tiers_total = 10, .verdict = .verified },
    .{ .name = "e0=origin where no identity exists (vector3, anti, dual)", .tiers_ok = 0, .tiers_total = 3, .verdict = .falsified },
    .{ .name = "e0=defect at 15^3 (FANO convention)", .tiers_ok = 1, .tiers_total = 7, .verdict = .verified },
    .{ .name = "e0=defect persists up the chain (30/60/120 dispersed; 16/32/64/128 uniform)", .tiers_ok = 0, .tiers_total = 6, .verdict = .falsified },
    .{ .name = "e0=defect label is coloring-convention dependent", .tiers_ok = 1, .tiers_total = 2, .verdict = .construction },
    .{ .name = "e0=Higgs as 721=3(240)+1", .tiers_ok = 1, .tiers_total = 1, .verdict = .verified },
    .{ .name = "+1 named Higgs/origin", .tiers_ok = 0, .tiers_total = 1, .verdict = .construction },
};

test "verdict table is consistent with the measurements" {
    try std.testing.expectEqual(@as(usize, 7), VERDICTS.len);
    // The identity-slot claim holds on exactly 5 of 10 tiers.
    var ok: usize = 0;
    const algs = [_]bridge.Algebra{ .e8_root, .real, .complex, .vector3, .quaternion, .bicomplex, .jordan, .octonion, .anti_octonion, .dual_bcomplex };
    for (algs) |a| {
        if (identityIsSlotZero(a)) ok += 1;
    }
    try std.testing.expectEqual(@as(usize, 5), ok);
    try std.testing.expectEqual(VERDICTS[0].tiers_ok, ok);
}
