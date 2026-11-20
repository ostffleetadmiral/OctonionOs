//! lattice_qbit.zig — the 3D lattice-native qbit contract.
//!
//! Q# supplies a conventional microscopic quantum-bit model; this module is
//! the project's distinct 3D cyber-physical qbit: ONE qbit whose state spans
//! the 16^3 domain, with a 15^3 interior basis (3375 cells) and 721 shell
//! sites, carrying the
//! Fano labels e0..e7 per cell (421 e0 observers, 422 of each e1..e7).
//!
//! Evolution is the donor-derived tight-binding Hamiltonian + Chebyshev
//! propagator in quantum/lattice_hamiltonian.zig and
//! quantum/lattice_evolution.zig — integer Q128.128 only, no floats.
//! Measurement remains the seeded deterministic contract of
//! quantum/measure.zig. The lattice qbit's own superposition, measurement,
//! and physical transduction are not yet joined by a dedicated experiment.
//! The framework additionally interprets i itself as superposed until measured.
const std = @import("std");
const fixed = @import("fixed_point.zig");
const lattice = @import("lattice.zig");
const ham = @import("quantum/lattice_hamiltonian.zig");
const evo = @import("quantum/lattice_evolution.zig");
const state = @import("quantum/state.zig");

const Q128 = fixed.Q128;
const Cx = state.Complex;

pub const INNER_SIDE = 15;
pub const SHELL_SIDE = 16;
pub const BASIS = 3375; // 15^3 interior cells = one qbit's basis
pub const DOMAIN = 4096; // 16^3 sites incl. shell
pub const SHELL_SITES = 721; // 16^3 - 15^3
pub const OBSERVERS = 421; // e0-labeled cells

pub const StateDomain = enum {
    full_domain_4096,
};

pub const STATE_DOMAIN: StateDomain = .full_domain_4096;

/// One cyber-physical qbit's current computational realization. Its
/// dynamical state spans the full 16^3 domain: the 15^3 interior plus 721
/// shell sites. Shell participation is controlled by the Hamiltonian
/// couplings; physical transduction and i-vector measurement remain explicit
/// elevation targets.
pub const LatticeQubit = struct {
    h: ham.Hamiltonian,
    lat: lattice.Lattice,
    psi: []Cx,
    out: []Cx,
    scratch: []Cx,

    pub fn init(allocator: std.mem.Allocator, t: Q128, v_shell: Q128, t_shell: Q128) !LatticeQubit {
        const psi = try allocator.alloc(Cx, DOMAIN);
        const out = try allocator.alloc(Cx, DOMAIN);
        const scratch = try allocator.alloc(Cx, 4 * DOMAIN); // propagate needs 4n
        errdefer allocator.free(psi);
        errdefer allocator.free(out);
        errdefer allocator.free(scratch);
        @memset(psi, Cx.zero);
        return .{
            .h = ham.Hamiltonian.init(SHELL_SIDE, SHELL_SIDE, SHELL_SIDE, t, Q128.zero, v_shell, t_shell),
            .lat = lattice.Lattice.init(),
            .psi = psi,
            .out = out,
            .scratch = scratch,
        };
    }

    pub fn deinit(self: *LatticeQubit, allocator: std.mem.Allocator) void {
        allocator.free(self.psi);
        allocator.free(self.out);
        allocator.free(self.scratch);
    }

    /// Prepare a computational-basis state in the 15^3 interior at
    /// Hamiltonian coordinates (0..14). The full state buffer is reset, so
    /// all 721 shell amplitudes become zero.
    pub fn prepareBasis(self: *LatticeQubit, x: usize, y: usize, z: usize) error{OutOfRange}!void {
        if (x >= INNER_SIDE or y >= INNER_SIDE or z >= INNER_SIDE) return error.OutOfRange;
        @memset(self.psi, Cx.zero);
        self.psi[self.h.idx(x, y, z)] = Cx.one;
    }

    /// Prepare a uniform interior state using a caller-supplied amplitude.
    /// The 721 shell amplitudes are zero. This function does not normalize or
    /// validate `amp`; the resulting full-domain norm is 3375*|amp|^2.
    pub fn prepareUniformInterior(self: *LatticeQubit, amp: Q128) void {
        @memset(self.psi, Cx.zero);
        const a = Cx.fromReal(amp);
        for (0..DOMAIN) |i| {
            if (!self.h.isShell(i)) self.psi[i] = a;
        }
    }

    /// One Chebyshev propagation step of duration tau.
    pub fn evolve(self: *LatticeQubit, tau: Q128, order: usize) void {
        evo.propagate(self.h, self.psi, self.out, tau, order, self.scratch);
        const tmp = self.psi;
        self.psi = self.out;
        self.out = tmp;
    }

    pub fn normSq(self: *const LatticeQubit) Q128 {
        return self.h.normSq(self.psi);
    }

    /// Population on the 721 shell sites of the full 4096-site state.
    pub fn shellPopulation(self: *const LatticeQubit) Q128 {
        var acc = Q128.zero;
        for (0..DOMAIN) |i| {
            if (self.h.isShell(i)) acc = acc.add(self.psi[i].normSquared());
        }
        return acc;
    }

    /// Population on e0-labeled interior cells (421 labels, including the
    /// geometric origin at signed coordinate (0,0,0)).
    /// Hamiltonian interior coords 0..14 are the lattice's unsigned
    /// coords directly (lattice coord = unsigned - 7).
    pub fn observerPopulation(self: *const LatticeQubit) Q128 {
        return self.labelPopulation(0);
    }

    /// Population summed over all interior cells carrying Fano label `label`.
    pub fn labelPopulation(self: *const LatticeQubit, label: u3) Q128 {
        var acc = Q128.zero;
        for (0..DOMAIN) |i| {
            if (self.h.isShell(i)) continue;
            const c = self.h.coords(i);
            if (self.lat.labelAtIndex(c.x, c.y, c.z) == label) acc = acc.add(self.psi[i].normSquared());
        }
        return acc;
    }

    /// Index of the largest |amplitude|^2 site (deterministic peak readout).
    pub fn peak(self: *const LatticeQubit) struct { index: usize, prob: Q128 } {
        var best: usize = 0;
        var best_p = Q128.zero;
        for (0..DOMAIN) |i| {
            const p = self.psi[i].normSquared();
            if (p.cmp(best_p) > 0) {
                best = i;
                best_p = p;
            }
        }
        return .{ .index = best, .prob = best_p };
    }
};

test "lattice qbit geometry matches the canon counts" {
    try std.testing.expectEqual(@as(usize, 3375), BASIS);
    try std.testing.expectEqual(@as(usize, 4096), DOMAIN);
    try std.testing.expectEqual(@as(usize, 721), SHELL_SITES);
    try std.testing.expectEqual(@as(usize, 421), OBSERVERS);
    try std.testing.expectEqual(StateDomain.full_domain_4096, STATE_DOMAIN);
    const lat = lattice.Lattice.init();
    try std.testing.expect(lat.validate());
    try std.testing.expectEqual(@as(usize, 421), lat.countLabel(0));
}

test "basis prepare is exact and rejects shell coordinates" {
    const gpa = std.testing.allocator;
    var q = try LatticeQubit.init(gpa, Q128.fromInteger(1), Q128.fromInteger(10), Q128.zero);
    defer q.deinit(gpa);
    try q.prepareBasis(7, 7, 7);
    try std.testing.expectEqual(@as(fixed.Raw, fixed.Scale), q.normSq().raw);
    const p = q.peak();
    try std.testing.expectEqual(q.h.idx(7, 7, 7), p.index);
    try std.testing.expectError(error.OutOfRange, q.prepareBasis(15, 0, 0));
}

test "decoupled shell stays dark under evolution" {
    const gpa = std.testing.allocator;
    // t_shell = 0: shell sites have potential but no coupling.
    var q = try LatticeQubit.init(gpa, Q128.fromInteger(1), Q128.fromInteger(10), Q128.zero);
    defer q.deinit(gpa);
    try q.prepareBasis(7, 7, 7);
    q.evolve(Q128.fromRatio(1, 8) catch unreachable, 8);
    try std.testing.expectEqual(@as(fixed.Raw, 0), q.shellPopulation().raw);
}

test "zero-time evolution is the identity" {
    const gpa = std.testing.allocator;
    var q = try LatticeQubit.init(gpa, Q128.fromInteger(1), Q128.fromInteger(10), Q128.zero);
    defer q.deinit(gpa);
    try q.prepareBasis(3, 4, 5);
    q.evolve(Q128.zero, 4);
    const p = q.peak();
    try std.testing.expectEqual(q.h.idx(3, 4, 5), p.index);
    try std.testing.expectEqual(@as(fixed.Raw, fixed.Scale), p.prob.raw);
}

test "label populations partition the interior norm" {
    const gpa = std.testing.allocator;
    var q = try LatticeQubit.init(gpa, Q128.fromInteger(1), Q128.fromInteger(10), Q128.zero);
    defer q.deinit(gpa);
    // uniform interior: every label gets its share of the norm
    const amp = Q128.fromRatio(1, 58) catch unreachable; // ~1/sqrt(3375)
    q.prepareUniformInterior(amp);
    var total = Q128.zero;
    for (0..8) |l| {
        const pop = q.labelPopulation(@intCast(l));
        total = total.add(pop);
    }
    const n = q.normSq();
    const diff = total.sub(n).abs().raw;
    try std.testing.expect(diff < fixed.Scale / 1000);
    // observer share is nonzero and below the total
    const obs = q.observerPopulation();
    try std.testing.expect(obs.raw > 0 and obs.cmp(n) < 0);
}

test "uniform interior state is embedded in the full 4096-site state" {
    const gpa = std.testing.allocator;
    var q = try LatticeQubit.init(gpa, Q128.fromInteger(1), Q128.fromInteger(10), Q128.zero);
    defer q.deinit(gpa);
    const amp = Q128.fromRatio(1, 58) catch unreachable;
    q.prepareUniformInterior(amp);
    try std.testing.expect(q.normSq().cmp(Q128.zero) > 0);
    try std.testing.expectEqual(@as(fixed.Raw, 0), q.shellPopulation().raw);
    try std.testing.expect(q.normSq().sub(amp.mul(amp).mul(Q128.fromInteger(BASIS))).abs().raw < fixed.Scale / 1000);
}

test "full-domain preparation resets shell amplitudes" {
    const gpa = std.testing.allocator;
    var q = try LatticeQubit.init(gpa, Q128.fromInteger(1), Q128.fromInteger(10), Q128.zero);
    defer q.deinit(gpa);
    q.psi[q.h.idx(15, 7, 7)] = Cx.one;
    try q.prepareBasis(7, 7, 7);
    try std.testing.expectEqual(fixed.Scale, q.normSq().raw);
    try std.testing.expectEqual(@as(fixed.Raw, 0), q.shellPopulation().raw);
}
