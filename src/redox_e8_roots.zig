//! E8 root system — the 240 octavian units on this repo's Fano table.
//!
//! Ported from the E=mc2 workspace (`hardware/src/octavian.zig`) with
//! i512 coefficients. Convention: octonion coordinates stored at
//! quadruple scale — actual coefficient = stored/4. Pure units +-e_i
//! carry one entry +-4; half-integer units carry four entries +-2.
//! Every product, inner product, and Weyl reflection stays exactly
//! integral.
//!
//!   E8 fingerprint (verified by exhaustive test): each root has
//!   1 antipode (-1), 56 roots at inner product +1/2, 56 at -1/2,
//!   and 126 orthogonal roots — and the 240-set is closed under
//!   Weyl reflection s_v(u) = u - 2<u,v>v.
//!
//! A root system is not an algebra: it carries a REFLECTION structure,
//! not a bilinear product. The bridge therefore gives this tier
//! promote/demote maps and reflection measurements, but `mul` is an
//! error by construction — that absence is the measured fact.
//!
//! Classification: EXACT_MATH.
const std = @import("std");
const oct = @import("redox_octonion.zig");

/// Scaled octonion vector: coefficient = stored/4.
pub const Vec = [8]i512;
pub const UNIT_COUNT = 240;
pub const DIM: usize = 8;

fn unitMul(a: u8, b: u8) struct { unit: u8, sign: i8 } {
    if (a == 0) return .{ .unit = b, .sign = 1 };
    if (b == 0) return .{ .unit = a, .sign = 1 };
    const p = oct.mul(@intCast(a), @intCast(b));
    return .{ .unit = p.unit, .sign = p.sign };
}

/// Recover the seven oriented Fano lines from the table itself.
pub fn fanoLines() [7][3]u8 {
    var lines: [7][3]u8 = undefined;
    var n: usize = 0;
    var a: u8 = 1;
    while (a <= 7) : (a += 1) {
        var b: u8 = a + 1;
        while (b <= 7) : (b += 1) {
            const p = unitMul(a, b);
            if (p.unit == 0 or p.unit == a or p.unit == b) continue;
            const c = p.unit;
            const t0 = @min(a, @min(b, c));
            const t2 = @max(a, @max(b, c));
            const t1 = a + b + c - t0 - t2;
            var dup = false;
            for (lines[0..n]) |t| {
                if (t[0] == t0 and t[1] == t1 and t[2] == t2) dup = true;
            }
            if (!dup) {
                lines[n] = .{ t0, t1, t2 };
                n += 1;
            }
        }
    }
    return lines;
}

/// The 240 roots: +-e_i (16), half-integer units over {e0}+line
/// triples (112), half-integer units over line-complement
/// quadruples (112).
pub fn buildRoots() [UNIT_COUNT]Vec {
    const lines = fanoLines();
    var units: [UNIT_COUNT]Vec = undefined;
    var n: usize = 0;
    for (0..8) |i| {
        var p: Vec = [_]i512{0} ** 8;
        p[i] = 4;
        units[n] = p;
        n += 1;
        p[i] = -4;
        units[n] = p;
        n += 1;
    }
    for (lines) |t| {
        var s0: i512 = -1;
        while (s0 <= 1) : (s0 += 2) {
            var s1: i512 = -1;
            while (s1 <= 1) : (s1 += 2) {
                var s2: i512 = -1;
                while (s2 <= 1) : (s2 += 2) {
                    var s3: i512 = -1;
                    while (s3 <= 1) : (s3 += 2) {
                        var v: Vec = [_]i512{0} ** 8;
                        v[0] = 2 * s0;
                        v[t[0]] = 2 * s1;
                        v[t[1]] = 2 * s2;
                        v[t[2]] = 2 * s3;
                        units[n] = v;
                        n += 1;
                    }
                }
            }
        }
    }
    for (lines) |t| {
        var quad: [4]u8 = undefined;
        var qn: usize = 0;
        for (1..8) |i| {
            if (i != t[0] and t[1] != i and t[2] != i) {
                quad[qn] = @intCast(i);
                qn += 1;
            }
        }
        var s0: i512 = -1;
        while (s0 <= 1) : (s0 += 2) {
            var s1: i512 = -1;
            while (s1 <= 1) : (s1 += 2) {
                var s2: i512 = -1;
                while (s2 <= 1) : (s2 += 2) {
                    var s3: i512 = -1;
                    while (s3 <= 1) : (s3 += 2) {
                        var v: Vec = [_]i512{0} ** 8;
                        v[quad[0]] = 2 * s0;
                        v[quad[1]] = 2 * s1;
                        v[quad[2]] = 2 * s2;
                        v[quad[3]] = 2 * s3;
                        units[n] = v;
                        n += 1;
                    }
                }
            }
        }
    }
    return units;
}

pub fn vecEq(a: Vec, b: Vec) bool {
    return std.mem.eql(i512, &a, &b);
}

/// Inner product in units of 1/16 (<x,y> * 16, exactly integral).
pub fn inner16(x: Vec, y: Vec) i512 {
    var s: i512 = 0;
    for (0..8) |i| s += x[i] * y[i];
    return s;
}

/// Weyl reflection s_v(u) = u - 2<u,v>v at norm-1 normalization.
/// Exact when 2<u,v> in {0,+-1,+-2}, i.e. inner16 in {0,+-8,+-16};
/// the i512 modulus asserts rather than truncates.
pub fn reflect(u: Vec, v: Vec) Vec {
    const c = @divExact(inner16(u, v), 8);
    var out: Vec = undefined;
    for (0..8) |i| out[i] = u[i] - c * v[i];
    return out;
}

/// Membership test against the 240-root set.
pub fn isRoot(v: Vec) bool {
    const units = buildRoots();
    for (units) |u| {
        if (vecEq(u, v)) return true;
    }
    return false;
}

pub fn normSquared(v: Vec) i512 {
    return inner16(v, v);
}

test "240 roots exist, all unit norm" {
    const units = buildRoots();
    var distinct = std.AutoHashMap(u64, void).init(std.testing.allocator);
    defer distinct.deinit();
    for (units) |u| {
        try std.testing.expectEqual(@as(i512, 16), inner16(u, u));
        var h = std.hash.Wyhash.init(0);
        for (u) |c| h.update(std.mem.asBytes(&c));
        try std.testing.expect((try distinct.getOrPut(h.final())).found_existing == false);
    }
    try std.testing.expectEqual(@as(usize, 240), distinct.count());
}

test "every root carries the exact E8 inner-product fingerprint" {
    const units = buildRoots();
    for (units) |u| {
        var self: usize = 0;
        var antipode: usize = 0;
        var half_pos: usize = 0;
        var half_neg: usize = 0;
        var orthogonal: usize = 0;
        var other: usize = 0;
        for (units) |v| {
            switch (inner16(u, v)) {
                16 => self += 1,
                -16 => antipode += 1,
                8 => half_pos += 1,
                -8 => half_neg += 1,
                0 => orthogonal += 1,
                else => other += 1,
            }
        }
        try std.testing.expectEqual(@as(usize, 1), self);
        try std.testing.expectEqual(@as(usize, 1), antipode);
        try std.testing.expectEqual(@as(usize, 56), half_pos);
        try std.testing.expectEqual(@as(usize, 56), half_neg);
        try std.testing.expectEqual(@as(usize, 126), orthogonal);
        try std.testing.expectEqual(@as(usize, 0), other);
    }
}

test "the root set is closed under Weyl reflection (root-system axiom)" {
    const units = buildRoots();
    var index = std.AutoHashMap(u64, void).init(std.testing.allocator);
    defer index.deinit();
    for (units) |u| {
        var h = std.hash.Wyhash.init(0);
        for (u) |c| h.update(std.mem.asBytes(&c));
        try index.put(h.final(), {});
    }
    for (units) |u| {
        for (units) |v| {
            const r = reflect(u, v);
            var h = std.hash.Wyhash.init(0);
            for (r) |c| h.update(std.mem.asBytes(&c));
            try std.testing.expect(index.contains(h.final()));
        }
    }
}
