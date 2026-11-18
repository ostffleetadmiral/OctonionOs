const std = @import("std");

pub const ENTRY_COUNT: usize = 225;
pub const SCALE: i64 = 1_000_000_000;

pub const ImpedanceState = enum(u8) {
    finite,
    open,
    short,
    positive_reactive_limit,
    negative_reactive_limit,
};

pub const Entry = struct {
    gamma_re: i64,
    gamma_im: i64,
    impedance_re: i64,
    impedance_im: i64,
    state: ImpedanceState,
};

pub const Table = struct {
    entries: [ENTRY_COUNT]Entry,

    pub fn get(self: *const Table, x: i8, y: i8) ?Entry {
        const position = index(x, y) orelse return null;
        return self.entries[position];
    }
};

pub fn index(x: i8, y: i8) ?usize {
    if (x < -7 or x > 7 or y < -7 or y > 7) return null;
    const column: usize = @intCast(@as(i16, x) + 7);
    const row: usize = @intCast(@as(i16, y) + 7);
    return row * 15 + column;
}

test "Smith table coordinate index covers the full transverse slice" {
    var seen = [_]bool{false} ** ENTRY_COUNT;
    for (0..15) |row| {
        for (0..15) |column| {
            const signed_y: i8 = @intCast(@as(i16, @intCast(row)) - 7);
            const signed_x: i8 = @intCast(@as(i16, @intCast(column)) - 7);
            const position = index(signed_x, signed_y).?;
            try std.testing.expect(!seen[position]);
            seen[position] = true;
        }
    }
    for (seen) |present| try std.testing.expect(present);
}
