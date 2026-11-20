//! 10D dual-B-complex — anti-octonion plus a nilpotent "dual" unit.
//!
//! Ported from the E=mc² workspace (`hardware/src/dual_b_complex.zig`),
//! re-expressed on this repo's `redox_octonion`/`redox_anti_octonion`
//! tables:
//!   - e0..e8: anti-octonion basis (e8^2 = +e0, commutes)
//!   - e9: dual element, e9^2 = 0 (nilpotent, like dual-number epsilon)
//!   - e9 is absorbing: e9 x e_i = e_i x e9 = e9 for every i != 9
//!
//! The dual element is a zero divisor of a stronger kind — nilpotent —
//! so this algebra is even further from a division algebra than the
//! bicomplex numbers. Octonion non-commutativity and non-associativity
//! survive untouched inside e1..e7.
//!
//! Classification: EXACT_MATH.
const std = @import("std");
const anti = @import("redox_anti_octonion.zig");

pub const Dual = [10]i512;
pub const DIM: usize = 10;
pub const E9: usize = 9;

const UnitProduct = struct { sign: i2, unit: u4, nilpotent_zero: bool };

fn unitMul(a: u4, b: u4) UnitProduct {
    if (a == E9 and b == E9) return .{ .sign = 0, .unit = 0, .nilpotent_zero = true };
    if (a == E9) return .{ .sign = 1, .unit = E9, .nilpotent_zero = false };
    if (b == E9) return .{ .sign = 1, .unit = E9, .nilpotent_zero = false };
    // e0..e8 multiply by the anti-octonion rule: compute a full Anti product.
    var va = anti.zero();
    var vb = anti.zero();
    va[a] = 1;
    vb[b] = 1;
    const p = anti.mul(va, vb);
    for (0..9) |u| {
        if (p[u] != 0) return .{ .sign = @intCast(p[u]), .unit = @intCast(u), .nilpotent_zero = false };
    }
    return .{ .sign = 0, .unit = 0, .nilpotent_zero = true };
}

pub fn zero() Dual {
    return [_]i512{0} ** 10;
}

pub fn unit(index: usize) Dual {
    var v = zero();
    v[index] = 1;
    return v;
}

pub fn add(a: Dual, b: Dual) Dual {
    var out = zero();
    for (0..10) |i| out[i] = a[i] + b[i];
    return out;
}

pub fn sub(a: Dual, b: Dual) Dual {
    var out = zero();
    for (0..10) |i| out[i] = a[i] - b[i];
    return out;
}

pub fn mul(a: Dual, b: Dual) Dual {
    var out = zero();
    for (0..10) |i| {
        if (a[i] == 0) continue;
        for (0..10) |j| {
            if (b[j] == 0) continue;
            const p = unitMul(@intCast(i), @intCast(j));
            if (p.nilpotent_zero) continue;
            out[p.unit] += a[i] * b[j] * @as(i512, p.sign);
        }
    }
    return out;
}

pub fn normSquared(v: Dual) i512 {
    var n: i512 = 0;
    for (v) |c| n += c * c;
    return n;
}

pub fn commutator(a: Dual, b: Dual) Dual {
    return sub(mul(a, b), mul(b, a));
}

pub fn associator(a: Dual, b: Dual, c: Dual) Dual {
    return sub(mul(mul(a, b), c), mul(a, mul(b, c)));
}

test "e9 squared is zero (nilpotent)" {
    try std.testing.expectEqual(zero(), mul(unit(9), unit(9)));
}

test "e9 is absorbing on both sides" {
    for (0..9) |i| {
        try std.testing.expectEqual(unit(9), mul(unit(9), unit(i)));
        try std.testing.expectEqual(unit(9), mul(unit(i), unit(9)));
    }
}

test "anti-octonion multiplication is preserved on e0..e8" {
    // e8^2 = +e0 still holds; octonion table intact on e0..e7.
    var expect = zero();
    expect[0] = 1;
    try std.testing.expectEqual(expect, mul(unit(8), unit(8)));
    try std.testing.expectEqual(unit(3), mul(unit(1), unit(2)));
    var neg = zero();
    neg[0] = -1;
    try std.testing.expectEqual(neg, mul(unit(5), unit(5)));
}

test "commutator and associator survive inside the octonion part" {
    try std.testing.expectEqual(@as(i512, 4), normSquared(commutator(unit(1), unit(2))));
    try std.testing.expectEqual(@as(i512, 4), normSquared(associator(unit(1), unit(2), unit(4))));
}

test "the whole algebra has a nontrivial annihilator direction" {
    // Any element built only of e9 is annihilated by any product with e9 —
    // the dual axis is a nilpotent absorbing ideal.
    var e9_only = zero();
    e9_only[9] = 7;
    try std.testing.expectEqual(zero(), mul(e9_only, e9_only));
}
