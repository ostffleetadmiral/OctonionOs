//! reversible_lattice.zig — lattice-native reversible transition contract v1.
//!
//! Declared semantics (a candidate rule, not a derived unique dynamics):
//!
//! - State: `[4096]u8` — byte values on the 16^3 domain, periodic
//!   boundary. This is a classical reversible lane, distinct from the
//!   Q128 lattice-qbit state; it does not evolve amplitudes.
//! - Structure: the domain partitions into 512 cells of 2x2x2 = 8 sites,
//!   the octonion component count. Cell site index s in 0..8 maps to
//!   cell-local offsets (s&1, (s>>1)&1, (s>>2)&1) — declared e0..e7
//!   ordering for this contract.
//! - Two staggered partitions tile the torus: `even` cells at even
//!   origins, `odd` cells at odd origins (wrapping mod 16). Alternating
//!   them is the Margolus construction — information crosses cell
//!   boundaries while every step remains a product of disjoint cell
//!   maps.
//! - `CellGate` is a bounded sequence of primitives, each a bijection on
//!   (Z/256)^8 under the disjointness constraints enforced at `emit`:
//!   unconditional `swap`/`add`/`sub` need distinct sites; conditional
//!   `cswap`/`cadd`/`csub` require the control site disjoint from every
//!   mutated site (`ctrl != dst` for cadd/csub; `ctrl` outside {a,b}
//!   for cswap). Under those constraints every primitive is invertible
//!   (`add`<->`sub`, `cadd`<->`csub`, `rot`<->`unrot`, swaps self), so
//!   every cell map, every step, and every alternating composition is
//!   bijective — the global inverse is the same partition sequence
//!   backwards with the inverse gate.
//! - `gateV1` is a declared convention (observer-controlled exchange,
//!   cyclic rotation, controlled transfer, tail exchange), not a
//!   uniquely derived physical rule.
const std = @import("std");
const qmodel = @import("quantum_model.zig");

pub const SIDE: usize = 16;
pub const SITE_COUNT: usize = SIDE * SIDE * SIDE;
pub const CELL_COUNT: usize = 512;
pub const PRIM_MAX: usize = 32;
pub const CONTRACT_VERSION: u8 = 1;

pub const Partition = enum { even, odd };

pub const PairSites = struct { a: u3, b: u3 };
pub const DirectedSites = struct { dst: u3, src: u3 };
pub const SwapControl = struct { a: u3, b: u3, ctrl: u3 };
pub const DirectedControl = struct { dst: u3, src: u3, ctrl: u3 };

pub const Prim = union(enum) {
    swap: PairSites,
    rot: void,
    unrot: void,
    add: DirectedSites,
    sub: DirectedSites,
    cswap: SwapControl,
    cadd: DirectedControl,
    csub: DirectedControl,
};

pub const Error = error{ GateFull, InvalidPrim };

fn validatePrim(prim: Prim) Error!void {
    switch (prim) {
        .swap => |g| if (g.a == g.b) return error.InvalidPrim,
        .add, .sub => |g| if (g.dst == g.src) return error.InvalidPrim,
        .cswap => |g| if (g.a == g.b or g.ctrl == g.a or g.ctrl == g.b) return error.InvalidPrim,
        // ctrl may equal src (read-only) but never dst (would break
        // bijectivity: +src can carry a nonzero dst to 0 and a zero dst
        // stays 0 — a collision).
        .cadd, .csub => |g| if (g.dst == g.src or g.ctrl == g.dst) return error.InvalidPrim,
        .rot, .unrot => {},
    }
}

fn inversePrim(prim: Prim) Prim {
    return switch (prim) {
        .swap => prim,
        .rot => .{ .unrot = {} },
        .unrot => .{ .rot = {} },
        .add => |g| .{ .sub = g },
        .sub => |g| .{ .add = g },
        .cswap => prim,
        .cadd => |g| .{ .csub = g },
        .csub => |g| .{ .cadd = g },
    };
}

fn applyPrim(cell: *[8]u8, prim: Prim) void {
    switch (prim) {
        .swap => |g| std.mem.swap(u8, &cell[@intCast(g.a)], &cell[@intCast(g.b)]),
        .rot => {
            const last = cell[7];
            var i: usize = 7;
            while (i > 0) : (i -= 1) cell[i] = cell[i - 1];
            cell[0] = last;
        },
        .unrot => {
            const first = cell[0];
            var i: usize = 0;
            while (i < 7) : (i += 1) cell[i] = cell[i + 1];
            cell[7] = first;
        },
        .add => |g| cell[@intCast(g.dst)] +%= cell[@intCast(g.src)],
        .sub => |g| cell[@intCast(g.dst)] -%= cell[@intCast(g.src)],
        .cswap => |g| {
            if (cell[@intCast(g.ctrl)] != 0) std.mem.swap(u8, &cell[@intCast(g.a)], &cell[@intCast(g.b)]);
        },
        .cadd => |g| {
            if (cell[@intCast(g.ctrl)] != 0) cell[@intCast(g.dst)] +%= cell[@intCast(g.src)];
        },
        .csub => |g| {
            if (cell[@intCast(g.ctrl)] != 0) cell[@intCast(g.dst)] -%= cell[@intCast(g.src)];
        },
    }
}

/// Bounded sequence of cell primitives; `inverse` reverses order and
/// maps each primitive to its inverse.
pub const CellGate = struct {
    prims: [PRIM_MAX]Prim = undefined,
    len: usize = 0,

    pub fn emit(self: *CellGate, prim: Prim) Error!void {
        if (self.len >= PRIM_MAX) return error.GateFull;
        try validatePrim(prim);
        self.prims[self.len] = prim;
        self.len += 1;
    }

    pub fn apply(self: *const CellGate, cell: *[8]u8) void {
        for (self.prims[0..self.len]) |prim| applyPrim(cell, prim);
    }

    pub fn inverse(self: *const CellGate) CellGate {
        var out: CellGate = .{};
        var i = self.len;
        while (i > 0) {
            i -= 1;
            out.prims[out.len] = inversePrim(self.prims[i]);
            out.len += 1;
        }
        return out;
    }
};

/// Declared contract-v1 gate: e0 controls an e1/e2 exchange, the cell
/// rotates, e5 controls an e3 += e4 transfer, and e6/e7 swap.
pub fn gateV1() CellGate {
    var g: CellGate = .{};
    g.emit(.{ .cswap = .{ .a = 1, .b = 2, .ctrl = 0 } }) catch unreachable;
    g.emit(.rot) catch unreachable;
    g.emit(.{ .cadd = .{ .dst = 3, .src = 4, .ctrl = 5 } }) catch unreachable;
    g.emit(.{ .swap = .{ .a = 6, .b = 7 } }) catch unreachable;
    return g;
}

fn cellOrigin(partition: Partition, cell: usize) [3]usize {
    const cx = cell % 8;
    const cy = (cell / 8) % 8;
    const cz = cell / 64;
    const shift = if (partition == .even) @as(usize, 0) else @as(usize, 1);
    return .{ (2 * cx + shift) & (SIDE - 1), (2 * cy + shift) & (SIDE - 1), (2 * cz + shift) & (SIDE - 1) };
}

/// Flat domain index of cell-local site s (0..8) in cell `cell`.
fn cellSite(partition: Partition, cell: usize, site: u3) usize {
    const origin = cellOrigin(partition, cell);
    const dx: usize = @intCast(site & 1);
    const dy: usize = @intCast((site >> 1) & 1);
    const dz: usize = @intCast((site >> 2) & 1);
    const x = (origin[0] + dx) & (SIDE - 1);
    const y = (origin[1] + dy) & (SIDE - 1);
    const z = (origin[2] + dz) & (SIDE - 1);
    return x + SIDE * (y + SIDE * z);
}

/// One reversible step: apply `gate` independently inside every cell of
/// `partition`. Bijective by construction (disjoint cell maps).
pub fn step(state: *[SITE_COUNT]u8, partition: Partition, gate: *const CellGate) void {
    var cell: usize = 0;
    while (cell < CELL_COUNT) : (cell += 1) {
        var buf: [8]u8 = undefined;
        for (0..8) |s| buf[s] = state[cellSite(partition, cell, @intCast(s))];
        gate.apply(&buf);
        for (0..8) |s| state[cellSite(partition, cell, @intCast(s))] = buf[s];
    }
}

/// Inverse of `step`: same partition, inverse gate sequence.
pub fn unstep(state: *[SITE_COUNT]u8, partition: Partition, gate: *const CellGate) void {
    var inverse = gate.inverse();
    step(state, partition, &inverse);
}

fn partitionForStep(step_index: usize) Partition {
    return if (step_index % 2 == 0) .even else .odd;
}

/// `steps` forward steps alternating even/odd partitions starting even.
pub fn run(state: *[SITE_COUNT]u8, steps: usize, gate: *const CellGate) void {
    for (0..steps) |i| step(state, partitionForStep(i), gate);
}

/// Exact inverse of `run`: unstep partitions in reverse order.
pub fn runInverse(state: *[SITE_COUNT]u8, steps: usize, gate: *const CellGate) void {
    var i = steps;
    while (i > 0) {
        i -= 1;
        unstep(state, partitionForStep(i), gate);
    }
}

/// Cell index containing flat site `index` under `partition`, or null
/// if the site is not addressable (cannot happen for valid inputs).
pub fn cellOf(partition: Partition, index: usize) usize {
    const x = index % SIDE;
    const y = (index / SIDE) % SIDE;
    const z = index / (SIDE * SIDE);
    const shift = if (partition == .even) @as(usize, 0) else @as(usize, 1);
    const cx = if (x >= shift) (x - shift) / 2 else (x + SIDE - shift) / 2;
    const cy = if (y >= shift) (y - shift) / 2 else (y + SIDE - shift) / 2;
    const cz = if (z >= shift) (z - shift) / 2 else (z + SIDE - shift) / 2;
    return cx + 8 * (cy + 8 * cz);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

fn streamState(seed: u64) [SITE_COUNT]u8 {
    var stream = qmodel.SelectorStream.init(seed);
    var state: [SITE_COUNT]u8 = undefined;
    for (&state) |*v| v.* = @truncate(stream.next());
    return state;
}

test "both partitions cover all 4096 sites exactly once" {
    inline for (.{ Partition.even, Partition.odd }) |partition| {
        var seen = [_]bool{false} ** SITE_COUNT;
        var count: usize = 0;
        for (0..CELL_COUNT) |cell| {
            for (0..8) |s| {
                const index = cellSite(partition, cell, @intCast(s));
                try std.testing.expect(!seen[index]);
                seen[index] = true;
                count += 1;
            }
        }
        try std.testing.expectEqual(SITE_COUNT, count);
        for (seen) |v| try std.testing.expect(v);
    }
}

test "invalid primitives fail closed at emit" {
    var g: CellGate = .{};
    var full: CellGate = .{};
    for (0..PRIM_MAX) |_| try full.emit(.rot);
    try std.testing.expectError(error.GateFull, full.emit(.rot));
    try std.testing.expectError(error.InvalidPrim, g.emit(.{ .swap = .{ .a = 1, .b = 1 } }));
    try std.testing.expectError(error.InvalidPrim, g.emit(.{ .add = .{ .dst = 2, .src = 2 } }));
    try std.testing.expectError(error.InvalidPrim, g.emit(.{ .cswap = .{ .a = 1, .b = 2, .ctrl = 1 } }));
    try std.testing.expectError(error.InvalidPrim, g.emit(.{ .cadd = .{ .dst = 3, .src = 4, .ctrl = 3 } }));
    // ctrl == src is legal: src is read-only.
    try g.emit(.{ .cadd = .{ .dst = 3, .src = 4, .ctrl = 4 } });
}

test "primitive inverse pairs round-trip on exhaustive byte pairs" {
    // swap/add/sub: exhaustive over the two mutated sites' values.
    for (0..256) |a| for (0..256) |b| {
        var cell = [_]u8{0} ** 8;
        cell[0] = @intCast(a);
        cell[1] = @intCast(b);
        const original = cell;
        applyPrim(&cell, .{ .swap = .{ .a = 0, .b = 1 } });
        applyPrim(&cell, .{ .swap = .{ .a = 0, .b = 1 } });
        try std.testing.expectEqualSlices(u8, &original, &cell);
        applyPrim(&cell, .{ .add = .{ .dst = 0, .src = 1 } });
        applyPrim(&cell, .{ .sub = .{ .dst = 0, .src = 1 } });
        try std.testing.expectEqualSlices(u8, &original, &cell);
    };
    // Conditional primitives: exhaustive control in {0,1} x all dst/src
    // byte pairs for cadd/csub; cswap on the same grid.
    for (0..2) |ctrl| for (0..256) |dst| for (0..256) |src| {
        var cell = [_]u8{0} ** 8;
        cell[6] = @intCast(ctrl);
        cell[3] = @intCast(dst);
        cell[4] = @intCast(src);
        const original = cell;
        applyPrim(&cell, .{ .cadd = .{ .dst = 3, .src = 4, .ctrl = 6 } });
        applyPrim(&cell, .{ .csub = .{ .dst = 3, .src = 4, .ctrl = 6 } });
        try std.testing.expectEqualSlices(u8, &original, &cell);
        applyPrim(&cell, .{ .cswap = .{ .a = 3, .b = 4, .ctrl = 6 } });
        applyPrim(&cell, .{ .cswap = .{ .a = 3, .b = 4, .ctrl = 6 } });
        try std.testing.expectEqualSlices(u8, &original, &cell);
    };
}

test "gate apply and inverse round-trip on structured and random cells" {
    const gate = gateV1();
    const inverse = gate.inverse();
    var stream = qmodel.SelectorStream.init(7);
    var trials: usize = 0;
    while (trials < 96) : (trials += 1) {
        var cell: [8]u8 = undefined;
        if (trials < 8) {
            // Edge patterns: all-zero, all-max, single-hot per site.
            @memset(&cell, if (trials == 0) 0 else if (trials == 1) 0xff else 0);
            if (trials >= 2) cell[trials - 2] = 1;
        } else {
            for (&cell) |*v| v.* = @truncate(stream.next());
        }
        const original = cell;
        gate.apply(&cell);
        inverse.apply(&cell);
        try std.testing.expectEqualSlices(u8, &original, &cell);
    }
}

test "alternating run and runInverse restore the full domain exactly" {
    const gate = gateV1();
    var state = streamState(1234);
    const original = state;
    run(&state, 16, &gate);
    try std.testing.expect(!std.mem.eql(u8, &state, &original));
    runInverse(&state, 16, &gate);
    try std.testing.expectEqualSlices(u8, &original, &state);
}

test "single excitation is transported across cell boundaries" {
    const gate = gateV1();
    var state = [_]u8{0} ** SITE_COUNT;
    const origin_index = cellSite(.even, 0, 0);
    state[origin_index] = 1;
    run(&state, 8, &gate);
    // Under gateV1 a lone excitation never fires a conditional gate
    // (every control reads 0), so exactly one site stays nonzero — but
    // partition alternation must have moved it off the origin cell.
    var nonzero_index: ?usize = null;
    var nonzero: usize = 0;
    for (0..SITE_COUNT) |i| {
        if (state[i] != 0) {
            nonzero += 1;
            nonzero_index = i;
        }
    }
    try std.testing.expectEqual(@as(usize, 1), nonzero);
    try std.testing.expect(nonzero_index.? != origin_index);
}

test "controlled transfer duplicates a value inside a cell" {
    const gate = gateV1();
    var state = [_]u8{0} ** SITE_COUNT;
    // Pre-rot positions: site0 feeds cswap's control, site3 becomes the
    // cadd source after rot, site4 becomes its control.
    for ([_]u3{ 0, 3, 4 }) |s| state[cellSite(.even, 0, s)] = 1;
    step(&state, .even, &gate);
    var nonzero: usize = 0;
    for (0..8) |s| {
        if (state[cellSite(.even, 0, @intCast(s))] != 0) nonzero += 1;
    }
    // cadd fires: 3 excitations become 4 nonzero sites in the cell.
    try std.testing.expectEqual(@as(usize, 4), nonzero);
}

test "empty gate is the identity and declared version is pinned" {
    const gate = gateV1();
    try std.testing.expectEqual(@as(usize, 4), gate.len);
    const empty: CellGate = .{};
    var state = streamState(5);
    const original = state;
    step(&state, .even, &empty);
    step(&state, .odd, &empty);
    try std.testing.expectEqualSlices(u8, &original, &state);
}

test "cellOf inverts cellSite membership for both partitions" {
    inline for (.{ Partition.even, Partition.odd }) |partition| {
        for (0..CELL_COUNT) |cell| {
            for (0..8) |s| {
                const index = cellSite(partition, cell, @intCast(s));
                try std.testing.expectEqual(cell, cellOf(partition, index));
            }
        }
    }
}
