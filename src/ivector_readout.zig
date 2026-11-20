//! ivector_readout.zig — i-vector ↔ lattice-state binding contract v1.
//!
//! Declared semantics (a contract, not a physical claim):
//!
//! The framework's i-vector `i = [e0^i,…,e7^i]` is an 8-component
//! signed-integer object; the lattice state is 4,096 complex amplitudes.
//! This module declares two software bindings between them:
//!
//! 1. **Shot readout** (`runIVectorShots`): each pure site sample is
//!    classified by `describeSite` — interior hits increment the matching
//!    e-label component, shell hits increment `shell_events`. The result
//!    is an integer histogram over the eight components plus an explicit
//!    shell channel. Shell events are NOT forced into the eight
//!    components: under contract v1 the i-vector has exactly eight
//!    components and the shell/foam sector is auxiliary metadata.
//!    Selectors come from the same deterministic `SelectorStream` as
//!    `quantum_model.zig` — reproducibility inputs, not physical
//!    randomness. Sampling is non-mutating; projectile repeated
//!    measurement on a single state is not simulated here (a collapsed
//!    state re-samples its own outcome).
//!
//! 2. **Population quantization** (`populationsToIVector`): the eight
//!    Q128 label populations are converted to i512 integers by
//!    `round_half_up(weight × denom)` where `denom > 0` is a caller-chosen
//!    scale. This is a declared rounding convention, selector-free, and
//!    exact for populations that are integer multiples of `1/denom`.
//!
//! Neither binding claims the i-vector is physically read out of the
//! lattice; they define what the software state *says* about the
//! i-vector under declared conventions. The physical correspondence
//! remains an open evidence question (CYBER-PHYSICS.md).
const std = @import("std");
const fixed = @import("fixed_point.zig");
const ivector = @import("redox_information_vector.zig");
const lm = @import("lattice_measure.zig");
const qmodel = @import("quantum_model.zig");
const qb = @import("lattice_qbit.zig");
const state = @import("quantum/state.zig");

const Q128 = fixed.Q128;
const LatticeQubit = qb.LatticeQubit;

pub const CONTRACT_VERSION: u8 = 1;
pub const Error = lm.Error || error{InvalidDenominator};

/// One classified site sample: an interior e-label hit or a shell hit.
pub const IVectorEvent = union(enum) {
    label: u3,
    shell: void,
};

/// Integer i-vector readout from site-sample shots. `components` holds
/// shot counts per e-label; `shell_events`/`interior_events` partition
/// `shots` across the domain's two sectors.
pub const IVectorReadout = struct {
    components: ivector.Vector = .{},
    shell_events: u64 = 0,
    interior_events: u64 = 0,
    shots: u64 = 0,
    seed: u64 = 0,
    contract: u8 = CONTRACT_VERSION,
};

/// Pure site sample classified as an i-vector event. Does not mutate psi.
pub fn sampleIVectorEvent(q: *const LatticeQubit, selector: u64) Error!IVectorEvent {
    const index = try lm.sampleSite(q, selector);
    const info = try lm.describeSite(q, index);
    if (info.shell) return .{ .shell = {} };
    return .{ .label = info.label.? };
}

/// Deterministic seeded i-vector shot readout over the full domain.
/// Non-mutating: every shot is an independent pure sample of the same
/// pre-measurement state.
pub fn runIVectorShots(q: *const LatticeQubit, shots: u32, seed: u64) Error!IVectorReadout {
    var stream = qmodel.SelectorStream.init(seed);
    var out: IVectorReadout = .{ .shots = shots, .seed = seed };
    var i: u32 = 0;
    while (i < shots) : (i += 1) {
        const event = try sampleIVectorEvent(q, stream.next());
        switch (event) {
            .label => |label| {
                const component: ivector.Component = @enumFromInt(@as(u3, label));
                out.components.set(component, out.components.at(component) +% 1);
                out.interior_events += 1;
            },
            .shell => out.shell_events += 1,
        }
    }
    return out;
}

/// SHA-256 over the readout record: all eight i512 components, the
/// shell/interior/shot counters, seed, and contract version.
pub fn readoutDigest(r: IVectorReadout) [32]u8 {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    for (r.components.values) |v| h.update(std.mem.asBytes(&v));
    h.update(std.mem.asBytes(&r.shell_events));
    h.update(std.mem.asBytes(&r.interior_events));
    h.update(std.mem.asBytes(&r.shots));
    h.update(std.mem.asBytes(&r.seed));
    h.update(&.{r.contract});
    var d: [32]u8 = undefined;
    h.final(&d);
    return d;
}

/// Selector-free binding: quantize the eight Q128 label populations to
/// i512 integers via round-half-up of `weight × denom` (denom > 0).
/// `weight` is a fixed-point population (Q128.128); for a normalized
/// interior state the components sum to approximately `denom`.
pub fn populationsToIVector(w: *const [8]Q128, denom: i512) Error!ivector.Vector {
    if (denom <= 0) return error.InvalidDenominator;
    const half: i512 = @as(i512, 1) << 127;
    var v = ivector.Vector{};
    for (w, 0..) |x, k| {
        // x >= 0 for squared-amplitude populations; num fits i512 for any
        // population representable in Q128 and any denom <= ~2^256.
        const num = @as(i512, x.raw) * denom;
        const scaled = (num + half) >> 128;
        const component: ivector.Component = @enumFromInt(@as(u3, @intCast(k)));
        v.set(component, scaled);
    }
    return v;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

fn testQubit(allocator: std.mem.Allocator) !LatticeQubit {
    return LatticeQubit.init(allocator, Q128.fromInteger(1), Q128.fromInteger(10), Q128.fromInteger(0));
}

fn uniformQubit(allocator: std.mem.Allocator) !LatticeQubit {
    var q = try testQubit(allocator);
    errdefer q.deinit(allocator);
    const amp = Q128.one.div(try Q128.fromInteger(qb.BASIS).sqrt()) catch unreachable;
    q.prepareUniformInterior(amp);
    return q;
}

test "interior basis state reads out as a pure e-label histogram" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa);
    defer q.deinit(gpa);
    try q.prepareBasis(7, 7, 7); // origin is e0
    const r = try runIVectorShots(&q, 256, 42);
    try std.testing.expectEqual(@as(u64, 256), r.shots);
    try std.testing.expectEqual(@as(u64, 0), r.shell_events);
    try std.testing.expectEqual(@as(u64, 256), r.interior_events);
    try std.testing.expectEqual(@as(i512, 256), r.components.at(.e0));
    for ([_]ivector.Component{ .e1, .e2, .e3, .e4, .e5, .e6, .e7 }) |c| {
        try std.testing.expectEqual(@as(i512, 0), r.components.at(c));
    }
    try std.testing.expectEqual(@as(u8, CONTRACT_VERSION), r.contract);
}

test "shell basis state reads out entirely into the shell channel" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa);
    defer q.deinit(gpa);
    q.psi[q.h.idx(15, 7, 7)] = state_complex_one();
    const r = try runIVectorShots(&q, 128, 7);
    try std.testing.expectEqual(@as(u64, 128), r.shell_events);
    try std.testing.expectEqual(@as(u64, 0), r.interior_events);
    for (r.components.values) |v| try std.testing.expectEqual(@as(i512, 0), v);
}

test "shot readout is deterministic, digest-stable, and non-mutating" {
    const gpa = std.testing.allocator;
    var q = try uniformQubit(gpa);
    defer q.deinit(gpa);
    const before = lm.domainDigest(&q);
    const a = try runIVectorShots(&q, 512, 99);
    const b = try runIVectorShots(&q, 512, 99);
    try std.testing.expectEqual(a.components.values, b.components.values);
    try std.testing.expectEqual(a.shell_events, b.shell_events);
    try std.testing.expectEqual(a.interior_events, b.interior_events);
    const da = readoutDigest(a);
    const db = readoutDigest(b);
    try std.testing.expectEqualSlices(u8, &da, &db);
    // A different seed perturbs the histogram on a non-degenerate state.
    const c = try runIVectorShots(&q, 512, 100);
    try std.testing.expect(!std.mem.eql(u8, &readoutDigest(c), &da));
    // Pure sampling left the state untouched.
    try std.testing.expectEqual(before, lm.domainDigest(&q));
    var sum: u64 = 0;
    for (a.components.values) |v| sum += @intCast(v);
    try std.testing.expectEqual(a.shots, sum + a.shell_events);
}

test "populationsToIVector quantizes with round-half-up and rejects bad denom" {
    const gpa = std.testing.allocator;
    var q = try uniformQubit(gpa);
    defer q.deinit(gpa);
    const w = lm.labelWeights(&q);
    const v = try populationsToIVector(&w, 1_000_000);
    // Uniform interior: each class ~ census share of ~1e6 units.
    try std.testing.expect(v.at(.e0) > 120_000 and v.at(.e0) < 130_000);
    for ([_]ivector.Component{ .e1, .e2, .e3, .e4, .e5, .e6, .e7 }) |c| {
        try std.testing.expect(v.at(c) > 120_000 and v.at(c) < 130_000);
    }
    // Exact case: weight exactly 0.5 at denom 4 -> 2 (half-up of 2.0).
    var exact: [8]Q128 = [_]Q128{Q128.zero} ** 8;
    exact[0] = Q128.fromRatio(1, 2) catch unreachable;
    exact[1] = Q128.fromRatio(1, 4) catch unreachable; // 1.0 at denom 4 -> rounds to 1
    const ev = try populationsToIVector(&exact, 4);
    try std.testing.expectEqual(@as(i512, 2), ev.at(.e0));
    try std.testing.expectEqual(@as(i512, 1), ev.at(.e1));
    try std.testing.expectError(error.InvalidDenominator, populationsToIVector(&w, 0));
    try std.testing.expectError(error.InvalidDenominator, populationsToIVector(&w, -3));
}

test "zero state and invalid selectors fail closed without mutation" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa);
    defer q.deinit(gpa);
    const digest0 = lm.domainDigest(&q);
    try std.testing.expectError(error.ZeroNorm, runIVectorShots(&q, 8, 1));
    try std.testing.expectError(error.ZeroNorm, sampleIVectorEvent(&q, 0));
    try q.prepareBasis(2, 3, 4);
    const digest1 = lm.domainDigest(&q);
    try std.testing.expectError(error.InvalidSelector, sampleIVectorEvent(&q, lm.SELECTOR_MAX));
    // `seed` initializes the stream and is not itself a selector: any u64
    // is a valid seed, including maxInt(u64).
    const seeded = try runIVectorShots(&q, 8, lm.SELECTOR_MAX);
    try std.testing.expectEqual(@as(u64, 8), seeded.shots);
    try std.testing.expectEqual(digest1, lm.domainDigest(&q));
    _ = digest0;
}

fn state_complex_one() state.Complex {
    return .{ .re = Q128.one, .im = Q128.zero };
}
