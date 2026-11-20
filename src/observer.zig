const std = @import("std");
const quantum = @import("quantum_model.zig");

pub const Snapshot = struct {
    amplitudes: [4]quantum.Complex,
    num_qubits: u8,

    pub fn fromState(state: quantum.State) Snapshot {
        return .{ .amplitudes = state.amplitudes, .num_qubits = state.num_qubits };
    }

    pub fn digest(self: Snapshot) [32]u8 {
        const state = quantum.State{ .amplitudes = self.amplitudes, .num_qubits = self.num_qubits };
        return state.digest();
    }

    pub fn readout(self: Snapshot) error{ InvalidQubitCount, InvalidBasisIndex, InvalidSelector, InvalidState, Overflow }!u8 {
        return @intCast(try self.measurement(0));
    }

    pub fn measurement(self: Snapshot, selector: u64) error{ InvalidQubitCount, InvalidBasisIndex, InvalidSelector, InvalidState, Overflow }!usize {
        const state = quantum.State{ .amplitudes = self.amplitudes, .num_qubits = self.num_qubits };
        state.validate() catch |err| return switch (err) {
            error.InvalidQubitCount => error.InvalidQubitCount,
            error.NonNormalized => error.InvalidState,
            error.Overflow => error.Overflow,
        };
        return quantum.sampleIndex(state, selector) catch |err| return switch (err) {
            error.InvalidQubitCount => error.InvalidQubitCount,
            error.InvalidState => error.InvalidState,
            error.InvalidSelector => error.InvalidSelector,
            error.Overflow => error.Overflow,
        };
    }
};

pub const Observer = struct {
    samples: u32 = 0,

    pub fn observe(self: *Observer, snapshot: Snapshot, selector: u64) error{ InvalidQubitCount, InvalidBasisIndex, InvalidSelector, InvalidState, Overflow, SampleCountOverflow }!u8 {
        const result = try snapshot.measurement(selector);
        if (result > std.math.maxInt(u8)) return error.InvalidBasisIndex;
        self.samples = std.math.add(u32, self.samples, 1) catch return error.SampleCountOverflow;
        return @intCast(result);
    }
};

pub fn explicitMeasurement(state: *quantum.State, selector: u64) error{ InvalidState, InvalidQubitCount, InvalidSelector, Overflow }!usize {
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
    try std.testing.expectEqual(@as(u8, 1), try observer.observe(Snapshot.fromState(state), quantum.SELECTOR_MAX - 1));
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
    try std.testing.expectEqual(@as(usize, 1), try explicitMeasurement(&state, quantum.SELECTOR_MAX - 1));
    try std.testing.expectEqual(quantum.Complex.one, state.amplitudes[1]);
    try std.testing.expect(!std.mem.eql(u8, &before, &Snapshot.fromState(state).digest()));
}

test "observer and managed mutation reject invalid state or index" {
    var observer = Observer{};
    const invalid = Snapshot{ .amplitudes = [_]quantum.Complex{quantum.Complex.zero} ** 4, .num_qubits = 1 };
    try std.testing.expectError(error.InvalidState, observer.observe(invalid, 0));
    try std.testing.expectEqual(@as(u32, 0), observer.samples);
    const valid = Snapshot.fromState(try quantum.State.init(1));
    try std.testing.expectError(error.InvalidSelector, observer.observe(valid, quantum.SELECTOR_MAX));
    try std.testing.expectEqual(@as(u32, 0), observer.samples);
    var state = try quantum.State.init(1);
    try std.testing.expectError(error.InvalidQubitIndex, managedFlip(&state, 1));
}
