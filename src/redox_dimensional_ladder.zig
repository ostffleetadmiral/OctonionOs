//! Declared dimensional ladder metadata; labels are model metadata, not physics.
//! The full layout is E0..E10 with the E8 root system bookending the chain:
//!
//!   E0  E8 roots          E6  Jordan algebra J3(O)
//!   E1  real numbers      E7  octonions
//!   E2  complex numbers   E8  E8 roots (same algebra as E0)
//!   E3  3D vector algebra E9  anti-octonions
//!   E4  quaternions       E10 dual-B-complex numbers
//!   E5  bicomplex numbers
//!
//! Each tier maps onto a measured algebra in `redox_algebra_bridge` — the
//! ladder indices are framework labels, NOT real dimensions: bicomplex_5d
//! has real dimension 4, jordan_6d has real dimension 27, octonion_7d has
//! real dimension 8. The E8-root tiers carry reflection structure, not a
//! bilinear product (`hasProduct() == false` is the measured fact).
const std = @import("std");
const bridge = @import("redox_algebra_bridge.zig");

pub const Tier = enum {
    e8_root_0d,
    real_1d,
    complex_2d,
    vector_3d,
    quaternion_4d,
    bicomplex_5d,
    jordan_6d,
    octonion_7d,
    e8_root_8d,
    anti_octonion_9d,
    dual_bcomplex_10d,
};
pub const LADDER = [_]Tier{
    .e8_root_0d,
    .real_1d,
    .complex_2d,
    .vector_3d,
    .quaternion_4d,
    .bicomplex_5d,
    .jordan_6d,
    .octonion_7d,
    .e8_root_8d,
    .anti_octonion_9d,
    .dual_bcomplex_10d,
};

pub fn name(tier: Tier) []const u8 {
    return switch (tier) {
        .e8_root_0d => "e0/E8-roots",
        .real_1d => "e1/real",
        .complex_2d => "e2/complex",
        .vector_3d => "e3/vector",
        .quaternion_4d => "e4/quaternion",
        .bicomplex_5d => "e5/bicomplex",
        .jordan_6d => "e6/jordan",
        .octonion_7d => "e7/octonion",
        .e8_root_8d => "e8/E8-roots",
        .anti_octonion_9d => "e9/anti-octonion",
        .dual_bcomplex_10d => "e10/dual-bcomplex",
    };
}

/// The measured algebra behind each ladder label. E0 and E8 resolve to
/// the same algebra — the bookends are the E8 root system twice.
pub fn algebra(tier: Tier) bridge.Algebra {
    return switch (tier) {
        .e8_root_0d => .e8_root,
        .real_1d => .real,
        .complex_2d => .complex,
        .vector_3d => .vector3,
        .quaternion_4d => .quaternion,
        .bicomplex_5d => .bicomplex,
        .jordan_6d => .jordan,
        .octonion_7d => .octonion,
        .e8_root_8d => .e8_root,
        .anti_octonion_9d => .anti_octonion,
        .dual_bcomplex_10d => .dual_bcomplex,
    };
}

test "dimensional ladder has 11 positions with E8-root bookends" {
    try std.testing.expectEqual(@as(usize, 11), LADDER.len);
    try std.testing.expectEqualStrings("e0/E8-roots", name(.e8_root_0d));
    try std.testing.expectEqualStrings("e8/E8-roots", name(.e8_root_8d));
    try std.testing.expectEqualStrings("e10/dual-bcomplex", name(.dual_bcomplex_10d));
}

test "every ladder tier resolves to a measured algebra" {
    for (LADDER) |tier| {
        const alg = algebra(tier);
        // Real dimensions are measured, not the label index:
        // e5 labels a 4-real-dim algebra, e6 a 27-dim one, e7 an 8-dim one.
        try std.testing.expect(alg.realDim() < 32);
    }
    try std.testing.expectEqual(@as(usize, 4), bridge.Algebra.bicomplex.realDim());
    try std.testing.expectEqual(@as(usize, 27), bridge.Algebra.jordan.realDim());
    try std.testing.expectEqual(@as(usize, 8), bridge.Algebra.octonion.realDim());
}

test "E0 and E8 are the same algebra — the ladder is bookended" {
    try std.testing.expectEqual(algebra(.e8_root_0d), algebra(.e8_root_8d));
    try std.testing.expectEqual(false, algebra(.e8_root_0d).hasProduct());
    // The bookend tiers border octonion (E7) below and anti-octonion (E9)
    // above — edges exist in both directions of the spine.
    try std.testing.expect(bridge.edgeKind(.octonion, .e8_root) != null);
    try std.testing.expect(bridge.edgeKind(.e8_root, .anti_octonion) != null);
}
