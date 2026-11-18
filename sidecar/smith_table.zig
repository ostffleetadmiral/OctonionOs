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

pub fn index(x: i8, y: i8) ?usize {
    if (x < -7 or x > 7 or y < -7 or y > 7) return null;
    return @as(usize, @intCast(@as(i16, y) + 7)) * 15 + @as(usize, @intCast(@as(i16, x) + 7));
}
