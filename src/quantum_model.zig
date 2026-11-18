const std = @import("std");

pub const FRACTIONAL_BITS: u6 = 32;
pub const ONE: i64 = 1 << FRACTIONAL_BITS;
pub const SQRT_HALF: i64 = 3_037_000_500;
pub const ROUNDING_TOLERANCE: i64 = 8;
pub const MAX_QUBITS: u8 = 2;
pub const DEFAULT_MEASUREMENT_SHOTS: u32 = 1;

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
        return std.math.add(i64, try mulFixed(a.re, a.re), try mulFixed(a.im, a.im));
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

    pub fn validate(self: State) error{ InvalidQubitCount, NonNormalized, Overflow }!void {
        if (self.num_qubits == 0 or self.num_qubits > MAX_QUBITS) return error.InvalidQubitCount;
        const norm = try self.normSquared();
        if (absDiff(norm, ONE) > ROUNDING_TOLERANCE) return error.NonNormalized;
    }

    pub fn normSquared(self: State) error{Overflow}!i64 {
        var total: i64 = 0;
        for (self.amplitudes[0..self.dimension()]) |amplitude| {
            total = try std.math.add(i64, total, try amplitude.normSquared());
        }
        return total;
    }

    pub fn probability(self: State, basis_index: usize) error{ InvalidBasisIndex, Overflow }!i64 {
        if (basis_index >= self.dimension()) return error.InvalidBasisIndex;
        return try self.amplitudes[basis_index].normSquared();
    }

    pub fn measure(self: *State, selector: u64) error{ InvalidState, InvalidQubitCount, Overflow }!usize {
        self.validate() catch return error.InvalidState;
        const selected = try sampleIndex(self.*, selector);
        self.collapseTo(selected);
        return selected;
    }

    fn collapseTo(self: *State, basis_index: usize) void {
        self.amplitudes = [_]Complex{Complex.zero} ** 4;
        self.amplitudes[basis_index] = Complex.one;
    }

    pub fn applyPauliX(self: *State, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.validate();
        if (target >= self.num_qubits) return error.InvalidQubitIndex;
        const bit = @as(usize, 1) << @intCast(target);
        for (0..self.dimension()) |index| {
            if ((index & bit) == 0) std.mem.swap(Complex, &self.amplitudes[index], &self.amplitudes[index | bit]);
        }
        try self.validate();
    }

    pub fn applyPauliZ(self: *State, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.validate();
        if (target >= self.num_qubits) return error.InvalidQubitIndex;
        const bit = @as(usize, 1) << @intCast(target);
        for (0..self.dimension()) |index| {
            if ((index & bit) != 0) {
                self.amplitudes[index].re = try std.math.negate(self.amplitudes[index].re);
                self.amplitudes[index].im = try std.math.negate(self.amplitudes[index].im);
            }
        }
        try self.validate();
    }

    pub fn applyHadamard(self: *State, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.validate();
        if (target >= self.num_qubits) return error.InvalidQubitIndex;
        const bit = @as(usize, 1) << @intCast(target);
        const length = self.dimension();
        var i: usize = 0;
        while (i < length) : (i += 1) {
            if ((i & bit) == 0) {
                const j = i | bit;
                const a = self.amplitudes[i];
                const b = self.amplitudes[j];
                self.amplitudes[i] = try (try a.add(b)).scale(SQRT_HALF);
                self.amplitudes[j] = try (try a.sub(b)).scale(SQRT_HALF);
            }
        }
        try self.validate();
    }

    pub fn applyCnot(self: *State, control: u8, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.validate();
        if (control >= self.num_qubits or target >= self.num_qubits or control == target) return error.InvalidQubitIndex;
        const control_bit = @as(usize, 1) << @intCast(control);
        const target_bit = @as(usize, 1) << @intCast(target);
        for (0..self.dimension()) |i| {
            if ((i & control_bit) != 0 and (i & target_bit) == 0) {
                const j = i | target_bit;
                std.mem.swap(Complex, &self.amplitudes[i], &self.amplitudes[j]);
            }
        }
        try self.validate();
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

fn sampleIndex(state: State, selector: u64) error{ InvalidState, Overflow }!usize {
    const threshold: u128 = (@as(u128, selector) * @as(u128, ONE)) >> 64;
    var cumulative: u128 = 0;
    var last_positive: usize = 0;
    for (state.amplitudes[0..state.dimension()], 0..) |amplitude, index| {
        const weight = try amplitude.normSquared();
        cumulative += @intCast(weight);
        if (weight > 0) last_positive = index;
        if (threshold < cumulative) return index;
    }
    if (last_positive >= state.dimension()) return error.InvalidState;
    return last_positive;
}

fn mulFixed(a: i64, b: i64) error{Overflow}!i64 {
    const product = @as(i128, a) * @as(i128, b);
    const rounded = if (product >= 0)
        product + (@as(i128, 1) << (FRACTIONAL_BITS - 1))
    else
        product - (@as(i128, 1) << (FRACTIONAL_BITS - 1));
    const result = rounded >> FRACTIONAL_BITS;
    return std.math.cast(i64, result) orelse error.Overflow;
}

fn sqrtFixed(value: i64) error{ InvalidNorm, Overflow }!i64 {
    if (value < 0) return error.InvalidNorm;
    const radicand = @as(u128, @intCast(value)) << FRACTIONAL_BITS;
    const root = std.math.sqrt(radicand);
    return std.math.cast(i64, root) orelse error.Overflow;
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
    try std.testing.expectEqual(@as(usize, 1), try second.measure(std.math.maxInt(u64)));
    try std.testing.expectEqual(Complex.zero, second.amplitudes[0]);
    try std.testing.expectEqual(Complex.one, second.amplitudes[1]);
}

test "Born measurement is seeded-reproducible and rejects invalid states" {
    var left = try State.init(2);
    var right = try State.init(2);
    try left.applyHadamard(0);
    try right.applyHadamard(0);
    try std.testing.expectEqual(try left.measure(0x123456789abcdef0), try right.measure(0x123456789abcdef0));
    left.amplitudes[0] = Complex.zero;
    try std.testing.expectError(error.InvalidState, left.measure(0));
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
