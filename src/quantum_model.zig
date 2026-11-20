const std = @import("std");

pub const FRACTIONAL_BITS: u6 = 32;
pub const ONE: i64 = 1 << FRACTIONAL_BITS;
pub const SQRT_HALF: i64 = 3_037_000_500;
pub const ROUNDING_TOLERANCE: i64 = 8;
pub const MAX_QUBITS: u8 = 2;
pub const SELECTOR_MAX: u64 = std.math.maxInt(u64);
pub const SEED_STEP: u64 = 0x9e3779b97f4a7c15;

pub const SelectorStream = struct {
    state: u64,

    pub fn init(seed: u64) SelectorStream {
        return .{ .state = seed };
    }

    pub fn next(self: *SelectorStream) u64 {
        self.state +%= SEED_STEP;
        var value = self.state;
        value = (value ^ (value >> 30)) *% 0xbf58476d1ce4e5b9;
        value = (value ^ (value >> 27)) *% 0x94d049bb133111eb;
        return value ^ (value >> 31);
    }
};

pub const ShotCounts = struct {
    counts: [4]u32 = [_]u32{0} ** 4,
    shots: u32 = 0,
};

pub const StateDigest = [32]u8;
pub const MAX_AMPLITUDE_MAGNITUDE: i64 = ONE;

pub const Complex = struct {
    re: i64 = 0,
    im: i64 = 0,

    pub const zero = Complex{};
    pub const one = Complex{ .re = ONE };

    fn add(a: Complex, b: Complex) error{Overflow}!Complex {
        return .{
            .re = try std.math.add(i64, a.re, b.re),
            .im = try std.math.add(i64, a.im, b.im),
        };
    }

    fn sub(a: Complex, b: Complex) error{Overflow}!Complex {
        return .{
            .re = try std.math.sub(i64, a.re, b.re),
            .im = try std.math.sub(i64, a.im, b.im),
        };
    }

    pub fn mul(a: Complex, b: Complex) error{Overflow}!Complex {
        const arbr = try mulFixed(a.re, b.re);
        const aibi = try mulFixed(a.im, b.im);
        const arbi = try mulFixed(a.re, b.im);
        const aibr = try mulFixed(a.im, b.re);
        return .{
            .re = try std.math.sub(i64, arbr, aibi),
            .im = try std.math.add(i64, arbi, aibr),
        };
    }

    pub fn scale(a: Complex, value: i64) error{Overflow}!Complex {
        return .{ .re = try mulFixed(a.re, value), .im = try mulFixed(a.im, value) };
    }

    pub fn normSquared(a: Complex) error{Overflow}!i64 {
        return squareSumToFixed(a.re, a.im);
    }
};

pub const State = struct {
    num_qubits: u8,
    amplitudes: [4]Complex,

    pub fn init(num_qubits: u8) error{UnsupportedQubitCount}!State {
        if (num_qubits == 0 or num_qubits > MAX_QUBITS) return error.UnsupportedQubitCount;
        var state = State{ .num_qubits = num_qubits, .amplitudes = [_]Complex{Complex.zero} ** 4 };
        state.amplitudes[0] = Complex.one;
        return state;
    }

    pub fn dimension(self: State) usize {
        return @as(usize, 1) << @intCast(self.num_qubits);
    }

    pub fn digest(self: State) StateDigest {
        var hasher = std.crypto.hash.sha2.Sha256.init(.{});
        hasher.update(&.{self.num_qubits});
        for (self.amplitudes) |amplitude| {
            hasher.update(std.mem.asBytes(&amplitude.re));
            hasher.update(std.mem.asBytes(&amplitude.im));
        }
        var result: StateDigest = undefined;
        hasher.final(&result);
        return result;
    }

    pub fn validate(self: State) error{ InvalidQubitCount, NonNormalized, Overflow }!void {
        if (self.num_qubits == 0 or self.num_qubits > MAX_QUBITS) return error.InvalidQubitCount;
        for (self.amplitudes[self.dimension()..]) |amplitude| {
            if (amplitude.re != 0 or amplitude.im != 0) return error.NonNormalized;
        }
        const norm = try self.normSquared();
        if (absDiff(norm, ONE) > ROUNDING_TOLERANCE) return error.NonNormalized;
        for (self.amplitudes[0..self.dimension()]) |amplitude| {
            if (magnitude64(amplitude.re) > MAX_AMPLITUDE_MAGNITUDE or
                magnitude64(amplitude.im) > MAX_AMPLITUDE_MAGNITUDE) return error.NonNormalized;
        }
    }

    pub fn normSquared(self: State) error{Overflow}!i64 {
        return sumToFixed(self.amplitudes[0..self.dimension()]);
    }

    pub fn probability(self: State, basis_index: usize) error{ InvalidBasisIndex, Overflow }!i64 {
        if (basis_index >= self.dimension()) return error.InvalidBasisIndex;
        return try self.amplitudes[basis_index].normSquared();
    }

    pub fn measure(self: *State, selector: u64) error{ InvalidState, InvalidQubitCount, InvalidSelector, Overflow }!usize {
        self.validate() catch |err| return switch (err) {
            error.InvalidQubitCount => error.InvalidQubitCount,
            error.NonNormalized => error.InvalidState,
            error.Overflow => error.Overflow,
        };
        const selected = try sampleIndex(self.*, selector);
        self.collapseTo(selected);
        return selected;
    }

    pub fn sample(self: State, selector: u64) error{ InvalidState, InvalidQubitCount, InvalidSelector, Overflow }!usize {
        return sampleIndex(self, selector);
    }

    pub fn runShots(self: State, shots: u32, seed: u64) error{ InvalidState, InvalidQubitCount, InvalidSelector, Overflow }!ShotCounts {
        self.validate() catch |err| return switch (err) {
            error.InvalidQubitCount => error.InvalidQubitCount,
            error.NonNormalized => error.InvalidState,
            error.Overflow => error.Overflow,
        };
        var result = ShotCounts{};
        var selectors = SelectorStream.init(seed);
        for (0..shots) |_| {
            const outcome = try sampleIndex(self, selectors.next());
            result.counts[outcome] = std.math.add(u32, result.counts[outcome], 1) catch return error.Overflow;
            result.shots = std.math.add(u32, result.shots, 1) catch return error.Overflow;
        }
        return result;
    }

    pub fn runShotsInto(self: State, counts: *ShotCounts, shots: u32, seed: u64) error{ InvalidState, InvalidQubitCount, InvalidSelector, Overflow }!void {
        const result = try self.runShots(shots, seed);
        counts.* = result;
    }

    fn collapseTo(self: *State, basis_index: usize) void {
        self.amplitudes = [_]Complex{Complex.zero} ** 4;
        self.amplitudes[basis_index] = Complex.one;
    }

    pub fn applyPauliX(self: *State, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.validate();
        if (target >= self.num_qubits) return error.InvalidQubitIndex;
        var next = self.*;
        const bit = @as(usize, 1) << @intCast(target);
        for (0..next.dimension()) |index| {
            if ((index & bit) == 0) std.mem.swap(Complex, &next.amplitudes[index], &next.amplitudes[index | bit]);
        }
        try next.validate();
        self.* = next;
    }

    pub fn applyPauliZ(self: *State, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.validate();
        if (target >= self.num_qubits) return error.InvalidQubitIndex;
        var next = self.*;
        const bit = @as(usize, 1) << @intCast(target);
        for (0..next.dimension()) |index| {
            if ((index & bit) != 0) {
                next.amplitudes[index].re = try std.math.negate(next.amplitudes[index].re);
                next.amplitudes[index].im = try std.math.negate(next.amplitudes[index].im);
            }
        }
        try next.validate();
        self.* = next;
    }

    pub fn applyS(self: *State, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.validate();
        if (target >= self.num_qubits) return error.InvalidQubitIndex;
        var next = self.*;
        const bit = @as(usize, 1) << @intCast(target);
        for (0..next.dimension()) |index| {
            if ((index & bit) != 0) {
                const real = next.amplitudes[index].re;
                next.amplitudes[index].re = try std.math.negate(next.amplitudes[index].im);
                next.amplitudes[index].im = real;
            }
        }
        try next.validate();
        self.* = next;
    }

    pub fn applyHadamard(self: *State, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.validate();
        if (target >= self.num_qubits) return error.InvalidQubitIndex;
        var next = self.*;
        const bit = @as(usize, 1) << @intCast(target);
        const length = next.dimension();
        var i: usize = 0;
        while (i < length) : (i += 1) {
            if ((i & bit) == 0) {
                const j = i | bit;
                const a = next.amplitudes[i];
                const b = next.amplitudes[j];
                next.amplitudes[i] = try (try a.add(b)).scale(SQRT_HALF);
                next.amplitudes[j] = try (try a.sub(b)).scale(SQRT_HALF);
            }
        }
        try next.validate();
        self.* = next;
    }

    pub fn applyCnot(self: *State, control: u8, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.validate();
        if (control >= self.num_qubits or target >= self.num_qubits or control == target) return error.InvalidQubitIndex;
        var next = self.*;
        const control_bit = @as(usize, 1) << @intCast(control);
        const target_bit = @as(usize, 1) << @intCast(target);
        for (0..next.dimension()) |i| {
            if ((i & control_bit) != 0 and (i & target_bit) == 0) {
                const j = i | target_bit;
                std.mem.swap(Complex, &next.amplitudes[i], &next.amplitudes[j]);
            }
        }
        try next.validate();
        self.* = next;
    }

    pub fn concurrence(self: State) error{ InvalidQubitCount, NonNormalized, Overflow, InvalidNorm }!i64 {
        try self.validate();
        if (self.num_qubits != 2) return error.InvalidQubitCount;
        const ad = try self.amplitudes[0].mul(self.amplitudes[3]);
        const bc = try self.amplitudes[1].mul(self.amplitudes[2]);
        const det = try ad.sub(bc);
        const determinant_norm = try det.normSquared();
        const magnitude = try sqrtFixed(determinant_norm);
        return std.math.mul(i64, magnitude, 2) catch error.Overflow;
    }
};

pub fn sampleIndex(state: State, selector: u64) error{ InvalidState, InvalidQubitCount, InvalidSelector, Overflow }!usize {
    state.validate() catch |err| return switch (err) {
        error.InvalidQubitCount => error.InvalidQubitCount,
        error.NonNormalized => error.InvalidState,
        error.Overflow => error.Overflow,
    };
    if (selector == SELECTOR_MAX) return error.InvalidSelector;
    const threshold: u128 = @as(u128, selector) * ONE / SELECTOR_MAX;
    var cumulative: u128 = 0;
    for (state.amplitudes[0..state.dimension()], 0..) |amplitude, index| {
        const weight = try amplitude.normSquared();
        cumulative += @intCast(weight);
        if (threshold < cumulative) return index;
    }
    return error.InvalidState;
}

fn mulFixed(a: i64, b: i64) error{Overflow}!i64 {
    const product = @as(i128, a) * @as(i128, b);
    return std.math.cast(i64, roundShiftNearestTiesAway(product, FRACTIONAL_BITS)) orelse error.Overflow;
}

fn sqrtFixed(value: i64) error{ InvalidNorm, Overflow }!i64 {
    if (value < 0) return error.InvalidNorm;
    const radicand = @as(u128, @intCast(value)) << FRACTIONAL_BITS;
    const root_floor = integerSqrt(radicand);
    const low_error = radicand - root_floor * root_floor;
    const next = root_floor + 1;
    const high_error = next * next - radicand;
    const root = if (low_error < high_error or (low_error == high_error and root_floor & 1 == 0)) root_floor else next;
    return std.math.cast(i64, root) orelse error.Overflow;
}

fn roundShiftNearestTiesAway(value: i128, shift: u6) i128 {
    const divisor: i128 = @as(i128, 1) << shift;
    const half = @divTrunc(divisor, 2);
    return if (value >= 0)
        @divTrunc(value + half, divisor)
    else
        -@divTrunc(-value + half, divisor);
}

fn magnitude64(value: i64) u64 {
    return if (value < 0)
        @as(u64, @intCast(-(value + 1))) + 1
    else
        @intCast(value);
}

fn integerSqrt(value: u128) u128 {
    if (value < 2) return value;
    var x = value;
    var next = (x + 1) / 2;
    while (next < x) {
        x = next;
        next = (x + value / x) / 2;
    }
    return x;
}

fn squareSumToFixed(a: i64, b: i64) error{Overflow}!i64 {
    const a_mag: u128 = magnitude64(a);
    const b_mag: u128 = magnitude64(b);
    const a_sq = std.math.mul(u128, a_mag, a_mag) catch return error.Overflow;
    const b_sq = std.math.mul(u128, b_mag, b_mag) catch return error.Overflow;
    const sum = std.math.add(u128, a_sq, b_sq) catch return error.Overflow;
    const half = @as(u128, 1) << (FRACTIONAL_BITS - 1);
    const rounded_sum = std.math.add(u128, sum, half) catch return error.Overflow;
    const rounded = rounded_sum >> FRACTIONAL_BITS;
    return std.math.cast(i64, rounded) orelse error.Overflow;
}

fn sumToFixed(values: []const Complex) error{Overflow}!i64 {
    var sum: i64 = 0;
    for (values) |value| {
        sum = std.math.add(i64, sum, try value.normSquared()) catch return error.Overflow;
    }
    return sum;
}

fn absDiff(a: i64, b: i64) i64 {
    return if (a >= b) a - b else b - a;
}

test "Hadamard creates balanced one-qubit probabilities and is self-inverse" {
    var state = try State.init(1);
    try state.applyHadamard(0);
    const p0 = try state.probability(0);
    const p1 = try state.probability(1);
    try std.testing.expect(absDiff(p0, ONE / 2) <= ROUNDING_TOLERANCE);
    try std.testing.expect(absDiff(p1, ONE / 2) <= ROUNDING_TOLERANCE);
    try state.applyHadamard(0);
    try std.testing.expect(absDiff(state.amplitudes[0].re, ONE) <= ROUNDING_TOLERANCE);
    try std.testing.expectEqual(@as(i64, 0), state.amplitudes[1].re);
}

test "Hadamard then CNOT yields the Bell state and unit concurrence" {
    var state = try State.init(2);
    try state.applyHadamard(0);
    try state.applyCnot(0, 1);
    try std.testing.expect(absDiff(state.amplitudes[0].re, SQRT_HALF) <= ROUNDING_TOLERANCE);
    try std.testing.expectEqual(Complex.zero, state.amplitudes[1]);
    try std.testing.expectEqual(Complex.zero, state.amplitudes[2]);
    try std.testing.expect(absDiff(state.amplitudes[3].re, SQRT_HALF) <= ROUNDING_TOLERANCE);
    try std.testing.expect(absDiff(try state.concurrence(), ONE) <= 64);
}

test "product state has zero concurrence" {
    var state = try State.init(2);
    try state.applyHadamard(0);
    try state.applyHadamard(1);
    try std.testing.expectEqual(@as(i64, 0), try state.concurrence());
}

test "Pauli X and Z are reversible under repeated application" {
    var state = try State.init(1);
    const original = state;
    try state.applyPauliX(0);
    try state.applyPauliX(0);
    try std.testing.expectEqual(original, state);
    try state.applyHadamard(0);
    const superposition = state;
    try state.applyPauliZ(0);
    try state.applyPauliZ(0);
    try std.testing.expectEqual(superposition, state);
}

test "Born measurement follows cumulative squared amplitudes and collapses" {
    var state = try State.init(1);
    try state.applyHadamard(0);
    try std.testing.expectEqual(@as(usize, 0), try state.measure(0));
    try std.testing.expectEqual(Complex.one, state.amplitudes[0]);
    try std.testing.expectEqual(Complex.zero, state.amplitudes[1]);

    var second = try State.init(1);
    try second.applyHadamard(0);
    try std.testing.expectEqual(@as(usize, 1), try second.measure(SELECTOR_MAX - 1));
    try std.testing.expectEqual(Complex.zero, second.amplitudes[0]);
    try std.testing.expectEqual(Complex.one, second.amplitudes[1]);
}

test "explicit selector measurement is repeatable and rejects invalid states" {
    var left = try State.init(2);
    var right = try State.init(2);
    try left.applyHadamard(0);
    try right.applyHadamard(0);
    try std.testing.expectEqual(try left.measure(0x123456789abcdef0), try right.measure(0x123456789abcdef0));
    left.amplitudes[0] = Complex.zero;
    try std.testing.expectError(error.InvalidState, left.measure(0));
}

test "seeded shot batches reproduce counts and approach equal Hadamard outcomes" {
    var state = try State.init(1);
    try state.applyHadamard(0);
    const first = try state.runShots(10_000, 42);
    const second = try state.runShots(10_000, 42);
    try std.testing.expectEqual(first, second);
    try std.testing.expectEqual(@as(u32, 10_000), first.shots);
    try std.testing.expect(@abs(@as(i64, first.counts[0]) - 5_000) < 300);
    try std.testing.expect(@abs(@as(i64, first.counts[1]) - 5_000) < 300);
}

test "failed shot requests do not modify caller-owned count output" {
    var state = try State.init(1);
    state.amplitudes[0] = Complex.zero;
    var counts = ShotCounts{ .counts = .{ 1, 2, 3, 4 }, .shots = 10 };
    const before = counts;
    try std.testing.expectError(error.InvalidState, state.runShotsInto(&counts, 100, 17));
    try std.testing.expectEqual(before, counts);
}

test "measurement refuses the excluded upper selector and preserves state" {
    var state = try State.init(1);
    try state.applyHadamard(0);
    const before = state;
    try std.testing.expectError(error.InvalidSelector, state.measure(SELECTOR_MAX));
    try std.testing.expectEqual(before, state);
}

test "state validation rejects nonzero unused amplitudes and checked overflow" {
    var state = try State.init(1);
    state.amplitudes[3] = Complex.one;
    try std.testing.expectError(error.NonNormalized, state.validate());

    state.amplitudes = [_]Complex{Complex.zero} ** 4;
    state.amplitudes[0] = .{ .re = std.math.maxInt(i64) };
    try std.testing.expectError(error.Overflow, state.validate());

    state.amplitudes[0] = .{ .re = 2 * ONE };
    state.amplitudes[1] = .{ .re = -ONE };
    try std.testing.expectError(error.NonNormalized, state.validate());
}

test "gate arithmetic failure leaves state unchanged" {
    var state = try State.init(1);
    state.amplitudes[0] = .{ .re = std.math.maxInt(i64) };
    state.amplitudes[1] = .{ .re = std.math.maxInt(i64) };
    const before = state;
    try std.testing.expectError(error.Overflow, state.applyHadamard(0));
    try std.testing.expectEqual(before, state);
}

test "checked gates leave state unchanged on validation failure" {
    var state = try State.init(1);
    state.amplitudes[0] = Complex.zero;
    const before = state;
    try std.testing.expectError(error.NonNormalized, state.applyPauliX(0));
    try std.testing.expectEqual(before, state);
}

test "invalid state dimensions, gate indices, and probabilities are rejected" {
    try std.testing.expectError(error.UnsupportedQubitCount, State.init(0));
    var state = try State.init(1);
    try std.testing.expectError(error.InvalidQubitIndex, state.applyHadamard(1));
    try std.testing.expectError(error.InvalidQubitIndex, state.applyCnot(0, 0));
    try std.testing.expectError(error.InvalidBasisIndex, state.probability(2));
    state.amplitudes[0] = Complex.zero;
    try std.testing.expectError(error.NonNormalized, state.validate());
}
