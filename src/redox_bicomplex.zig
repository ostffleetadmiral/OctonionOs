//! Bicomplex numbers — the commutative 4-real-dimensional algebra C(x)C.
//!
//! Basis {1, i, j, k} with i^2 = -1, j^2 = +1, k = ij = ji, k^2 = -1.
//! The ladder's `bicomplex_5d` label is framework metadata; the actual
//! real dimension is 4.
//!
//! Measured structure:
//!   - commutative and associative (commutator/associator identically zero)
//!   - NOT a division algebra: (1 + j)(1 - j) = 0 — nontrivial zero divisors
//!   - idempotent split: (1+j)^2 = 2(1+j), so e+ = (1+j)/2 and e- = (1-j)/2
//!     are orthogonal idempotents (halves kept symbolic to stay integer-exact)
//!   - because of the zero divisors, no subalgebra embedding into the
//!     Cayley-Dickson chain (R/C/H/O are division algebras) exists —
//!     the bridge therefore only offers a linear (non-homomorphic) map.
//!
//! Classification: EXACT_MATH.
const std = @import("std");

pub const BC = [4]i512; // [0]=1, [1]=i, [2]=j, [3]=k=ij
pub const DIM: usize = 4;

const UNIT_PRODUCT = [4][4]i8{
    // rows = left factor, cols = right factor; entries encode +k/-k as ±(index+1), 0 = zero
    .{ 1, 2, 3, 4 }, // 1 * {1,i,j,k}
    .{ 2, -1, 4, -3 }, // i * {1,i,j,k} = {i,-1,k,-j}
    .{ 3, 4, 1, 2 }, // j * {1,i,j,k} = {j,k,1,i}
    .{ 4, -3, 2, -1 }, // k * {1,i,j,k} = {k,-j,i,-1}
};

pub fn zero() BC {
    return [_]i512{0} ** 4;
}

pub fn unit(index: usize) BC {
    var v = zero();
    v[index] = 1;
    return v;
}

pub fn add(a: BC, b: BC) BC {
    return .{ a[0] + b[0], a[1] + b[1], a[2] + b[2], a[3] + b[3] };
}

pub fn sub(a: BC, b: BC) BC {
    return .{ a[0] - b[0], a[1] - b[1], a[2] - b[2], a[3] - b[3] };
}

pub fn mul(a: BC, b: BC) BC {
    var out = zero();
    for (0..4) |i| {
        if (a[i] == 0) continue;
        for (0..4) |j| {
            if (b[j] == 0) continue;
            const code = UNIT_PRODUCT[i][j];
            const idx: usize = @intCast(@abs(code));
            out[idx - 1] += a[i] * b[j] * @as(i512, if (code < 0) -1 else 1);
        }
    }
    return out;
}

pub fn normSquared(v: BC) i512 {
    var n: i512 = 0;
    for (v) |c| n += c * c;
    return n;
}

pub fn commutator(a: BC, b: BC) BC {
    return sub(mul(a, b), mul(b, a));
}

pub fn associator(a: BC, b: BC, c: BC) BC {
    return sub(mul(mul(a, b), c), mul(a, mul(b, c)));
}

test "bicomplex is commutative on every basis pair" {
    for (0..4) |i| for (0..4) |j| {
        try std.testing.expectEqual(zero(), commutator(unit(i), unit(j)));
    };
}

test "bicomplex is associative on every basis triple" {
    for (0..4) |i| for (0..4) |j| for (0..4) |k| {
        try std.testing.expectEqual(zero(), associator(unit(i), unit(j), unit(k)));
    };
}

test "signature split: i^2 = -1, j^2 = +1, k^2 = -1" {
    var neg_one = zero();
    neg_one[0] = -1;
    var pos_one = zero();
    pos_one[0] = 1;
    try std.testing.expectEqual(neg_one, mul(unit(1), unit(1)));
    try std.testing.expectEqual(pos_one, mul(unit(2), unit(2))); // j^2 = +1
    try std.testing.expectEqual(neg_one, mul(unit(3), unit(3)));
}

test "zero divisors exist: (1 + j)(1 - j) = 0" {
    var p = unit(0);
    p[2] = 1; // 1 + j
    var q = unit(0);
    q[2] = -1; // 1 - j
    try std.testing.expectEqual(zero(), mul(p, q));
    try std.testing.expect(normSquared(p) != 0 and normSquared(q) != 0);
}

test "unscaled idempotent: (1 + j)^2 = 2(1 + j)" {
    var p = unit(0);
    p[2] = 1;
    const p2 = mul(p, p);
    try std.testing.expectEqual(@as(i512, 2), p2[0]);
    try std.testing.expectEqual(@as(i512, 2), p2[2]);
}
