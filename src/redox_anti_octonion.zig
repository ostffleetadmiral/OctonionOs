//! 9D anti-octonion — the octonion algebra plus a commuting "anti" unit.
//!
//! Ported from the E=mc² workspace (`hardware/src/anti_octonion.zig`),
//! re-expressed on this repo's `redox_octonion` Fano table:
//!   - e0..e7: standard octonion basis (e_i^2 = -1 for i > 0)
//!   - e8: anti/scaling element, e8^2 = +e0 (split signature)
//!   - e8 commutes with every octonion element: e8 x e_i = e_i x e8 = e_i
//!
//! The anti element does not repair the octonion defects: commutator and
//! associator remain generically nonzero on the e1..e7 subspace.
//!
//! Classification: EXACT_MATH.
const std = @import("std");
const oct = @import("redox_octonion.zig");

pub const Anti = [9]i512;
pub const DIM: usize = 9;
pub const E8: usize = 8;

const UnitProduct = struct { sign: i2, unit: u4, nilpotent_zero: bool };

fn unitMul(a: u4, b: u4) UnitProduct {
    if (a == E8 and b == E8) return .{ .sign = 1, .unit = 0, .nilpotent_zero = false };
    if (a == E8) return .{ .sign = 1, .unit = b, .nilpotent_zero = false };
    if (b == E8) return .{ .sign = 1, .unit = a, .nilpotent_zero = false };
    const p = oct.mul(@intCast(a), @intCast(b));
    return .{ .sign = p.sign, .unit = p.unit, .nilpotent_zero = false };
}

pub fn zero() Anti {
    return [_]i512{0} ** 9;
}

pub fn unit(index: usize) Anti {
    var v = zero();
    v[index] = 1;
    return v;
}

pub fn add(a: Anti, b: Anti) Anti {
    var out = zero();
    for (0..9) |i| out[i] = a[i] + b[i];
    return out;
}

pub fn sub(a: Anti, b: Anti) Anti {
    var out = zero();
    for (0..9) |i| out[i] = a[i] - b[i];
    return out;
}

pub fn mul(a: Anti, b: Anti) Anti {
    var out = zero();
    for (0..9) |i| {
        if (a[i] == 0) continue;
        for (0..9) |j| {
            if (b[j] == 0) continue;
            const p = unitMul(@intCast(i), @intCast(j));
            if (p.nilpotent_zero) continue;
            out[p.unit] += a[i] * b[j] * @as(i512, p.sign);
        }
    }
    return out;
}

pub fn normSquared(v: Anti) i512 {
    var n: i512 = 0;
    for (v) |c| n += c * c;
    return n;
}

pub fn commutator(a: Anti, b: Anti) Anti {
    return sub(mul(a, b), mul(b, a));
}

pub fn associator(a: Anti, b: Anti, c: Anti) Anti {
    return sub(mul(mul(a, b), c), mul(a, mul(b, c)));
}

/// Restriction check: products of e0..e7 stay inside e0..e7.
pub fn inOctonionSubalgebra(v: Anti) bool {
    return v[8] == 0;
}

test "e8 squared is +e0 (split signature)" {
    var expect = zero();
    expect[0] = 1;
    try std.testing.expectEqual(expect, mul(unit(8), unit(8)));
}

test "e8 commutes with every octonion unit" {
    for (0..8) |i| {
        try std.testing.expectEqual(zero(), commutator(unit(8), unit(i)));
    }
}

test "octonion multiplication is preserved on e0..e7" {
    // e1*e2 = e3, e_i^2 = -e0 — identical to the octonion table.
    try std.testing.expectEqual(unit(3), mul(unit(1), unit(2)));
    for (1..8) |i| {
        var expect = zero();
        expect[0] = -1;
        try std.testing.expectEqual(expect, mul(unit(i), unit(i)));
    }
    for (0..8) |i| for (0..8) |j| {
        try std.testing.expect(inOctonionSubalgebra(mul(unit(i), unit(j))));
    };
}

test "commutator and associator survive inside the octonion part" {
    try std.testing.expectEqual(@as(i512, 4), normSquared(commutator(unit(1), unit(2))));
    // Same witness as octonion: [e1,e2,e4] = 2e7.
    try std.testing.expectEqual(@as(i512, 4), normSquared(associator(unit(1), unit(2), unit(4))));
}
