const std = @import("std");
const quantum = @import("quantum_model.zig");

pub const Snapshot = struct {
    amplitudes: [4]quantum.Complex,
    num_qubits: u8,

    pub fn fromState(state: quantum.State) Snapshot {
        return .{ .amplitudes = state.amplitudes, .num_qubits = state.num_qubits };
    }

    pub fn digest(self: Snapshot) [32]u8 {
        var hasher = std.crypto.hash.sha2.Sha256.init(.{});
        hasher.update(&.{self.num_qubits});
        for (self.amplitudes) |amplitude| {
            hasher.update(std.mem.asBytes(&amplitude.re));
            hasher.update(std.mem.asBytes(&amplitude.im));
        }
        var result: [32]u8 = undefined;
        hasher.final(&result);
        return result;
    }

    pub fn readout(self: Snapshot) error{ InvalidQubitCount, InvalidBasisIndex, InvalidState, Overflow }!u8 {
        return @intCast(try self.measurement(0));
    }

    pub fn measurement(self: Snapshot, selector: u64) error{ InvalidQubitCount, InvalidBasisIndex, InvalidState, Overflow }!usize {
        var state = quantum.State{ .amplitudes = self.amplitudes, .num_qubits = self.num_qubits };
        state.validate() catch |err| switch (err) {
            error.InvalidQubitCount => return error.InvalidQubitCount,
            error.NonNormalized => return error.InvalidState,
            error.Overflow => return error.Overflow,
        };
        return try sampleIndex(state, selector);
    }
};

fn sampleIndex(state: quantum.State, selector: u64) error{ InvalidState, Overflow }!usize {
    const threshold: u128 = (@as(u128, selector) * @as(u128, quantum.ONE)) >> 64;
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

pub const Observer = struct {
    samples: u32 = 0,

    pub fn observe(self: *Observer, snapshot: Snapshot, selector: u64) error{ InvalidQubitCount, InvalidBasisIndex, InvalidState, Overflow, SampleCountOverflow }!u8 {
        const result = try snapshot.measurement(selector);
        if (result > std.math.maxInt(u8)) return error.InvalidBasisIndex;
        self.samples = std.math.add(u32, self.samples, 1) catch return error.SampleCountOverflow;
        return @intCast(result);
    }
};

pub fn explicitMeasurement(state: *quantum.State, selector: u64) error{ InvalidState, InvalidQubitCount, Overflow }!usize {
    return state.measure(selector);
}

pub fn managedFlip(state: *quantum.State, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
    try state.validate();
    if (target >= state.num_qubits) return error.InvalidQubitIndex;
    const bit = @as(usize, 1) << @intCast(target);
    for (0..state.dimension()) |index| {
        if ((index & bit) == 0) std.mem.swap(quantum.Complex, &state.amplitudes[index], &state.amplitudes[index | bit]);
    }
    try state.validate();
}

test "passive observations return stable readout and do not change state digest" {
    var state = try quantum.State.init(1);
    try state.applyHadamard(0);
    const before = Snapshot.fromState(state).digest();
    var observer = Observer{};
    try std.testing.expectEqual(@as(u8, 0), try observer.observe(Snapshot.fromState(state), 0));
    try std.testing.expectEqual(@as(u8, 1), try observer.observe(Snapshot.fromState(state), std.math.maxInt(u64)));
    try std.testing.expectEqual(@as(u32, 2), observer.samples);
    try std.testing.expectEqual(before, Snapshot.fromState(state).digest());
}

test "explicit managed flip changes the state digest" {
    var state = try quantum.State.init(1);
    const before = Snapshot.fromState(state).digest();
    try managedFlip(&state, 0);
    try std.testing.expectEqual(quantum.Complex.one, state.amplitudes[1]);
    try std.testing.expect(!std.mem.eql(u8, &before, &Snapshot.fromState(state).digest()));
}

test "explicit measurement collapses the owned state by its Born weights" {
    var state = try quantum.State.init(1);
    try state.applyHadamard(0);
    const before = Snapshot.fromState(state).digest();
    try std.testing.expectEqual(@as(usize, 1), try explicitMeasurement(&state, std.math.maxInt(u64)));
    try std.testing.expectEqual(quantum.Complex.one, state.amplitudes[1]);
    try std.testing.expect(!std.mem.eql(u8, &before, &Snapshot.fromState(state).digest()));
}

test "observer and managed mutation reject invalid state or index" {
    var observer = Observer{};
    const invalid = Snapshot{ .amplitudes = [_]quantum.Complex{quantum.Complex.zero} ** 4, .num_qubits = 1 };
    try std.testing.expectError(error.InvalidState, observer.observe(invalid, 0));
    try std.testing.expectEqual(@as(u32, 0), observer.samples);
    var state = try quantum.State.init(1);
    try std.testing.expectError(error.InvalidQubitIndex, managedFlip(&state, 1));
}
