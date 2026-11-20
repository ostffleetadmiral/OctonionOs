//! Exceptional Jordan algebra J3(O) — 3x3 Hermitian matrices over octonions.
//!
//! Ported from the E=mc² workspace (`hardware/src/jordan_algebra.zig`),
//! re-expressed on this repo's `redox_octonion` Fano table with i512
//! integer coefficients:
//!
//!   X = [ α   o1  o2 ]
//!       [ ō1  β   o3 ]
//!       [ ō2  ō3  γ  ]
//!
//!   real dimension: 3 + 3*8 = 27; automorphism group F4 (dim 52).
//!
//! The Jordan product is the symmetrized matrix product X o Y = (XY+YX)/2:
//! commutative but non-associative (power-associative). To stay exact in
//! integer arithmetic, the primary operation here is the DOUBLED product
//!   j2(X,Y) = XY + YX = 2*(X o Y)
//! which is coefficient-exact. The halved `jmul` is provided for parity
//! with the parent implementation and truncates odd remainders; all
//! structural measurements (commutator, associator) use `j2` so the
//! reported magnitudes are honest integers.
//!
//! Classification: EXACT_MATH for the arithmetic; the framework's
//! physics reading of J3(O) stays an interpretation label.
const std = @import("std");
const oct = @import("redox_octonion.zig");

pub const Oct = [8]i512;
pub const DIM: usize = 27;
pub const F4_DIM: u32 = 52;

pub fn octZero() Oct {
    return [_]i512{0} ** 8;
}

pub fn octUnit(index: usize) Oct {
    var v = octZero();
    v[index] = 1;
    return v;
}

pub fn octAdd(a: Oct, b: Oct) Oct {
    var out = octZero();
    for (0..8) |i| out[i] = a[i] + b[i];
    return out;
}

pub fn octScale(a: Oct, s: i512) Oct {
    var out = octZero();
    for (0..8) |i| out[i] = a[i] * s;
    return out;
}

pub fn octConjugate(a: Oct) Oct {
    var out = a;
    for (1..8) |i| out[i] = -out[i];
    return out;
}

/// Octonion product on integer coefficients via the Fano table.
pub fn octMul(a: Oct, b: Oct) Oct {
    var out = octZero();
    for (0..8) |i| {
        if (a[i] == 0) continue;
        for (0..8) |j| {
            if (b[j] == 0) continue;
            const p = oct.mul(@intCast(i), @intCast(j));
            out[p.unit] += a[i] * b[j] * @as(i512, p.sign);
        }
    }
    return out;
}

pub fn octRe(a: Oct) i512 {
    return a[0];
}

pub fn octNormSquared(a: Oct) i512 {
    var n: i512 = 0;
    for (a) |c| n += c * c;
    return n;
}

pub const J3 = struct {
    alpha: i512, // (1,1) real
    beta: i512, // (2,2) real
    gamma: i512, // (3,3) real
    o1: Oct, // (1,2); (2,1) = conj(o1)
    o2: Oct, // (1,3); (3,1) = conj(o2)
    o3: Oct, // (2,3); (3,2) = conj(o3)

    pub fn diagonal(a: i512, b: i512, g: i512) J3 {
        return .{ .alpha = a, .beta = b, .gamma = g, .o1 = octZero(), .o2 = octZero(), .o3 = octZero() };
    }

    pub fn zero() J3 {
        return diagonal(0, 0, 0);
    }
};

/// tr(X) = a + b + g
pub fn trace(x: J3) i512 {
    return x.alpha + x.beta + x.gamma;
}

/// s(X) = ab + ag + bg - |o1|^2 - |o2|^2 - |o3|^2
pub fn secondaryTrace(x: J3) i512 {
    return x.alpha * x.beta + x.alpha * x.gamma + x.beta * x.gamma -
        octNormSquared(x.o1) - octNormSquared(x.o2) - octNormSquared(x.o3);
}

/// det(X) = abg + 2 Re(o1 . ō2 . o3) - a|o3|^2 - b|o2|^2 - g|o1|^2
pub fn determinant(x: J3) i512 {
    const triple = octMul(octMul(x.o1, octConjugate(x.o2)), x.o3);
    return x.alpha * x.beta * x.gamma + 2 * octRe(triple) -
        x.alpha * octNormSquared(x.o3) - x.beta * octNormSquared(x.o2) - x.gamma * octNormSquared(x.o1);
}

/// Characteristic polynomial l^3 + c2 l^2 + c1 l + c0.
pub const CharPoly = struct { c2: i512, c1: i512, c0: i512 };

pub fn characteristicPolynomial(x: J3) CharPoly {
    return .{ .c2 = -trace(x), .c1 = secondaryTrace(x), .c0 = -determinant(x) };
}

/// Doubled Jordan product j2(X,Y) = XY + YX = 2*(X o Y) — exact integers.
pub fn jmul2(x: J3, y: J3) J3 {
    const a2 = x.alpha * y.alpha + y.alpha * x.alpha +
        octRe(octMul(x.o1, octConjugate(y.o1))) + octRe(octMul(x.o2, octConjugate(y.o2))) +
        octRe(octMul(y.o1, octConjugate(x.o1))) + octRe(octMul(y.o2, octConjugate(x.o2)));

    const b2 = x.beta * y.beta + y.beta * x.beta +
        octRe(octMul(x.o1, octConjugate(y.o1))) + octRe(octMul(x.o3, octConjugate(y.o3))) +
        octRe(octMul(y.o1, octConjugate(x.o1))) + octRe(octMul(y.o3, octConjugate(x.o3)));

    const g2 = x.gamma * y.gamma + y.gamma * x.gamma +
        octRe(octMul(x.o2, octConjugate(y.o2))) + octRe(octMul(x.o3, octConjugate(y.o3))) +
        octRe(octMul(y.o2, octConjugate(x.o2))) + octRe(octMul(y.o3, octConjugate(x.o3)));

    const o1_2 = octAdd(
        octAdd(octScale(y.o1, x.alpha + x.beta), octScale(x.o1, y.alpha + y.beta)),
        octAdd(octMul(x.o2, octConjugate(y.o3)), octMul(y.o2, octConjugate(x.o3))),
    );
    const o2_2 = octAdd(
        octAdd(octScale(y.o2, x.alpha + x.gamma), octScale(x.o2, y.alpha + y.gamma)),
        octAdd(octMul(x.o1, y.o3), octMul(y.o1, x.o3)),
    );
    const o3_2 = octAdd(
        octAdd(octScale(y.o3, x.beta + x.gamma), octScale(x.o3, y.beta + y.gamma)),
        octAdd(octMul(octConjugate(x.o1), y.o2), octMul(octConjugate(y.o1), x.o2)),
    );

    return .{ .alpha = a2, .beta = b2, .gamma = g2, .o1 = o1_2, .o2 = o2_2, .o3 = o3_2 };
}

/// Halved Jordan product X o Y; truncates odd remainders (parity with the
/// parent implementation). Use `jmul2` where exactness matters.
pub fn jmul(x: J3, y: J3) J3 {
    const p = jmul2(x, y);
    var o1 = octZero();
    var o2 = octZero();
    var o3 = octZero();
    for (0..8) |i| {
        o1[i] = @divTrunc(p.o1[i], 2);
        o2[i] = @divTrunc(p.o2[i], 2);
        o3[i] = @divTrunc(p.o3[i], 2);
    }
    return .{ .alpha = @divTrunc(p.alpha, 2), .beta = @divTrunc(p.beta, 2), .gamma = @divTrunc(p.gamma, 2), .o1 = o1, .o2 = o2, .o3 = o3 };
}

pub fn eql(x: J3, y: J3) bool {
    return x.alpha == y.alpha and x.beta == y.beta and x.gamma == y.gamma and
        std.mem.eql(i512, &x.o1, &y.o1) and std.mem.eql(i512, &x.o2, &y.o2) and
        std.mem.eql(i512, &x.o3, &y.o3);
}

pub fn subJ(x: J3, y: J3) J3 {
    return .{
        .alpha = x.alpha - y.alpha,
        .beta = x.beta - y.beta,
        .gamma = x.gamma - y.gamma,
        .o1 = octAdd(x.o1, octScale(y.o1, -1)),
        .o2 = octAdd(x.o2, octScale(y.o2, -1)),
        .o3 = octAdd(x.o3, octScale(y.o3, -1)),
    };
}

/// Squared magnitude over all 27 real components.
pub fn normSquared(x: J3) i512 {
    return x.alpha * x.alpha + x.beta * x.beta + x.gamma * x.gamma +
        2 * octNormSquared(x.o1) + 2 * octNormSquared(x.o2) + 2 * octNormSquared(x.o3);
}

/// Jordan commutator measured on the doubled product: identically zero.
pub fn commutator(x: J3, y: J3) J3 {
    return subJ(jmul2(x, y), jmul2(y, x));
}

/// Jordan associator on the doubled product:
/// (X j2 Y) j2 Z - X j2 (Y j2 Z). Nonzero for generic J3(O) elements;
/// magnitudes are 4x those of the halved product.
pub fn associator(x: J3, y: J3, z: J3) J3 {
    return subJ(jmul2(jmul2(x, y), z), jmul2(x, jmul2(y, z)));
}

test "J3(O) has 27 real dimensions and F4 has 52" {
    try std.testing.expectEqual(@as(usize, 27), DIM);
    try std.testing.expectEqual(@as(u32, 52), F4_DIM);
}

test "characteristic polynomials match hand-computed values" {
    const ident = characteristicPolynomial(J3.diagonal(1, 1, 1));
    try std.testing.expectEqual(@as(i512, -3), ident.c2);
    try std.testing.expectEqual(@as(i512, 3), ident.c1);
    try std.testing.expectEqual(@as(i512, -1), ident.c0);
    const d = characteristicPolynomial(J3.diagonal(2, 3, 5));
    try std.testing.expectEqual(@as(i512, -10), d.c2);
    try std.testing.expectEqual(@as(i512, 31), d.c1);
    try std.testing.expectEqual(@as(i512, -30), d.c0);
}

test "doubled Jordan product is commutative on every component" {
    var x = J3.diagonal(1, 2, 3);
    x.o1 = octUnit(1);
    var y = J3.diagonal(4, 5, 6);
    y.o2 = octUnit(2);
    y.o3 = octUnit(4);
    try std.testing.expectEqual(@as(i512, 0), normSquared(commutator(x, y)));
    // diagonal commutation matches the parent halved product too
    const p = jmul(J3.diagonal(2, 3, 5), J3.diagonal(1, 4, 6));
    try std.testing.expectEqual(@as(i512, 2), p.alpha);
    try std.testing.expectEqual(@as(i512, 12), p.beta);
    try std.testing.expectEqual(@as(i512, 30), p.gamma);
}

test "Jordan algebra is power-associative: X j2 (X j2 X) = (X j2 X) j2 X" {
    var x = J3.diagonal(1, 0, 2);
    x.o1 = octUnit(1);
    x.o2 = octUnit(3);
    const left = jmul2(x, jmul2(x, x));
    const right = jmul2(jmul2(x, x), x);
    try std.testing.expect(eql(left, right));
}

test "J3(O) is non-associative — measured witness by bounded search" {
    // Search basis-unit off-diagonal placements for a nonzero associator.
    var found = false;
    outer: for (0..8) |i| {
        for (0..8) |j| {
            for (0..8) |k| {
                var x = J3.zero();
                x.o1 = octUnit(i);
                var y = J3.zero();
                y.o2 = octUnit(j);
                var z = J3.zero();
                z.o3 = octUnit(k);
                if (normSquared(associator(x, y, z)) != 0) {
                    found = true;
                    break :outer;
                }
            }
        }
    }
    try std.testing.expect(found);
}
