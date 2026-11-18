const std = @import("std");

pub const SCALE: i64 = 1 << 32;
pub const MAX_MAGNITUDE: i64 = SCALE;
pub const MAX_PHASE_EIGHTH_TURNS: u3 = 7;
pub const ROUNDING_TOLERANCE: i64 = 4;

pub const Path = struct {
    amplitude: i64,
    phase_eighth_turns: u3,
};

pub const Result = struct {
    amplitude: i64,
    intensity: i64,
};

pub fn combine(paths: []const Path) error{ InvalidPathCount, InvalidAmplitude, Overflow }!Result {
    if (paths.len == 0 or paths.len > 2) return error.InvalidPathCount;
    var amplitude: i64 = 0;
    for (paths) |path| {
        if (path.amplitude < 0 or path.amplitude > MAX_MAGNITUDE) return error.InvalidAmplitude;
        const signed = switch (path.phase_eighth_turns) {
            0 => path.amplitude,
            4 => -path.amplitude,
            else => return error.InvalidAmplitude,
        };
        amplitude = std.math.add(i64, amplitude, signed) catch return error.Overflow;
    }
    const square = @as(i128, amplitude) * amplitude;
    const intensity = square >> 32;
    return .{
        .amplitude = amplitude,
        .intensity = std.math.cast(i64, intensity) orelse return error.Overflow,
    };
}

test "equal in-phase paths constructively reinforce" {
    const paths = [_]Path{
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 },
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 },
    };
    const result = try combine(&paths);
    try std.testing.expectEqual(SCALE, result.amplitude);
    try std.testing.expectEqual(SCALE, result.intensity);
}

test "equal opposite-phase paths destructively cancel" {
    const paths = [_]Path{
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 },
        .{ .amplitude = SCALE / 2, .phase_eighth_turns = 4 },
    };
    const result = try combine(&paths);
    try std.testing.expectEqual(@as(i64, 0), result.amplitude);
    try std.testing.expectEqual(@as(i64, 0), result.intensity);
}

test "single path intensity is its squared amplitude" {
    const path = [_]Path{.{ .amplitude = SCALE / 2, .phase_eighth_turns = 0 }};
    const result = try combine(&path);
    try std.testing.expectEqual(SCALE / 2, result.amplitude);
    try std.testing.expectEqual(SCALE / 4, result.intensity);
    try std.testing.expectEqual(result, try combine(&path));
}

test "unsupported phases, magnitudes, and path counts are rejected" {
    const bad_phase = [_]Path{.{ .amplitude = 1, .phase_eighth_turns = 1 }};
    const bad_magnitude = [_]Path{.{ .amplitude = SCALE + 1, .phase_eighth_turns = 0 }};
    try std.testing.expectError(error.InvalidAmplitude, combine(&bad_phase));
    try std.testing.expectError(error.InvalidAmplitude, combine(&bad_magnitude));
    try std.testing.expectError(error.InvalidPathCount, combine(&.{}));
    const too_many = [_]Path{.{ .amplitude = 0, .phase_eighth_turns = 0 }} ** 3;
    try std.testing.expectError(error.InvalidPathCount, combine(&too_many));
}
