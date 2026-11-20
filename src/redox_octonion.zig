//! Exact Fano-line octonion basis and associator witness.
const std = @import("std");

pub const Unit = u3;
pub const FANO_LINES = [_][3]Unit{ .{ 1, 2, 3 }, .{ 1, 4, 5 }, .{ 1, 7, 6 }, .{ 2, 4, 6 }, .{ 2, 5, 7 }, .{ 3, 4, 7 }, .{ 3, 5, 6 } };
pub const Product = struct { sign: i2, unit: Unit };

pub fn mul(a: Unit, b: Unit) Product {
    if (a == 0) return .{ .sign = 1, .unit = b };
    if (b == 0) return .{ .sign = 1, .unit = a };
    if (a == b) return .{ .sign = -1, .unit = 0 };
    for (FANO_LINES) |line| for (0..3) |i| {
        const x = line[i];
        const y = line[(i + 1) % 3];
        const z = line[(i + 2) % 3];
        if (a == x and b == y) return .{ .sign = 1, .unit = z };
        if (a == y and b == x) return .{ .sign = -1, .unit = z };
    };
    return .{ .sign = 0, .unit = 0 };
}

pub fn isNonAssociative() bool {
    const ab = mul(1, 2);
    const left = mul(ab.unit, 4);
    const bc = mul(2, 4);
    const right = mul(1, bc.unit);
    return left.unit != right.unit or left.sign != right.sign;
}

test "octonion Fano basis is non-associative" {
    try std.testing.expect(isNonAssociative());
    try std.testing.expectEqual(@as(usize, 7), FANO_LINES.len);
}
