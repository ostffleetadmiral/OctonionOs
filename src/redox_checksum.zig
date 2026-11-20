//! Unit-aware algebraic checksum; not a physical law.
const std = @import("std");

pub const Energy = struct { raw: i256, unit: []const u8 };
pub fn forward(mass: i256, c2: i256) Energy {
    return .{ .raw = mass * c2, .unit = "mass*velocity^2" };
}
pub fn inverse(mass: i256, c2: i256) Energy {
    return .{ .raw = @divTrunc(mass, c2), .unit = "mass/velocity^2" };
}
pub fn productIsMassSquared(mass: i256, c2: i256) bool {
    return forward(mass, c2).raw * inverse(mass, c2).raw == mass * mass;
}

test "checksum is an algebraic identity with explicit units" {
    try std.testing.expect(productIsMassSquared(8, 2));
    try std.testing.expectEqualStrings("mass*velocity^2", forward(7, 2).unit);
}
