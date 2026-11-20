//! 3D vector algebra — the cross-product algebra on integer triples.
//!
//! The ladder's `vector_3d` tier is R3 with the Gibbs cross product:
//! anti-commutative (a x b = -(b x a)), non-associative, satisfies the
//! Jacobi identity, and has no unit element. It embeds into the
//! quaternions as the pure-imaginary subspace, where
//! u*v = -(u.v) + u x v — i.e. the quaternion product of two vectors is
//! the vector cross product plus a scalar (negative dot) part.
//!
//! Classification: EXACT_MATH — the product table and all measured
//! properties are exact integer statements.
const std = @import("std");

pub const V3 = [3]i512;
pub const DIM: usize = 3;

pub fn zero() V3 {
    return [_]i512{0} ** 3;
}

pub fn unit(index: usize) V3 {
    var v = zero();
    v[index] = 1;
    return v;
}

/// Cross product a x b.
pub fn cross(a: V3, b: V3) V3 {
    return .{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

/// Dot product a . b (exact integer).
pub fn dot(a: V3, b: V3) i512 {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

pub fn add(a: V3, b: V3) V3 {
    return .{ a[0] + b[0], a[1] + b[1], a[2] + b[2] };
}

pub fn sub(a: V3, b: V3) V3 {
    return .{ a[0] - b[0], a[1] - b[1], a[2] - b[2] };
}

/// Commutator [a,b] = a x b - b x a = 2(a x b): generically nonzero.
pub fn commutator(a: V3, b: V3) V3 {
    return sub(cross(a, b), cross(b, a));
}

/// Associator (a x b) x c - a x (b x c): generically nonzero.
pub fn associator(a: V3, b: V3, c: V3) V3 {
    return sub(cross(cross(a, b), c), cross(a, cross(b, c)));
}

pub fn normSquared(v: V3) i512 {
    return dot(v, v);
}

/// Jacobi identity residual: a x (b x c) + b x (c x a) + c x (a x b).
/// Identically zero for every triple — the cross product is a Lie algebra.
pub fn jacobiResidual(a: V3, b: V3, c: V3) V3 {
    return add(add(cross(a, cross(b, c)), cross(b, cross(c, a))), cross(c, cross(a, b)));
}

/// Vector triple product residual: a x (b x c) - ((a.c)b - (a.b)c) = 0.
pub fn tripleProductResidual(a: V3, b: V3, c: V3) V3 {
    const lhs = cross(a, cross(b, c));
    const bac_cab = sub(.{ dot(a, c) * b[0], dot(a, c) * b[1], dot(a, c) * b[2] }, .{ dot(a, b) * c[0], dot(a, b) * c[1], dot(a, b) * c[2] });
    return sub(lhs, bac_cab);
}

test "cross product is anti-commutative" {
    const e1 = unit(0);
    const e2 = unit(1);
    try std.testing.expectEqual(unit(2), cross(e1, e2));
    var neg = zero();
    neg[2] = -1;
    try std.testing.expectEqual(neg, cross(e2, e1));
}

test "commutator is generically nonzero and equals 2(a x b)" {
    const c = commutator(unit(0), unit(1));
    try std.testing.expectEqual(@as(i512, 2), c[2]);
    try std.testing.expectEqual(@as(i512, 4), normSquared(c));
}

test "cross product is non-associative — measured witness" {
    // (x x x) x y = 0 while x x (x x y) = x x z = -y: associator = +y, cost 1.
    const a = associator(unit(0), unit(0), unit(1));
    try std.testing.expectEqual(unit(1), a);
    try std.testing.expectEqual(@as(i512, 1), normSquared(a));
}

test "Jacobi identity holds on every basis triple" {
    for (0..3) |i| for (0..3) |j| for (0..3) |k| {
        try std.testing.expectEqual(zero(), jacobiResidual(unit(i), unit(j), unit(k)));
    };
}

test "vector triple product identity holds on every basis triple" {
    for (0..3) |i| for (0..3) |j| for (0..3) |k| {
        try std.testing.expectEqual(zero(), tripleProductResidual(unit(i), unit(j), unit(k)));
    };
}

test "a x a is always zero and there is no unit element" {
    const v = V3{ 3, -5, 7 };
    try std.testing.expectEqual(zero(), cross(v, v));
    // No multiplicative identity: e x x = x would need e orthogonal AND
    // unit-scaling simultaneously; on basis vectors e1 x e2 = e3 != e2.
    for (0..3) |i| for (0..3) |j| {
        if (i != j) try std.testing.expect(normSquared(sub(cross(unit(i), unit(j)), unit(j))) != 0);
    };
}
