const std = @import("std");

pub const REGISTER_BITS: usize = 256;
pub const MAX_INSTRUCTIONS: usize = 256;
pub const Register = u256;

pub const Gate = union(enum) {
    not: u8,
    cnot: struct { control: u8, target: u8 },
    toffoli: struct { a: u8, b: u8, target: u8 },
    fredkin: struct { control: u8, a: u8, b: u8 },
    swap: struct { a: u8, b: u8 },
    peres: struct { a: u8, b: u8, c: u8 },
    peres_inverse: struct { a: u8, b: u8, c: u8 },
};

pub const Instruction = struct { gate: Gate };
pub const Error = error{ InvalidGate, ProgramFull, InvalidProgram, InvalidWidth };

pub const Program = struct {
    instructions: [MAX_INSTRUCTIONS]Instruction = undefined,
    len: usize = 0,

    pub fn emit(self: *Program, gate: Gate) Error!void {
        if (self.len >= MAX_INSTRUCTIONS) return error.ProgramFull;
        try validateGate(gate);
        self.instructions[self.len] = .{ .gate = gate };
        self.len += 1;
    }
};

pub fn apply(state: Register, gate: Gate) Error!Register {
    try validateGate(gate);
    return switch (gate) {
        .not => |index| state ^ bitMask(index),
        .cnot => |g| if (bit(state, g.control) != 0) state ^ bitMask(g.target) else state,
        .toffoli => |g| if (bit(state, g.a) != 0 and bit(state, g.b) != 0) state ^ bitMask(g.target) else state,
        .fredkin => |g| if (bit(state, g.control) != 0) swapBits(state, g.a, g.b) else state,
        .swap => |g| swapBits(state, g.a, g.b),
        .peres => |g| peres(state, g.a, g.b, g.c, false),
        .peres_inverse => |g| peres(state, g.a, g.b, g.c, true),
    };
}

pub fn inverse(gate: Gate) Error!Gate {
    try validateGate(gate);
    return switch (gate) {
        .peres => |g| .{ .peres_inverse = .{ .a = g.a, .b = g.b, .c = g.c } },
        .peres_inverse => |g| .{ .peres = .{ .a = g.a, .b = g.b, .c = g.c } },
        else => gate,
    };
}

pub fn run(register: Register, program: *const Program) Error!Register {
    try validateProgram(program);
    var result = register;
    for (program.instructions[0..program.len]) |instruction| {
        result = try apply(result, instruction.gate);
    }
    return result;
}

pub fn uncompute(register: Register, program: *const Program) Error!Register {
    try validateProgram(program);
    var result = register;
    var index = program.len;
    while (index > 0) {
        index -= 1;
        result = try apply(result, try inverse(program.instructions[index].gate));
    }
    return result;
}

pub fn runThenUncompute(register: Register, program: *const Program) Error!Register {
    return uncompute(try run(register, program), program);
}

pub fn isBijective(program: *const Program, width: u8) bool {
    if (width == 0 or width > 8 or program.len > MAX_INSTRUCTIONS) return false;
    for (program.instructions[0..program.len]) |instruction| {
        validateGateForWidth(instruction.gate, width) catch return false;
    }

    var seen: u256 = 0;
    const limit: u16 = @as(u16, 1) << @intCast(width);
    for (0..limit) |input| {
        const output = (run(@intCast(input), program) catch return false);
        const marker = @as(u256, 1) << @intCast(output);
        if (seen & marker != 0) return false;
        seen |= marker;
    }
    return true;
}

pub const BennettResult = struct {
    output: Register,
    restored_work: Register,
};

pub fn computeCopyUncompute(input: Register, program: *const Program, output_mask: Register) Error!BennettResult {
    const work = try run(input, program);
    const output = work & output_mask;
    const restored = try uncompute(work, program);
    return .{ .output = output, .restored_work = restored };
}

fn validateProgram(program: *const Program) Error!void {
    if (program.len > MAX_INSTRUCTIONS) return error.InvalidProgram;
    for (program.instructions[0..program.len]) |instruction| try validateGate(instruction.gate);
}

fn validateGate(gate: Gate) Error!void {
    return switch (gate) {
        .not => {},
        .cnot => |g| if (g.control == g.target) error.InvalidGate,
        .toffoli => |g| if (g.a == g.b or g.a == g.target or g.b == g.target) error.InvalidGate,
        .fredkin => |g| if (g.control == g.a or g.control == g.b or g.a == g.b) error.InvalidGate,
        .swap => |g| if (g.a == g.b) error.InvalidGate,
        .peres => |g| if (g.a == g.b or g.a == g.c or g.b == g.c) error.InvalidGate,
        .peres_inverse => |g| if (g.a == g.b or g.a == g.c or g.b == g.c) error.InvalidGate,
    };
}

fn validateGateForWidth(gate: Gate, width: u8) Error!void {
    try validateGate(gate);
    switch (gate) {
        .not => |i| if (i >= width) return error.InvalidGate,
        .cnot => |g| if (g.control >= width or g.target >= width) return error.InvalidGate,
        .toffoli => |g| if (g.a >= width or g.b >= width or g.target >= width) return error.InvalidGate,
        .fredkin => |g| if (g.control >= width or g.a >= width or g.b >= width) return error.InvalidGate,
        .swap => |g| if (g.a >= width or g.b >= width) return error.InvalidGate,
        .peres => |g| if (g.a >= width or g.b >= width or g.c >= width) return error.InvalidGate,
        .peres_inverse => |g| if (g.a >= width or g.b >= width or g.c >= width) return error.InvalidGate,
    }
}

fn bit(state: Register, index: u8) u1 {
    return @intCast((state >> @intCast(index)) & 1);
}

fn bitMask(index: u8) Register {
    return @as(Register, 1) << @intCast(index);
}

fn swapBits(state: Register, a: u8, b: u8) Register {
    if (bit(state, a) == bit(state, b)) return state;
    return state ^ bitMask(a) ^ bitMask(b);
}

fn peres(state: Register, a: u8, b: u8, c: u8, inverse_gate: bool) Register {
    const va = bit(state, a);
    const vb = bit(state, b);
    const vc = bit(state, c);
    const next_b = va ^ vb;
    const next_c = if (inverse_gate) (va & next_b) ^ vc else (va & vb) ^ vc;
    return (state & ~(bitMask(b) | bitMask(c))) |
        (@as(Register, next_b) << @intCast(b)) |
        (@as(Register, next_c) << @intCast(c));
}

test "gate sequence reverses exactly for all 8-bit inputs" {
    var program = Program{};
    try program.emit(.{ .peres = .{ .a = 0, .b = 1, .c = 2 } });
    try program.emit(.{ .fredkin = .{ .control = 2, .a = 0, .b = 1 } });
    try program.emit(.{ .toffoli = .{ .a = 1, .b = 2, .target = 0 } });
    for (0..256) |input| {
        try std.testing.expectEqual(@as(Register, input), try runThenUncompute(input, &program));
    }
}

test "supported gates are permutations over an exhaustive 8-bit domain" {
    const gates = [_]Gate{
        .{ .not = 0 },
        .{ .cnot = .{ .control = 0, .target = 1 } },
        .{ .toffoli = .{ .a = 0, .b = 1, .target = 2 } },
        .{ .fredkin = .{ .control = 0, .a = 1, .b = 2 } },
        .{ .swap = .{ .a = 1, .b = 2 } },
        .{ .peres = .{ .a = 0, .b = 1, .c = 2 } },
        .{ .peres_inverse = .{ .a = 0, .b = 1, .c = 2 } },
    };
    for (gates) |gate| {
        var program = Program{};
        try program.emit(gate);
        try std.testing.expect(isBijective(&program, 8));
    }
}

test "Bennett compute-copy-uncompute preserves the output and restores work" {
    var program = Program{};
    try program.emit(.{ .cnot = .{ .control = 0, .target = 1 } });
    try program.emit(.{ .toffoli = .{ .a = 0, .b = 1, .target = 2 } });
    const initial: Register = 1;
    const result = try computeCopyUncompute(initial, &program, bitMask(2));
    try std.testing.expectEqual(@as(Register, 1) << 2, result.output);
    try std.testing.expectEqual(initial, result.restored_work);
}

test "invalid aliases, widths, program sizes, and forged lengths fail closed" {
    var program = Program{};
    try std.testing.expectError(error.InvalidGate, program.emit(.{ .cnot = .{ .control = 1, .target = 1 } }));
    try std.testing.expect(!isBijective(&program, 0));
    try std.testing.expect(!isBijective(&program, 9));
    try program.emit(.{ .not = 8 });
    try std.testing.expect(!isBijective(&program, 8));

    var forged = Program{};
    forged.len = MAX_INSTRUCTIONS + 1;
    try std.testing.expectError(error.InvalidProgram, run(0, &forged));
    try std.testing.expectError(error.InvalidProgram, uncompute(0, &forged));
}
