//! Fixed-point precision rungs paired with lattice-side scaling.
//!
//! The family fixed-point ladder runs i32q16 -> i64q32 -> i128q64 ->
//! i256q128 -> i512q256: each rung doubles both the raw integer width
//! and the fractional width (raw_bits = 2 * frac_bits). The lattice
//! side ladder runs 16^3 -> 32^3 -> 64^3 -> 128^3 -> 256^3 -> 512^3.
//!
//! Pairing convention (model metadata, not a verified physical law):
//! shell side 16 uses i32q16, 32 uses i64q32, 64 uses i128q64,
//! 128 uses i256q128, and 256/512 saturate at i512q256 — the widest
//! rung in the family (REDOX-1.0 i512Q256.256). Donor evidence:
//! codec/fx.py maps Q64.64->i128, Q128.128->i256, Q256.256->i512;
//! Rations src/fixedpoint/i256q128.zig and hardware/src/fixed_point.zig
//! supply the i256q128 rung; i512Q256.256RedOx supplies i512q256.
const std = @import("std");

pub const PrecisionRung = struct {
    name: []const u8,
    raw_bits: u16,
    frac_bits: u16,
    raw_type: []const u8,
    /// Largest lattice shell side this rung is paired with.
    max_shell_side: u16,
};

pub const PRECISION_LADDER = [_]PrecisionRung{
    .{ .name = "i32q16", .raw_bits = 32, .frac_bits = 16, .raw_type = "i32", .max_shell_side = 16 },
    .{ .name = "i64q32", .raw_bits = 64, .frac_bits = 32, .raw_type = "i64", .max_shell_side = 32 },
    .{ .name = "i128q64", .raw_bits = 128, .frac_bits = 64, .raw_type = "i128", .max_shell_side = 64 },
    .{ .name = "i256q128", .raw_bits = 256, .frac_bits = 128, .raw_type = "i256", .max_shell_side = 128 },
    .{ .name = "i512q256", .raw_bits = 512, .frac_bits = 256, .raw_type = "i512", .max_shell_side = 512 },
};

/// Lattice shell sides from 16^3 through 512^3 (powers of two).
pub const LATTICE_SIDES = [_]u16{ 16, 32, 64, 128, 256, 512 };

/// Canonical interior/shell pairs: shell side s pairs with inner
/// s - s/16, preserving the 16/15 ratio of the base 15^3/16^3 pair.
pub const CanonicalPair = struct { inner: u16, shell: u16 };

pub fn canonicalInner(shell: u16) u16 {
    return shell - shell / 16;
}

pub fn canonicalPairs() [LATTICE_SIDES.len]CanonicalPair {
    var out: [LATTICE_SIDES.len]CanonicalPair = undefined;
    for (LATTICE_SIDES, 0..) |shell, i| {
        out[i] = .{ .inner = canonicalInner(shell), .shell = shell };
    }
    return out;
}

/// The precision rung paired with a lattice shell side. Sides above
/// 256 saturate at the top rung i512q256.
pub fn rungForShell(side: u16) PrecisionRung {
    for (PRECISION_LADDER) |rung| {
        if (side <= rung.max_shell_side) return rung;
    }
    return PRECISION_LADDER[PRECISION_LADDER.len - 1];
}

pub fn volume(side: u16) u64 {
    const s: u64 = side;
    return s * s * s;
}

pub fn foamCount(inner: u16, shell: u16) u64 {
    return volume(shell) - volume(inner);
}

test "precision rungs double raw and fractional width each step" {
    try std.testing.expectEqual(@as(usize, 5), PRECISION_LADDER.len);
    for (PRECISION_LADDER, 0..) |rung, i| {
        try std.testing.expectEqual(rung.frac_bits * 2, rung.raw_bits);
        if (i > 0) {
            const prev = PRECISION_LADDER[i - 1];
            try std.testing.expectEqual(prev.raw_bits * 2, rung.raw_bits);
            try std.testing.expectEqual(prev.frac_bits * 2, rung.frac_bits);
        }
    }
    try std.testing.expectEqualStrings("i512q256", PRECISION_LADDER[4].name);
}

test "lattice sides run 16^3 through 512^3" {
    try std.testing.expectEqual(@as(usize, 6), LATTICE_SIDES.len);
    try std.testing.expectEqual(@as(u16, 16), LATTICE_SIDES[0]);
    try std.testing.expectEqual(@as(u16, 512), LATTICE_SIDES[LATTICE_SIDES.len - 1]);
    for (LATTICE_SIDES) |side| {
        try std.testing.expect(side != 0 and (side & (side - 1)) == 0);
    }
}

test "canonical pairs preserve the 15/16 shell ratio through 512" {
    const pairs = canonicalPairs();
    try std.testing.expectEqual(@as(u16, 15), pairs[0].inner);
    try std.testing.expectEqual(@as(u16, 16), pairs[0].shell);
    try std.testing.expectEqual(@as(u16, 480), pairs[5].inner);
    try std.testing.expectEqual(@as(u16, 512), pairs[5].shell);
    for (pairs) |p| {
        // shell/inner == 16/15 exactly: 16*inner == 15*shell
        try std.testing.expectEqual(@as(u32, 16) * p.inner, @as(u32, 15) * p.shell);
        // boundary/inner^3 == 721/3375 exactly (cross-multiplied, no division)
        const foam = foamCount(p.inner, p.shell);
        const iv: u128 = @as(u128, p.inner) * p.inner * p.inner;
        try std.testing.expectEqual(@as(u128, foam) * 3375, @as(u128, 721) * iv);
    }
}

test "shell volumes and precision pairing are exact" {
    try std.testing.expectEqual(@as(u64, 4096), volume(16));
    try std.testing.expectEqual(@as(u64, 134217728), volume(512));
    try std.testing.expectEqualStrings("i32q16", rungForShell(16).name);
    try std.testing.expectEqualStrings("i64q32", rungForShell(32).name);
    try std.testing.expectEqualStrings("i128q64", rungForShell(64).name);
    try std.testing.expectEqualStrings("i256q128", rungForShell(128).name);
    try std.testing.expectEqualStrings("i512q256", rungForShell(256).name);
    try std.testing.expectEqualStrings("i512q256", rungForShell(512).name);
}
