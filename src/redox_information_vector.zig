//! Typed e0..e7 information vector metadata.
const std = @import("std");

pub const Component = enum(u3) { e0, e1, e2, e3, e4, e5, e6, e7 };
pub const COMPONENT_COUNT: usize = 8;

pub const Vector = struct {
    values: [COMPONENT_COUNT]i512 = [_]i512{0} ** COMPONENT_COUNT,

    pub fn at(self: Vector, component: Component) i512 {
        return self.values[@intFromEnum(component)];
    }

    pub fn set(self: *Vector, component: Component, value: i512) void {
        self.values[@intFromEnum(component)] = value;
    }
};

test "information vector has eight explicit components" {
    var vector = Vector{};
    vector.set(.e7, 7);
    try std.testing.expectEqual(@as(i512, 7), vector.at(.e7));
    try std.testing.expectEqual(COMPONENT_COUNT, vector.values.len);
}
