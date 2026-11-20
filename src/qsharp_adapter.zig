const std = @import("std");
const quantum = @import("quantum_model.zig");

pub const Result = enum(u8) {
    zero = 0,
    one = 1,
};

pub const Register = struct {
    state: quantum.State,

    pub fn init(qubit_count: u8) error{UnsupportedQubitCount}!Register {
        return .{ .state = try quantum.State.init(qubit_count) };
    }

    pub fn h(self: *Register, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.state.applyHadamard(target);
    }

    pub fn x(self: *Register, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.state.applyPauliX(target);
    }

    pub fn z(self: *Register, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.state.applyPauliZ(target);
    }

    pub fn s(self: *Register, target: u8) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.state.applyS(target);
    }

    pub fn cnot(
        self: *Register,
        control: u8,
        target: u8,
    ) error{ InvalidQubitIndex, InvalidQubitCount, NonNormalized, Overflow }!void {
        try self.state.applyCnot(control, target);
    }

    pub fn measure(
        self: Register,
        selector: u64,
    ) error{ InvalidState, InvalidQubitCount, InvalidSelector, Overflow }!usize {
        return self.state.sample(selector);
    }

    pub fn measureAndReset(
        self: *Register,
        target: u8,
        selector: u64,
    ) error{ InvalidQubitIndex, InvalidQubitCount, InvalidSelector, InvalidState, Overflow }!Result {
        if (target >= self.state.num_qubits) return error.InvalidQubitIndex;
        const selected = try self.state.measure(selector);
        const outcome: Result = if ((selected & (@as(usize, 1) << @intCast(target))) == 0) .zero else .one;
        if (outcome == .one) self.state.applyPauliX(target) catch |err| return switch (err) {
            error.InvalidQubitIndex => error.InvalidQubitIndex,
            error.InvalidQubitCount => error.InvalidQubitCount,
            error.NonNormalized => error.InvalidState,
            error.Overflow => error.Overflow,
        };
        return outcome;
    }

    pub fn reset(self: *Register) error{ InvalidQubitCount, InvalidState, Overflow }!void {
        if (self.state.num_qubits != 1) return error.InvalidQubitCount;
        _ = self.measureAndReset(0, 0) catch |err| return switch (err) {
            error.InvalidQubitIndex => error.InvalidQubitCount,
            error.InvalidQubitCount => error.InvalidQubitCount,
            error.InvalidSelector => error.InvalidState,
            error.InvalidState => error.InvalidState,
            error.Overflow => error.Overflow,
        };
    }
};

test "Q#-style operation adapter maps H and CNOT to the bounded model" {
    var register = try Register.init(2);
    try register.h(0);
    try register.cnot(0, 1);
    try std.testing.expectEqual(quantum.ONE, try register.state.normSquared());
    try std.testing.expectEqual(quantum.ONE, try register.state.concurrence());
}

test "measurement is non-mutating and measure-and-reset is explicit" {
    var register = try Register.init(1);
    try register.h(0);
    const before = register.state.digest();
    _ = try register.measure(0);
    try std.testing.expectEqual(before, register.state.digest());

    const result = try register.measureAndReset(0, quantum.SELECTOR_MAX - 1);
    try std.testing.expectEqual(Result.one, result);
    try std.testing.expectEqual(quantum.Complex.one, register.state.amplitudes[0]);
}

test "reset restores the one-qubit zero basis state" {
    var register = try Register.init(1);
    try register.x(0);
    try register.reset();
    try std.testing.expectEqual(quantum.Complex.one, register.state.amplitudes[0]);
    try std.testing.expectEqual(quantum.Complex.zero, register.state.amplitudes[1]);
}

test "invalid target and selector are rejected without mutation" {
    var register = try Register.init(1);
    const before = register.state;
    try std.testing.expectError(error.InvalidQubitIndex, register.x(1));
    try std.testing.expectError(error.InvalidSelector, register.measureAndReset(0, quantum.SELECTOR_MAX));
    try std.testing.expectEqual(before, register.state);
}
