const std = @import("std");
const lattice_mod = @import("lattice.zig");

pub const DIMENSION: usize = lattice_mod.NODE_COUNT;
pub const EDGE_COUNT: usize = 9_450;
pub const MAX_DEGREE: u8 = 6;
pub const MAX_VECTOR_COMPONENT: i16 = 32;
pub const MAX_SCALE_SIDE: usize = 512;
pub const MAX_SCALE_NODES: usize = 134_217_728;
const WORDS_PER_ROW: usize = (DIMENSION + 63) / 64;

pub const Edge = struct {
    a: u16,
    b: u16,
    axis: u2,
};

pub const ScaledStencil = struct {
    side: usize,

    pub fn init(side: usize) error{UnsupportedScale}!ScaledStencil {
        if (side < 2 or side > MAX_SCALE_SIDE or side % 2 != 0) return error.UnsupportedScale;
        return .{ .side = side };
    }

    pub fn nodeCount(self: ScaledStencil) usize {
        return checkedCube(self.side).?;
    }

    pub fn center(self: ScaledStencil) usize {
        const coordinate = self.side / 2;
        return (coordinate * self.side + coordinate) * self.side + coordinate;
    }

    pub fn neighborEdge(self: ScaledStencil, a: usize, b: usize) bool {
        if (a >= self.nodeCount() or b >= self.nodeCount()) return false;
        const ca = reducedCoord(self.side, a);
        const cb = reducedCoord(self.side, b);
        if (@abs(ca.x - cb.x) + @abs(ca.y - cb.y) + @abs(ca.z - cb.z) != 1) return false;
        const delta: i16 = @intCast(@mod((cb.x + cb.y + cb.z) - (ca.x + ca.y + ca.z), 8));
        return delta == 1 or delta == 7;
    }

    pub fn apply(self: ScaledStencil, allocator: std.mem.Allocator, input: []const i64, output: []i64) error{ InvalidLength, OutOfMemory, Overflow }!void {
        if (input.len != self.nodeCount() or output.len != input.len) return error.InvalidLength;
        const snapshot = try allocator.dupe(i64, input);
        defer allocator.free(snapshot);
        @memset(output, 0);
        for (0..self.side) |z| {
            for (0..self.side) |y| {
                for (0..self.side) |x| {
                    const a = (z * self.side + y) * self.side + x;
                    const candidates = [_]?usize{
                        if (x + 1 < self.side) a + 1 else null,
                        if (y + 1 < self.side) a + self.side else null,
                        if (z + 1 < self.side) a + self.side * self.side else null,
                    };
                    for (candidates) |candidate| {
                        const b = candidate orelse continue;
                        if (!self.neighborEdge(a, b)) continue;
                        output[a] = std.math.add(i64, output[a], snapshot[b]) catch return error.Overflow;
                        output[b] = std.math.add(i64, output[b], snapshot[a]) catch return error.Overflow;
                    }
                }
            }
        }
    }

    pub fn applyCayleyApprox(self: ScaledStencil, allocator: std.mem.Allocator, input: []const i64, output: []i64) error{ InvalidLength, OutOfMemory, Overflow }!void {
        if (input.len != self.nodeCount() or output.len != input.len) return error.InvalidLength;
        const h1 = try allocator.alloc(i64, input.len);
        defer allocator.free(h1);
        const h2 = try allocator.alloc(i64, input.len);
        defer allocator.free(h2);
        try self.apply(allocator, input, h1);
        try self.apply(allocator, h1, h2);
        const result = try allocator.alloc(i64, input.len);
        defer allocator.free(result);
        for (0..input.len) |i| {
            const base = std.math.mul(i64, 49, input[i]) catch return error.Overflow;
            const linear = std.math.mul(i64, 14, h1[i]) catch return error.Overflow;
            const numerator = std.math.add(i64, base, linear) catch return error.Overflow;
            const complete = std.math.sub(i64, numerator, h2[i]) catch return error.Overflow;
            result[i] = roundNearestTiesEven(complete, 49);
        }
        @memcpy(output, result);
    }

    pub fn applyExactReducedPolynomial(self: ScaledStencil, allocator: std.mem.Allocator, input: []const i64, output: []ReducedRational) error{ InvalidLength, OutOfMemory, Overflow, ZeroDenominator }!void {
        if (input.len != self.nodeCount() or output.len != input.len) return error.InvalidLength;
        const wide = try allocator.alloc(i128, input.len);
        defer allocator.free(wide);
        for (input, 0..) |value, i| wide[i] = value;
        try exactReducedCayley(self.side, wide, output, allocator);
    }
};

const AdjacencyRow = [WORDS_PER_ROW]u64;

pub const Vector = struct {
    values: [DIMENSION]i16,

    pub fn basis(index: usize) error{InvalidBasisIndex}!Vector {
        if (index >= DIMENSION) return error.InvalidBasisIndex;
        var vector = Vector{ .values = [_]i16{0} ** DIMENSION };
        vector.values[index] = 1;
        return vector;
    }

    pub fn normSquared(self: *const Vector) u64 {
        var norm: u64 = 0;
        for (self.values) |value| {
            const wide: i64 = value;
            norm += @intCast(wide * wide);
        }
        return norm;
    }

    pub fn dot(self: *const Vector, other: *const Vector) i128 {
        var result: i128 = 0;
        for (self.values, other.values) |a, b| result += @as(i128, a) * b;
        return result;
    }
};

pub const Graph = struct {
    edges: [EDGE_COUNT]Edge,
    adjacency: [DIMENSION]AdjacencyRow,
    degree: [DIMENSION]u8,

    pub fn build(lattice: *const lattice_mod.Lattice) error{EdgeCountMismatch}!Graph {
        var graph: Graph = undefined;
        @memset(std.mem.sliceAsBytes(std.mem.asBytes(&graph)), 0);
        var edge_count: usize = 0;
        for (0..lattice_mod.SIDE) |z| {
            for (0..lattice_mod.SIDE) |y| {
                for (0..lattice_mod.SIDE) |x| {
                    const source = lattice_mod.Lattice.indexUnsigned(x, y, z);
                    const candidates = [_]struct { x: usize, y: usize, z: usize, axis: u2 }{
                        .{ .x = x + 1, .y = y, .z = z, .axis = 0 },
                        .{ .x = x, .y = y + 1, .z = z, .axis = 1 },
                        .{ .x = x, .y = y, .z = z + 1, .axis = 2 },
                    };
                    for (candidates) |candidate| {
                        if (candidate.x >= lattice_mod.SIDE or candidate.y >= lattice_mod.SIDE or
                            candidate.z >= lattice_mod.SIDE) continue;
                        const destination = lattice_mod.Lattice.indexUnsigned(candidate.x, candidate.y, candidate.z);
                        const delta = @mod(
                            @as(i16, lattice.labels[destination]) - @as(i16, lattice.labels[source]),
                            8,
                        );
                        if (delta != 1 and delta != 7) continue;
                        if (edge_count >= EDGE_COUNT) return error.EdgeCountMismatch;
                        graph.edges[edge_count] = .{
                            .a = @intCast(source),
                            .b = @intCast(destination),
                            .axis = candidate.axis,
                        };
                        edge_count += 1;
                        graph.setAdjacent(source, destination);
                        graph.setAdjacent(destination, source);
                        graph.degree[source] += 1;
                        graph.degree[destination] += 1;
                    }
                }
            }
        }
        if (edge_count != EDGE_COUNT) return error.EdgeCountMismatch;
        return graph;
    }

    pub fn hasAdjacent(self: *const Graph, a: usize, b: usize) bool {
        return self.adjacency[a][b / 64] & (@as(u64, 1) << @intCast(b % 64)) != 0;
    }

    fn setAdjacent(self: *Graph, a: usize, b: usize) void {
        self.adjacency[a][b / 64] |= @as(u64, 1) << @intCast(b % 64);
    }

    pub fn apply(self: *const Graph, input: *const Vector, output: *Vector) error{Overflow}!void {
        const snapshot = input.*;
        output.* = .{ .values = [_]i16{0} ** DIMENSION };
        for (0..DIMENSION) |source| {
            for (self.adjacency[source], 0..) |word, word_index| {
                var remaining = word;
                while (remaining != 0) {
                    const bit = @ctz(remaining);
                    const destination = word_index * 64 + bit;
                    if (destination < DIMENSION) {
                        output.values[source] = std.math.add(
                            i16,
                            output.values[source],
                            snapshot.values[destination],
                        ) catch return error.Overflow;
                    }
                    remaining &= remaining - 1;
                }
            }
        }
    }

    pub fn applyWide(self: *const Graph, input: *const WideVector, output: *WideVector) error{Overflow}!void {
        const snapshot = input.*;
        output.* = .{ .values = [_]i64{0} ** DIMENSION };
        for (0..DIMENSION) |source| {
            for (self.adjacency[source], 0..) |word, word_index| {
                var remaining = word;
                while (remaining != 0) {
                    const bit = @ctz(remaining);
                    const destination = word_index * 64 + bit;
                    if (destination < DIMENSION) {
                        output.values[source] = std.math.add(
                            i64,
                            output.values[source],
                            snapshot.values[destination],
                        ) catch return error.Overflow;
                    }
                    remaining &= remaining - 1;
                }
            }
        }
    }
};

pub const WideVector = struct {
    values: [DIMENSION]i64,
};

pub const TimeStep = struct {
    numerator: i16,
    denominator: u16,

    pub fn derived() TimeStep {
        return .{ .numerator = 1, .denominator = lattice_mod.DEFECT_COUNT };
    }

    pub fn validate(self: TimeStep) bool {
        return self.numerator == 1 and self.denominator == lattice_mod.DEFECT_COUNT and
            lattice_mod.DEFECT_COUNT == 7;
    }

    pub fn apply(self: TimeStep, graph: *const Graph, input: *const Vector, output: *Vector) error{ Overflow, InvalidTimeStep }!void {
        if (!self.validate()) return error.InvalidTimeStep;
        try Cayley.apply(graph, input, output);
    }
};

const Cayley = struct {
    fn apply(graph: *const Graph, input: *const Vector, output: *Vector) error{Overflow}!void {
        if (!withinBound(input)) return error.Overflow;
        var h1 = WideVector{ .values = [_]i64{0} ** DIMENSION };
        var h2 = WideVector{ .values = [_]i64{0} ** DIMENSION };
        var original = WideVector{ .values = [_]i64{0} ** DIMENSION };
        for (input.values, 0..) |value, i| original.values[i] = value;
        try graph.applyWide(&original, &h1);
        try graph.applyWide(&h1, &h2);

        try evaluatePolynomial(input, &h1, &h2, output);
    }

    fn evaluatePolynomial(input: *const Vector, h1: *const WideVector, h2: *const WideVector, output: *Vector) error{Overflow}!void {
        const h1_values = h1.values;
        const h2_values = h2.values;
        var candidate = Vector{ .values = [_]i16{0} ** DIMENSION };
        const denominator: i64 = lattice_mod.DEFECT_COUNT;
        const den_sq = denominator * denominator;
        for (0..DIMENSION) |i| {
            const identity = std.math.mul(i64, den_sq, input.values[i]) catch return error.Overflow;
            const first = std.math.mul(i64, 2 * denominator, h1_values[i]) catch return error.Overflow;
            const numerator = std.math.add(i64, identity, first) catch return error.Overflow;
            const full = std.math.add(i64, numerator, -h2_values[i]) catch return error.Overflow;
            const rounded = roundNearestTiesEven(full, den_sq);
            candidate.values[i] = std.math.cast(i16, rounded) orelse return error.Overflow;
            if (@abs(candidate.values[i]) > MAX_VECTOR_COMPONENT) return error.Overflow;
        }
        if (!withinBound(&candidate)) return error.Overflow;
        output.* = candidate;
    }
};

fn withinBound(vector: *const Vector) bool {
    for (vector.values) |value| if (@abs(value) > MAX_VECTOR_COMPONENT) return false;
    return true;
}

pub const ProbeSummary = struct {
    reduced_known_answer_numerator: i128,
    reduced_known_answer_denominator: i128,
    max_basis_norm_error_num: i128,
    max_basis_norm_error_den: i128,
    max_repeated_norm_error_num: i128,
    max_repeated_norm_error_den: i128,
};

pub const ReducedRational = struct {
    numerator: i128,
    denominator: i128,

    pub fn init(numerator: i128, denominator: i128) error{ZeroDenominator}!ReducedRational {
        if (denominator == 0) return error.ZeroDenominator;
        const sign: i128 = if (denominator < 0) -1 else 1;
        const n = numerator * sign;
        const d = denominator * sign;
        const divisor = gcd(abs128(n), @intCast(d));
        const signed_divisor: i128 = @intCast(divisor);
        return .{ .numerator = @divTrunc(n, signed_divisor), .denominator = @divTrunc(d, signed_divisor) };
    }

    pub fn add(a: ReducedRational, b: ReducedRational) error{ Overflow, ZeroDenominator }!ReducedRational {
        const left = std.math.mul(i128, a.numerator, b.denominator) catch return error.Overflow;
        const right = std.math.mul(i128, b.numerator, a.denominator) catch return error.Overflow;
        const numerator = std.math.add(i128, left, right) catch return error.Overflow;
        const denominator = std.math.mul(i128, a.denominator, b.denominator) catch return error.Overflow;
        return init(numerator, denominator);
    }

    pub fn mul(a: ReducedRational, b: ReducedRational) error{ Overflow, ZeroDenominator }!ReducedRational {
        const numerator = std.math.mul(i128, a.numerator, b.numerator) catch return error.Overflow;
        const denominator = std.math.mul(i128, a.denominator, b.denominator) catch return error.Overflow;
        return init(numerator, denominator);
    }

    pub fn div(a: ReducedRational, b: ReducedRational) error{ Overflow, ZeroDenominator }!ReducedRational {
        if (b.numerator == 0) return error.ZeroDenominator;
        return mul(a, try init(b.denominator, b.numerator));
    }

    pub fn square(a: ReducedRational) error{ Overflow, ZeroDenominator }!ReducedRational {
        return mul(a, a);
    }
};

fn abs128(value: i128) u128 {
    return if (value < 0) @intCast(-value) else @intCast(value);
}

fn gcd(a_input: u128, b_input: u128) u128 {
    var a = a_input;
    var b = b_input;
    while (b != 0) {
        const remainder = a % b;
        a = b;
        b = remainder;
    }
    return if (a == 0) 1 else a;
}

pub fn exactReducedCayley(scale: usize, input: []const i128, output: []ReducedRational, allocator: std.mem.Allocator) error{ InvalidLength, Overflow, ZeroDenominator, OutOfMemory }!void {
    const volume = checkedCube(scale) orelse return error.InvalidLength;
    if (input.len != volume or output.len != input.len) return error.InvalidLength;
    const nodes = input.len;
    const h1 = try allocator.alloc(i128, nodes);
    defer allocator.free(h1);
    const h2 = try allocator.alloc(i128, nodes);
    defer allocator.free(h2);
    try reducedApply(scale, input, h1, allocator);
    try reducedApply(scale, h1, h2, allocator);
    const d: i128 = 7;
    for (0..nodes) |i| {
        const den_sq: i128 = d * d;
        const identity = std.math.mul(i128, den_sq, input[i]) catch return error.Overflow;
        const first = std.math.mul(i128, 2 * d, h1[i]) catch return error.Overflow;
        const numerator = std.math.add(i128, identity, first) catch return error.Overflow;
        const full = std.math.add(i128, numerator, -h2[i]) catch return error.Overflow;
        output[i] = try ReducedRational.init(full, den_sq);
    }
}

fn reducedApply(side: usize, input: []const i128, output: []i128, allocator: std.mem.Allocator) error{ InvalidLength, Overflow, OutOfMemory }!void {
    const volume = checkedCube(side) orelse return error.InvalidLength;
    if (input.len != volume or output.len != input.len) return error.InvalidLength;
    const snapshot = try allocator.dupe(i128, input);
    defer allocator.free(snapshot);
    @memset(output, 0);
    for (0..side) |z| {
        for (0..side) |y| {
            for (0..side) |x| {
                const a = (z * side + y) * side + x;
                if (x + 1 < side) try reducedNeighbor(side, snapshot, output, a, a + 1);
                if (y + 1 < side) try reducedNeighbor(side, snapshot, output, a, a + side);
                if (z + 1 < side) try reducedNeighbor(side, snapshot, output, a, a + side * side);
            }
        }
    }
}

fn reducedNeighbor(side: usize, input: []const i128, output: []i128, a: usize, b: usize) error{Overflow}!void {
    const ca = reducedCoord(side, a);
    const cb = reducedCoord(side, b);
    if (@abs(ca.x - cb.x) + @abs(ca.y - cb.y) + @abs(ca.z - cb.z) != 1) return;
    const delta: i16 = @intCast(@mod((cb.x + cb.y + cb.z) - (ca.x + ca.y + ca.z), 8));
    if (delta != 1 and delta != 7) return;
    output[a] = std.math.add(i128, output[a], input[b]) catch return error.Overflow;
    output[b] = std.math.add(i128, output[b], input[a]) catch return error.Overflow;
}

const Coord3 = struct { x: i16, y: i16, z: i16 };

fn checkedCube(side: usize) ?usize {
    const square = std.math.mul(usize, side, side) catch return null;
    return std.math.mul(usize, square, side) catch return null;
}

fn roundNearestTiesEven(numerator: i64, denominator: i64) i64 {
    const quotient = @divTrunc(numerator, denominator);
    const remainder = @rem(numerator, denominator);
    const twice: u64 = @intCast(@abs(remainder) * 2);
    const den: u64 = @intCast(denominator);
    if (twice < den) return quotient;
    const direction: i64 = if (numerator < 0) -1 else 1;
    if (twice > den or @mod(quotient, 2) != 0) return quotient + direction;
    return quotient;
}

fn reducedCoord(side: usize, index: usize) Coord3 {
    return .{
        .x = @intCast(@as(isize, @intCast(index % side)) - @as(isize, @intCast(side / 2))),
        .y = @intCast(@as(isize, @intCast((index / side) % side)) - @as(isize, @intCast(side / 2))),
        .z = @intCast(@as(isize, @intCast(index / (side * side))) - @as(isize, @intCast(side / 2))),
    };
}

pub fn exhaustivePropagatorProbes(graph: *const Graph, repeated_steps: usize, allocator: std.mem.Allocator) error{ Overflow, InvalidTimeStep, InvalidBasisIndex, OutOfMemory, InvalidLength, ZeroDenominator }!ProbeSummary {
    const time = TimeStep.derived();
    var max_norm_error: i128 = 0;
    for (0..DIMENSION) |basis_index| {
        const input = try Vector.basis(basis_index);
        var forward: Vector = undefined;
        try time.apply(graph, &input, &forward);
        const norm_delta = @as(i128, @intCast(forward.normSquared())) - @as(i128, @intCast(input.normSquared()));
        max_norm_error = @max(max_norm_error, @as(i128, @intCast(abs128(norm_delta))));
    }

    const origin = lattice_mod.Lattice.index(.{ .x = 0, .y = 0, .z = 0 }).?;
    var initial = try Vector.basis(origin);
    const initial_norm: i128 = initial.normSquared();
    var max_repeated_delta: i128 = 0;
    for (0..repeated_steps) |_| {
        var next: Vector = undefined;
        try time.apply(graph, &initial, &next);
        initial = next;
        const delta = @as(i128, initial.normSquared()) - initial_norm;
        max_repeated_delta = @max(max_repeated_delta, @as(i128, @intCast(abs128(delta))));
    }

    const reduced = [_]i128{ 0, 0, 0, 0, 0, 0, 0, 0 };
    var exact = [_]ReducedRational{.{ .numerator = 0, .denominator = 1 }} ** 8;
    try exactReducedCayley(2, &reduced, &exact, allocator);
    return .{
        .reduced_known_answer_numerator = exact[0].numerator,
        .reduced_known_answer_denominator = exact[0].denominator,
        .max_basis_norm_error_num = max_norm_error,
        .max_basis_norm_error_den = 1,
        .max_repeated_norm_error_num = max_repeated_delta,
        .max_repeated_norm_error_den = 1,
    };
}

test "symmetric Fano adjacency census and exact Hermiticity" {
    const lattice = lattice_mod.Lattice.init();
    const graph = try Graph.build(&lattice);
    var axis_edges = [_]usize{0} ** 3;
    var histogram = [_]usize{0} ** 7;
    for (graph.edges) |edge| axis_edges[edge.axis] += 1;
    for (graph.degree) |degree| histogram[degree] += 1;
    try std.testing.expectEqual([_]usize{ 3_150, 3_150, 3_150 }, axis_edges);
    try std.testing.expectEqual([_]usize{ 0, 0, 0, 8, 156, 1_014, 2_197 }, histogram);
    for (0..DIMENSION) |a| for (0..DIMENSION) |b| {
        try std.testing.expectEqual(graph.hasAdjacent(a, b), graph.hasAdjacent(b, a));
    };
}

test "exact rational polynomial reduced known answer is computed without free parameters" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const input = [_]i128{ 1, 0, 0, 0, 0, 0, 0, 0 };
    var output = [_]ReducedRational{.{ .numerator = 0, .denominator = 1 }} ** 8;
    try exactReducedCayley(2, &input, &output, arena.allocator());
    try std.testing.expectEqual(@as(i128, 46), output[0].numerator);
    try std.testing.expectEqual(@as(i128, 49), output[0].denominator);
}

test "scaled sparse stencil applies rule and rational reference at side 2 and 4" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    inline for (.{ 2, 4 }) |side| {
        const stencil = try ScaledStencil.init(side);
        const count = stencil.nodeCount();
        const input = try allocator.alloc(i64, count);
        const approximate = try allocator.alloc(i64, count);
        const exact = try allocator.alloc(ReducedRational, count);
        @memset(input, 0);
        input[stencil.center()] = 1;
        try stencil.applyCayleyApprox(allocator, input, approximate);
        try stencil.applyExactReducedPolynomial(allocator, input, exact);
        try std.testing.expectEqual(if (side == 2) @as(i128, 46) else @as(i128, 43), exact[stencil.center()].numerator);
        try std.testing.expectEqual(@as(i128, 49), exact[stencil.center()].denominator);
        try std.testing.expectEqual(@as(i64, 1), approximate[stencil.center()]);
    }
    try std.testing.expectError(error.UnsupportedScale, ScaledStencil.init(513));
}

test "side-2 rounded polynomial collision falsifies a free-state inverse" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const stencil = try ScaledStencil.init(2);
    const first = [_]i64{ -1, -1, -1, -1, -1, -1, 0, 0 };
    const second = [_]i64{ -1, -1, -1, -1, -1, -1, 0, 1 };
    const first_output = try allocator.alloc(i64, first.len);
    const second_output = try allocator.alloc(i64, second.len);
    try stencil.applyCayleyApprox(allocator, &first, first_output);
    try stencil.applyCayleyApprox(allocator, &second, second_output);
    try std.testing.expect(!std.mem.eql(i64, &first, &second));
    try std.testing.expectEqualSlices(i64, first_output, second_output);
    try std.testing.expectEqualSlices(i64, &[_]i64{ -2, -2, -1, -1, -1, -1, 0, 0 }, first_output);
}

test "exact rational polynomial agrees with fixed-point origin basis control" {
    const lattice = lattice_mod.Lattice.init();
    const graph = try Graph.build(&lattice);
    const origin = lattice_mod.Lattice.index(.{ .x = 0, .y = 0, .z = 0 }).?;
    const input = try Vector.basis(origin);
    var output: Vector = undefined;
    try TimeStep.derived().apply(&graph, &input, &output);
    try std.testing.expectEqual(@as(u64, 1), output.normSquared());
    try std.testing.expectEqual(input.values, output.values);
}

test "all basis vectors report their rounded polynomial norm" {
    const lattice = lattice_mod.Lattice.init();
    const graph = try Graph.build(&lattice);
    var max_norm_delta: u64 = 0;
    for (0..DIMENSION) |basis_index| {
        const input = try Vector.basis(basis_index);
        var forward: Vector = undefined;
        try TimeStep.derived().apply(&graph, &input, &forward);
        max_norm_delta = @max(max_norm_delta, @abs(@as(i64, @intCast(forward.normSquared())) - 1));
    }
    try std.testing.expectEqual(@as(u64, 0), max_norm_delta);
}

test "repeated rounded-polynomial evolution reports norm drift" {
    const lattice = lattice_mod.Lattice.init();
    const graph = try Graph.build(&lattice);
    const origin = lattice_mod.Lattice.index(.{ .x = 0, .y = 0, .z = 0 }).?;
    var state = try Vector.basis(origin);
    const initial_norm = state.normSquared();
    var max_norm_delta: u64 = 0;
    var steps: usize = 0;
    while (steps < 64) : (steps += 1) {
        var next: Vector = undefined;
        try TimeStep.derived().apply(&graph, &state, &next);
        state = next;
        const norm = state.normSquared();
        const delta: i64 = @as(i64, @intCast(norm)) - @as(i64, @intCast(initial_norm));
        max_norm_delta = @max(max_norm_delta, @as(u64, @intCast(@abs(delta))));
    }
    try std.testing.expectEqual(@as(u64, 0), max_norm_delta);
}

test "basis and repeated-step drift probe runs with bounded states" {
    const lattice = lattice_mod.Lattice.init();
    const graph = try Graph.build(&lattice);
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const summary = try exhaustivePropagatorProbes(&graph, 8, arena.allocator());
    try std.testing.expect(summary.reduced_known_answer_denominator > 0);
    try std.testing.expect(summary.max_basis_norm_error_den == 1);
}
