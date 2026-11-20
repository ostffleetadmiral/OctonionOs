const std = @import("std");
const quantum_model = @import("quantum_model.zig");

pub const SCALE: i64 = quantum_model.ONE;
pub const MAX_MAGNITUDE: i64 = SCALE;
pub const MAX_PHASE_EIGHTH_TURNS: u3 = 7;
pub const ROUNDING_TOLERANCE: i64 = 8;

pub const Path = struct {
    amplitude: i64,
    phase_eighth_turns: u3,
};

pub const Result = struct {
    amplitude_re: i64,
    amplitude_im: i64,
    intensity: i64,
};

pub fn combine(paths: []const Path) error{ InvalidPathCount, InvalidAmplitude, Overflow }!Result {
    if (paths.len == 0 or paths.len > 2) return error.InvalidPathCount;
    var re: i64 = 0;
    var im: i64 = 0;
    for (paths) |path| {
        if (path.amplitude < 0 or path.amplitude > MAX_MAGNITUDE) return error.InvalidAmplitude;
        const contribution = rotate(path.amplitude, path.phase_eighth_turns) catch return error.Overflow;
        re = std.math.add(i64, re, contribution.re) catch return error.Overflow;
        im = std.math.add(i64, im, contribution.im) catch return error.Overflow;
    }
    const re_mag = magnitude128(re);
    const im_mag = magnitude128(im);
    const re_sq = std.math.mul(u128, re_mag, re_mag) catch return error.Overflow;
    const im_sq = std.math.mul(u128, im_mag, im_mag) catch return error.Overflow;
    const square_sum = std.math.add(u128, re_sq, im_sq) catch return error.Overflow;
    const intensity = roundUnsignedShiftNearestTiesEven(square_sum, 32);
    return .{
        .amplitude_re = re,
        .amplitude_im = im,
        .intensity = std.math.cast(i64, intensity) orelse return error.Overflow,
    };
}

const Components = struct {
    re: i64,
    im: i64,
};

fn rotate(amplitude: i64, phase: u3) error{Overflow}!Components {
    return switch (phase) {
        0 => .{ .re = amplitude, .im = 0 },
        1 => .{ .re = try multiplyFixed(amplitude, quantum_model.SQRT_HALF), .im = try multiplyFixed(amplitude, quantum_model.SQRT_HALF) },
        2 => .{ .re = 0, .im = amplitude },
        3 => .{ .re = try negateFixed(try multiplyFixed(amplitude, quantum_model.SQRT_HALF)), .im = try multiplyFixed(amplitude, quantum_model.SQRT_HALF) },
        4 => .{ .re = try negateFixed(amplitude), .im = 0 },
        5 => .{ .re = try negateFixed(try multiplyFixed(amplitude, quantum_model.SQRT_HALF)), .im = try negateFixed(try multiplyFixed(amplitude, quantum_model.SQRT_HALF)) },
        6 => .{ .re = 0, .im = try negateFixed(amplitude) },
        7 => .{ .re = try multiplyFixed(amplitude, quantum_model.SQRT_HALF), .im = try negateFixed(try multiplyFixed(amplitude, quantum_model.SQRT_HALF)) },
    };
}

fn multiplyFixed(a: i64, b: i64) error{Overflow}!i64 {
    const product = @as(i128, a) * b;
    return std.math.cast(i64, roundShiftNearestTiesEven(product, 32)) orelse error.Overflow;
}

fn negateFixed(value: i64) error{Overflow}!i64 {
    return std.math.negate(value) catch error.Overflow;
}

fn roundShiftNearestTiesEven(value: i128, shift: u6) i128 {
    const divisor: i128 = @as(i128, 1) << shift;
    const magnitude = magnitude128Signed(value);
    const positive = magnitude / @as(u128, @intCast(divisor));
    const remainder = magnitude % @as(u128, @intCast(divisor));
    const half: u128 = @as(u128, 1) << (shift - 1);
    const rounded = positive + @intFromBool(remainder > half or (remainder == half and positive & 1 == 1));
    return if (value < 0)
        -@as(i128, @intCast(rounded))
    else
        @intCast(rounded);
}

fn magnitude128Signed(value: i128) u128 {
    return if (value < 0)
        @as(u128, @intCast(-(value + 1))) + 1
    else
        @intCast(value);
}

fn magnitude128(value: i64) u128 {
    return if (value < 0)
        @as(u128, @intCast(-(value + 1))) + 1
    else
        @intCast(value);
}

fn roundUnsignedShiftNearestTiesEven(value: u128, shift: u6) u128 {
    const divisor: u128 = @as(u128, 1) << shift;
    const quotient = value / divisor;
    const remainder = value % divisor;
    const half = divisor / 2;
    return quotient + @intFromBool(remainder > half or (remainder == half and quotient & 1 == 1));
}

test "equal in-phase paths constructively reinforce" {
    const paths = [_]Path{
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 },
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 },
    };
    const result = try combine(&paths);
    try std.testing.expectEqual(SCALE, result.amplitude_re);
    try std.testing.expectEqual(@as(i64, 0), result.amplitude_im);
    try std.testing.expectEqual(SCALE, result.intensity);
}

test "equal opposite-phase paths destructively cancel" {
    const paths = [_]Path{
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 },
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 4 },
    };
    const result = try combine(&paths);
    try std.testing.expectEqual(@as(i64, 0), result.amplitude_re);
    try std.testing.expectEqual(@as(i64, 0), result.amplitude_im);
    try std.testing.expectEqual(@as(i64, 0), result.intensity);
}

test "quadrature phases combine as complex amplitudes" {
    const paths = [_]Path{
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 },
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 2 },
    };
    const result = try combine(&paths);
    try std.testing.expectEqual(SCALE / 2, result.amplitude_re);
    try std.testing.expectEqual(SCALE / 2, result.amplitude_im);
    try std.testing.expectEqual(SCALE / 2, result.intensity);
}

test "two-path fringes vary periodically across all relative phases" {
    const expected = [_]i64{ SCALE, 3_665_983_898, SCALE / 2, 628_983_398, 0, 628_983_398, SCALE / 2, 3_665_983_898 };
    for (0..8) |phase_value| {
        const phase: u3 = @intCast(phase_value);
        const paths = [_]Path{
            .{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 },
            .{ .amplitude = SCALE / 2, .phase_eighth_turns = phase },
        };
        const result = try combine(&paths);
        try std.testing.expect(@abs(result.intensity - expected[phase_value]) <= ROUNDING_TOLERANCE);
    }
}

test "eighth-turn rotations have constructive, destructive and periodic controls" {
    const angles = [_]u3{ 0, 1, 2, 3, 4, 5, 6, 7 };
    for (angles) |phase| {
        const path = [_]Path{.{ .amplitude = SCALE / 2, .phase_eighth_turns = phase }};
        const result = try combine(&path);
        try std.testing.expect(@abs(result.intensity - SCALE / 4) <= ROUNDING_TOLERANCE);
    }
    const repeated = [_]Path{.{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 }};
    try std.testing.expectEqual(try combine(&repeated), try combine(&repeated));
}

test "path phase labels are local and do not alias the lattice transit counter" {
    const paths = [_]Path{
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 },
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 4 },
    };
    try std.testing.expectEqual(@as(i64, 0), (try combine(&paths)).intensity);
}

test "unsupported amplitudes and path counts are rejected" {
    const bad_magnitude = [_]Path{.{ .amplitude = SCALE + 1, .phase_eighth_turns = 0 }};
    try std.testing.expectError(error.InvalidAmplitude, combine(&bad_magnitude));
    try std.testing.expectError(error.InvalidPathCount, combine(&.{}));
    const too_many = [_]Path{.{ .amplitude = 0, .phase_eighth_turns = 0 }} ** 3;
    try std.testing.expectError(error.InvalidPathCount, combine(&too_many));
}
