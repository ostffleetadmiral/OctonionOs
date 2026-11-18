const std = @import("std");
const table = @import("smith_table.zig");

const Complex = struct {
    re: f64,
    im: f64,
};

const DiskPoint = struct {
    x: f64,
    y: f64,
};

const Impedance = union(enum) {
    finite: Complex,
    open,
    short,
    reactive_limit: f64,
};

const TableEntry = struct {
    gamma_re: f64,
    gamma_im: f64,
    impedance: Impedance,
};

const QuantizedEntry = table.Entry;

pub const SCALE: i64 = 1_000_000_000;
const TOLERANCE: f64 = 1e-12;

fn concentricSquareToDisk(u: f64, v: f64) DiskPoint {
    if (u == 0.0 and v == 0.0) return .{ .x = 0.0, .y = 0.0 };

    var radius: f64 = undefined;
    var theta: f64 = undefined;
    if (u > -v) {
        if (u > v) {
            radius = u;
            theta = (std.math.pi / 4.0) * (v / u);
        } else {
            radius = v;
            theta = (std.math.pi / 4.0) * (2.0 - (u / v));
        }
    } else if (u < v) {
        radius = -u;
        theta = (std.math.pi / 4.0) * (4.0 + (v / u));
    } else {
        radius = -v;
        theta = if (v == 0.0) 0.0 else (std.math.pi / 4.0) * (6.0 - (u / v));
    }

    return .{
        .x = radius * @cos(theta),
        .y = radius * @sin(theta),
    };
}

fn impedanceFromGamma(gamma: Complex) Impedance {
    if (@abs(gamma.re - 1.0) <= TOLERANCE and @abs(gamma.im) <= TOLERANCE) return .open;
    if (@abs(gamma.re + 1.0) <= TOLERANCE and @abs(gamma.im) <= TOLERANCE) return .short;

    const denominator_re = 1.0 - gamma.re;
    const denominator_im = -gamma.im;
    const denominator_norm = denominator_re * denominator_re + denominator_im * denominator_im;
    if (denominator_norm <= TOLERANCE * TOLERANCE) return .open;

    const numerator_re = 1.0 + gamma.re;
    const numerator_im = gamma.im;
    const result = Complex{
        .re = (numerator_re * denominator_re + numerator_im * denominator_im) / denominator_norm,
        .im = (numerator_im * denominator_re - numerator_re * denominator_im) / denominator_norm,
    };
    if (!std.math.isFinite(result.re) or !std.math.isFinite(result.im)) {
        return .{ .reactive_limit = if (gamma.im < 0.0) -std.math.inf(f64) else std.math.inf(f64) };
    }
    if (@abs(gamma.re * gamma.re + gamma.im * gamma.im - 1.0) <= TOLERANCE and @abs(gamma.im) > TOLERANCE) {
        return .{ .reactive_limit = result.im };
    }
    return .{ .finite = result };
}

fn roundToScaled(value: f64) i64 {
    const scaled = value * @as(f64, @floatFromInt(SCALE));
    if (scaled >= @as(f64, @floatFromInt(std.math.maxInt(i64)))) return std.math.maxInt(i64);
    if (scaled <= @as(f64, @floatFromInt(std.math.minInt(i64)))) return std.math.minInt(i64);
    return @intFromFloat(@round(scaled));
}

fn quantize(entry: TableEntry) QuantizedEntry {
    var result = QuantizedEntry{
        .gamma_re = roundToScaled(entry.gamma_re),
        .gamma_im = roundToScaled(entry.gamma_im),
        .impedance_re = 0,
        .impedance_im = 0,
        .state = .finite,
    };
    switch (entry.impedance) {
        .finite => |z| {
            result.impedance_re = roundToScaled(z.re);
            result.impedance_im = roundToScaled(z.im);
        },
        .open => {
            result.state = .open;
        },
        .short => {
            result.state = .short;
        },
        .reactive_limit => |value| {
            result.state = if (value < 0.0) .negative_reactive_limit else .positive_reactive_limit;
            result.impedance_im = roundToScaled(value);
        },
    }
    return result;
}

fn makeEntry(x: i8, y: i8) TableEntry {
    const point = concentricSquareToDisk(@as(f64, @floatFromInt(x)) / 7.0, @as(f64, @floatFromInt(y)) / 7.0);
    const gamma = Complex{ .re = point.x, .im = point.y };
    return .{
        .gamma_re = gamma.re,
        .gamma_im = gamma.im,
        .impedance = impedanceFromGamma(gamma),
    };
}

pub fn generateTable() [table.ENTRY_COUNT]QuantizedEntry {
    var entries: [table.ENTRY_COUNT]QuantizedEntry = undefined;
    for (0..15) |row| {
        for (0..15) |column| {
            const x: i8 = @intCast(@as(i16, @intCast(column)) - 7);
            const y: i8 = @intCast(@as(i16, @intCast(row)) - 7);
            entries[table.index(x, y).?] = quantize(makeEntry(x, y));
        }
    }
    return entries;
}

pub fn generateCoreTable() table.Table {
    return .{ .entries = generateTable() };
}

pub fn scale() i64 {
    return SCALE;
}

test "Shirley map sends origin to zero and square perimeter to unit circle" {
    const center = concentricSquareToDisk(0.0, 0.0);
    try std.testing.expectApproxEqAbs(@as(f64, 0.0), center.x, TOLERANCE);
    try std.testing.expectApproxEqAbs(@as(f64, 0.0), center.y, TOLERANCE);

    for (0..15) |i| {
        const coordinate = (@as(f64, @floatFromInt(i)) - 7.0) / 7.0;
        const points = [_]DiskPoint{
            concentricSquareToDisk(-1.0, coordinate),
            concentricSquareToDisk(1.0, coordinate),
            concentricSquareToDisk(coordinate, -1.0),
            concentricSquareToDisk(coordinate, 1.0),
        };
        for (points) |point| {
            const radius_squared = point.x * point.x + point.y * point.y;
            try std.testing.expectApproxEqAbs(@as(f64, 1.0), radius_squared, 1e-12);
        }
    }
}

test "Shirley mapping covers all square points inside unit disk with quadrant symmetry" {
    for (0..15) |row| {
        for (0..15) |column| {
            const u = (@as(f64, @floatFromInt(column)) - 7.0) / 7.0;
            const v = (@as(f64, @floatFromInt(row)) - 7.0) / 7.0;
            const point = concentricSquareToDisk(u, v);
            try std.testing.expect(std.math.isFinite(point.x) and std.math.isFinite(point.y));
            try std.testing.expect(point.x * point.x + point.y * point.y <= 1.0 + TOLERANCE);
            const rotated = concentricSquareToDisk(-v, u);
            try std.testing.expectApproxEqAbs(-point.y, rotated.x, TOLERANCE);
            try std.testing.expectApproxEqAbs(point.x, rotated.y, TOLERANCE);
        }
    }
}

test "standard impedance maps center to matched load and cardinal limits correctly" {
    const matched = impedanceFromGamma(.{ .re = 0.0, .im = 0.0 });
    try std.testing.expect(matched == .finite);
    try std.testing.expectApproxEqAbs(@as(f64, 1.0), matched.finite.re, TOLERANCE);
    try std.testing.expectApproxEqAbs(@as(f64, 0.0), matched.finite.im, TOLERANCE);
    try std.testing.expect(impedanceFromGamma(.{ .re = 1.0, .im = 0.0 }) == .open);
    try std.testing.expect(impedanceFromGamma(.{ .re = -1.0, .im = 0.0 }) == .short);

    const reactive = impedanceFromGamma(.{ .re = 0.0, .im = 1.0 });
    try std.testing.expect(reactive == .reactive_limit);
    try std.testing.expectApproxEqAbs(@as(f64, 1.0), reactive.reactive_limit, TOLERANCE);
}

test "quantized lookup contains 225 entries and bounded Gamma error" {
    const entries = generateTable();
    try std.testing.expectEqual(@as(usize, 225), entries.len);
    const center = entries[table.index(0, 0).?];
    try std.testing.expectEqual(@as(i64, 0), center.gamma_re);
    try std.testing.expectEqual(@as(i64, 0), center.gamma_im);
    try std.testing.expectEqual(table.ImpedanceState.finite, center.state);
    try std.testing.expectEqual(SCALE, center.impedance_re);
    try std.testing.expectEqual(@as(i64, 0), center.impedance_im);

    for (entries) |entry| {
        try std.testing.expect(entry.gamma_re >= -SCALE and entry.gamma_re <= SCALE);
        try std.testing.expect(entry.gamma_im >= -SCALE and entry.gamma_im <= SCALE);
    }

    for (0..15) |row| {
        for (0..15) |column| {
            const x: i8 = @intCast(@as(i16, @intCast(column)) - 7);
            const y: i8 = @intCast(@as(i16, @intCast(row)) - 7);
            const reference = makeEntry(x, y);
            const quantized = entries[table.index(x, y).?];
            const gamma_re = @as(f64, @floatFromInt(quantized.gamma_re)) / @as(f64, @floatFromInt(SCALE));
            const gamma_im = @as(f64, @floatFromInt(quantized.gamma_im)) / @as(f64, @floatFromInt(SCALE));
            try std.testing.expectApproxEqAbs(reference.gamma_re, gamma_re, 0.5 / @as(f64, @floatFromInt(SCALE)) + 1e-15);
            try std.testing.expectApproxEqAbs(reference.gamma_im, gamma_im, 0.5 / @as(f64, @floatFromInt(SCALE)) + 1e-15);
            switch (reference.impedance) {
                .finite => |z| {
                    try std.testing.expectEqual(table.ImpedanceState.finite, quantized.state);
                    try std.testing.expectApproxEqAbs(z.re, @as(f64, @floatFromInt(quantized.impedance_re)) / @as(f64, @floatFromInt(SCALE)), 1e-8);
                    try std.testing.expectApproxEqAbs(z.im, @as(f64, @floatFromInt(quantized.impedance_im)) / @as(f64, @floatFromInt(SCALE)), 1e-8);
                },
                .open => try std.testing.expectEqual(table.ImpedanceState.open, quantized.state),
                .short => try std.testing.expectEqual(table.ImpedanceState.short, quantized.state),
                .reactive_limit => |value| {
                    try std.testing.expect(quantized.state == .positive_reactive_limit or quantized.state == .negative_reactive_limit);
                    try std.testing.expectApproxEqAbs(value, @as(f64, @floatFromInt(quantized.impedance_im)) / @as(f64, @floatFromInt(SCALE)), 1e-8);
                },
            }
        }
    }

    const unique_gamma_count = blk: {
        var unique: usize = 0;
        for (entries, 0..) |entry, i| {
            var duplicate = false;
            for (entries[0..i]) |earlier| {
                if (entry.gamma_re == earlier.gamma_re and entry.gamma_im == earlier.gamma_im) {
                    duplicate = true;
                    break;
                }
            }
            if (!duplicate) unique += 1;
        }
        break :blk unique;
    };
    try std.testing.expectEqual(@as(usize, 225), unique_gamma_count);
}
