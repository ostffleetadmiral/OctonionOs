//! 16D sedenion algebra S — the Cayley-Dickson double of the octonions.
//!
//! Second instance of the e8-extension superposition, coexisting with
//! `redox_anti_octonion.zig`'s split commuting extension:
//!   - e8^2 = -e0 here (Cayley-Dickson), vs +e0 in the split extension
//!   - e8 ANTICOMMUTES with every imaginary octonion unit here, vs
//!     commutes in the split extension
//!   - S is non-commutative, non-associative, non-ALTERNATIVE, and has
//!     zero divisors; flexibility and power-associativity survive.
//!
//! Elements are pairs (a, b) = a + b·l with a, b octonions and l the
//! doubling unit. Multiplication uses the Cayley-Dickson formula
//!   (a, b)(c, d) = (a c - conj(d) b, d a + b conj(c))
//! which gives l^2 = -1, e_{i+8} = e_i·l, and l·e_i = -e_i·l for i > 0.
//!
//! Classification: EXACT_MATH.

const std = @import("std");
const oct = @import("redox_octonion.zig");

pub const Sed = [16]i512;
pub const DIM: usize = 16;
pub const L: usize = 8; // index of the doubling unit e8

const O = [8]i512;

fn ozero() O {
    return [_]i512{0} ** 8;
}

fn oadd(a: O, b: O) O {
    var out: O = undefined;
    for (0..8) |i| out[i] = a[i] + b[i];
    return out;
}

fn osub(a: O, b: O) O {
    var out: O = undefined;
    for (0..8) |i| out[i] = a[i] - b[i];
    return out;
}

fn oconj(a: O) O {
    var out = a;
    for (1..8) |i| out[i] = -out[i];
    return out;
}

fn omul(a: O, b: O) O {
    var out = ozero();
    for (0..8) |i| for (0..8) |j| {
        const p = oct.mul(@intCast(i), @intCast(j));
        out[p.unit] += a[i] * b[j] * @as(i512, p.sign);
    };
    return out;
}

fn lo(s: Sed) O {
    return s[0..8].*;
}

fn hi(s: Sed) O {
    return s[8..16].*;
}

pub fn zero() Sed {
    return [_]i512{0} ** 16;
}

pub fn unit(index: usize) Sed {
    var v = zero();
    v[index] = 1;
    return v;
}

pub fn add(a: Sed, b: Sed) Sed {
    var out: Sed = undefined;
    for (0..DIM) |i| out[i] = a[i] + b[i];
    return out;
}

pub fn sub(a: Sed, b: Sed) Sed {
    var out: Sed = undefined;
    for (0..DIM) |i| out[i] = a[i] - b[i];
    return out;
}

pub fn neg(a: Sed) Sed {
    var out: Sed = undefined;
    for (0..DIM) |i| out[i] = -a[i];
    return out;
}

/// Cayley-Dickson product: (a,b)(c,d) = (ac - conj(d)b, da + b conj(c)).
pub fn mul(a: Sed, b: Sed) Sed {
    const alo = lo(a);
    const ahi = hi(a);
    const blo = lo(b);
    const bhi = hi(b);
    const plo = osub(omul(alo, blo), omul(oconj(bhi), ahi));
    const phi = oadd(omul(bhi, alo), omul(ahi, oconj(blo)));
    var out: Sed = undefined;
    for (0..8) |i| out[i] = plo[i];
    for (0..8) |i| out[8 + i] = phi[i];
    return out;
}

pub fn conj(a: Sed) Sed {
    var out = a;
    for (1..DIM) |i| out[i] = -out[i];
    return out;
}

pub fn normSquared(v: Sed) i512 {
    var n: i512 = 0;
    for (v) |x| n += x * x;
    return n;
}

pub fn isZero(v: Sed) bool {
    for (v) |x| if (x != 0) return false;
    return true;
}

test "e8 squared is -e0 (Cayley-Dickson signature)" {
    const e8 = unit(8);
    try std.testing.expectEqual(neg(unit(0)), mul(e8, e8));
}

test "e8 anticommutes with every imaginary octonion unit" {
    const e8 = unit(8);
    for (1..8) |i| {
        const ei = unit(i);
        try std.testing.expect(isZero(add(mul(e8, ei), mul(ei, e8))));
        // Naming convention: e_i * e8 = e_{i+8}.
        try std.testing.expectEqual(unit(i + 8), mul(ei, e8));
    }
    // e8 still commutes with the scalar e0.
    try std.testing.expectEqual(unit(8), mul(e8, unit(0)));
    try std.testing.expectEqual(unit(8), mul(unit(0), e8));
}

test "all fifteen imaginary units square to -e0" {
    for (1..DIM) |i| {
        try std.testing.expectEqual(neg(unit(0)), mul(unit(i), unit(i)));
    }
}

test "octonion subalgebra e0..e7 is preserved" {
    for (0..8) |i| for (0..8) |j| {
        const p = mul(unit(i), unit(j));
        const q = oct.mul(@intCast(i), @intCast(j));
        var expected = zero();
        expected[q.unit] = q.sign;
        try std.testing.expectEqual(expected, p);
    };
}

test "sedenions are non-commutative and non-associative" {
    try std.testing.expect(!isZero(sub(mul(unit(1), unit(2)), mul(unit(2), unit(1)))));
    const a = unit(9);
    const b = unit(10);
    const c = unit(11);
    try std.testing.expect(!isZero(sub(mul(mul(a, b), c), mul(a, mul(b, c)))));
}

test "sedenions are non-alternative: (x x) y != x (x y) for some x" {
    var found = false;
    for (1..DIM) |i| {
        for (1..DIM) |j| {
            if (i == j) continue;
            const x = add(unit(i), unit(j));
            const y = unit((i + 5) % 16);
            if (!isZero(sub(mul(mul(x, x), y), mul(x, mul(x, y))))) found = true;
        }
    }
    try std.testing.expect(found);
}

test "sedenions have zero divisors" {
    var count: usize = 0;
    var first_a: usize = 0;
    var first_b: usize = 0;
    var first_c: usize = 0;
    var first_d: usize = 0;
    for (1..DIM) |a| for (a + 1..DIM) |b| {
        for (1..DIM) |c| for (c + 1..DIM) |d| {
            const x = add(unit(a), unit(b));
            const y = add(unit(c), unit(d));
            if (isZero(mul(x, y))) {
                if (count == 0) {
                    first_a = a;
                    first_b = b;
                    first_c = c;
                    first_d = d;
                }
                count += 1;
            }
        };
    };
    try std.testing.expect(count > 0);
    // Pin the discovered certificate: e_{a}+e_{b} and e_{c}+e_{d} are
    // nonzero elements with zero product.
    const x = add(unit(first_a), unit(first_b));
    const y = add(unit(first_c), unit(first_d));
    try std.testing.expect(!isZero(x));
    try std.testing.expect(!isZero(y));
    try std.testing.expect(isZero(mul(x, y)));
}

test "sedenions remain flexible and power-associative" {
    const a = add(unit(3), unit(9));
    const b = add(sub(unit(6), unit(12)), unit(2));
    // Flexible law: (a b) a = a (b a).
    try std.testing.expectEqual(mul(mul(a, b), a), mul(a, mul(b, a)));
    // Power-associativity: (x x) x = x (x x).
    const x = add(unit(1), add(unit(8), unit(15)));
    try std.testing.expectEqual(mul(mul(x, x), x), mul(x, mul(x, x)));
    // Conjugate norm identity: x * conj(x) = |x|^2 e0.
    var expected = zero();
    expected[0] = normSquared(x);
    try std.testing.expectEqual(expected, mul(x, conj(x)));
}
