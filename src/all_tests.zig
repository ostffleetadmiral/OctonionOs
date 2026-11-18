comptime {
    _ = @import("lattice.zig");
    _ = @import("ladder.zig");
    _ = @import("frames.zig");
    _ = @import("smith_table.zig");
    _ = @import("scaling.zig");
    _ = @import("routing.zig");
    _ = @import("serialize.zig");
}

test "core test suite imports integer modules" {}
