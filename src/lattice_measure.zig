//! lattice_measure.zig — measurement/readout contract v1 for the lattice qbit.
//!
//! Declared semantics (this is a contract, not a physical claim):
//!
//! - The state is `psi[0..4096)` over the 16^3 domain; `siteWeight(i) =
//!   |psi(i)|^2`. The site observable resolves all 4,096 sites — interior
//!   and shell.
//! - The e-label observable resolves the eight Fano label classes on the
//!   15^3 interior only. Shell sites carry no e-label and belong to no
//!   label eigenspace; label sampling is therefore conditional on the
//!   interior subspace.
//! - `sampleSite` / `sampleLabel` are pure (non-mutating) Born draws driven
//!   by caller-supplied u64 selectors — deterministic, no entropy source.
//!   `SELECTOR_MAX` (maxInt(u64)) is rejected, matching the half-open
//!   selector contract of quantum_model.zig.
//! - `measureSite` collapses psi to the sampled basis site.
//! - `measureLabel` performs the Lüders projection onto the sampled label's
//!   interior subspace and renormalizes to unit norm; shell amplitude is
//!   projected out. A repeated label draw on the collapsed state returns
//!   the same label (absorbing outcome).
//! - All readouts (weights, populations, digest, describeSite) are
//!   non-mutating; `domainDigest` binds the full state for before/after
//!   disturbance checks.
//!
//! Physical elevation is separate: this contract defines software
//! measurement semantics only. Mapping it to apparatus observables requires
//! the measurement contract gate in CYBER-PHYSICS.md.
const std = @import("std");
const fixed = @import("fixed_point.zig");
const qb = @import("lattice_qbit.zig");
const qmodel = @import("quantum_model.zig");
const state = @import("quantum/state.zig");

const Q128 = fixed.Q128;
const Cx = state.Complex;
const LatticeQubit = qb.LatticeQubit;

pub const SELECTOR_MAX: u64 = std.math.maxInt(u64);
const SELECTOR_DEN: fixed.Raw = @as(fixed.Raw, 1) << 64;

pub const Error = error{
    InvalidSelector,
    ZeroNorm,
    NoOutcome,
    OutOfRange,
    DivisionByZero,
    Overflow,
};

pub const SiteInfo = struct {
    index: usize,
    x: usize,
    y: usize,
    z: usize,
    shell: bool,
    label: ?u3,
    weight: Q128,
};

pub const LabelShotCounts = struct {
    counts: [8]u32 = [_]u32{0} ** 8,
    shots: u32 = 0,
};

fn siteWeight(q: *const LatticeQubit, index: usize) Q128 {
    return q.psi[index].normSquared();
}

/// |psi(i)|^2 for a domain site.
pub fn siteProbability(q: *const LatticeQubit, index: usize) Error!Q128 {
    if (index >= qb.DOMAIN) return error.OutOfRange;
    return siteWeight(q, index);
}

/// Squared-amplitude population per e-label class over the interior.
/// The eight weights sum to the interior norm (shell excluded).
/// Single pass over psi: coords and label are computed once per site.
pub fn labelWeights(q: *const LatticeQubit) [8]Q128 {
    var w: [8]Q128 = [_]Q128{Q128.zero} ** 8;
    for (0..qb.DOMAIN) |i| {
        if (q.h.isShell(i)) continue;
        const c = q.h.coords(i);
        const label = q.lat.labelAtIndex(c.x, c.y, c.z);
        w[label] = w[label].add(siteWeight(q, i));
    }
    return w;
}

/// SHA-256 over every amplitude's re/im raw limbs, in domain order.
pub fn domainDigest(q: *const LatticeQubit) [32]u8 {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    for (q.psi) |a| {
        h.update(std.mem.asBytes(&a.re.raw));
        h.update(std.mem.asBytes(&a.im.raw));
    }
    var d: [32]u8 = undefined;
    h.final(&d);
    return d;
}

/// Coordinates, shell flag, e-label (null on shell), and weight for a site.
pub fn describeSite(q: *const LatticeQubit, index: usize) Error!SiteInfo {
    if (index >= qb.DOMAIN) return error.OutOfRange;
    const c = q.h.coords(index);
    const shell = q.h.isShell(index);
    var label: ?u3 = null;
    if (!shell) label = q.lat.labelAtIndex(c.x, c.y, c.z);
    return .{
        .index = index,
        .x = c.x,
        .y = c.y,
        .z = c.z,
        .shell = shell,
        .label = label,
        .weight = siteWeight(q, index),
    };
}

fn threshold(selector: u64, total: Q128) Error!Q128 {
    if (selector == SELECTOR_MAX) return error.InvalidSelector;
    const r = try Q128.fromRatio(@as(fixed.Raw, selector), SELECTOR_DEN);
    return r.mul(total);
}

/// Pure Born draw over all 4,096 domain sites. Does not mutate psi.
pub fn sampleSite(q: *const LatticeQubit, selector: u64) Error!usize {
    const total = q.normSq();
    if (total.cmp(Q128.zero) <= 0) return error.ZeroNorm;
    const t = try threshold(selector, total);
    var cumulative = Q128.zero;
    for (0..qb.DOMAIN) |i| {
        cumulative = cumulative.add(siteWeight(q, i));
        if (t.cmp(cumulative) < 0) return i;
    }
    return error.NoOutcome;
}

/// Pure Born draw over the eight interior e-label classes, weighted by
/// label population. Does not mutate psi. Shell amplitude is outside the
/// label observable and does not enter the distribution.
pub fn sampleLabel(q: *const LatticeQubit, selector: u64) Error!u3 {
    const w = labelWeights(q);
    var total = Q128.zero;
    for (w) |x| total = total.add(x);
    if (total.cmp(Q128.zero) <= 0) return error.ZeroNorm;
    const t = try threshold(selector, total);
    var cumulative = Q128.zero;
    for (w, 0..) |x, l| {
        cumulative = cumulative.add(x);
        if (t.cmp(cumulative) < 0) return @intCast(l);
    }
    return error.NoOutcome;
}

/// Born draw plus collapse to the sampled basis site.
pub fn measureSite(q: *LatticeQubit, selector: u64) Error!usize {
    const index = try sampleSite(q, selector);
    try collapseToSite(q, index);
    return index;
}

/// Collapse psi to a single domain basis site (interior or shell).
pub fn collapseToSite(q: *LatticeQubit, index: usize) Error!void {
    if (index >= qb.DOMAIN) return error.OutOfRange;
    @memset(q.psi, Cx.zero);
    q.psi[index] = Cx.one;
}

/// Born draw over label classes plus Lüders projection onto the sampled
/// label's interior subspace, renormalized to unit norm.
pub fn measureLabel(q: *LatticeQubit, selector: u64) Error!u3 {
    const label = try sampleLabel(q, selector);
    try collapseToLabel(q, label);
    return label;
}

/// Lüders projection onto one e-label class: keep only interior sites
/// carrying `label`, zero everything else (including all shell sites,
/// which belong to no label eigenspace), then renormalize to unit norm.
/// Two-pass: a class with no population fails before psi is touched.
pub fn collapseToLabel(q: *LatticeQubit, label: u3) Error!void {
    var kept = Q128.zero;
    for (0..qb.DOMAIN) |i| {
        if (q.h.isShell(i)) continue;
        const c = q.h.coords(i);
        if (q.lat.labelAtIndex(c.x, c.y, c.z) == label) kept = kept.add(siteWeight(q, i));
    }
    if (kept.cmp(Q128.zero) <= 0) return error.ZeroNorm;
    const norm = try kept.sqrt();
    const inv = try Q128.one.div(norm);
    for (0..qb.DOMAIN) |i| {
        if (q.h.isShell(i)) {
            q.psi[i] = Cx.zero;
            continue;
        }
        const c = q.h.coords(i);
        if (q.lat.labelAtIndex(c.x, c.y, c.z) == label) {
            q.psi[i] = q.psi[i].scale(inv);
        } else {
            q.psi[i] = Cx.zero;
        }
    }
}

/// Deterministic seeded label-shot histogram over the interior classes.
/// Selectors come from the same SplitMix64-style stream as quantum_model.
pub fn runLabelShots(q: *const LatticeQubit, shots: u32, seed: u64) Error!LabelShotCounts {
    var stream = qmodel.SelectorStream.init(seed);
    var out: LabelShotCounts = .{ .shots = shots };
    var i: u32 = 0;
    while (i < shots) : (i += 1) {
        const label = try sampleLabel(q, stream.next());
        out.counts[label] += 1;
    }
    return out;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

fn testQubit(allocator: std.mem.Allocator, comptime t: i64, comptime v_shell: i64, comptime t_shell: i64) !LatticeQubit {
    return LatticeQubit.init(allocator, Q128.fromInteger(t), Q128.fromInteger(v_shell), Q128.fromInteger(t_shell));
}

test "site sampling is deterministic and measureSite collapses to a basis state" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa, 1, 10, 0);
    defer q.deinit(gpa);
    try q.prepareBasis(7, 7, 7);
    const before = domainDigest(&q);
    const s1 = try sampleSite(&q, 0);
    const s2 = try sampleSite(&q, std.math.maxInt(u64) - 1);
    try std.testing.expectEqual(s1, s2);
    try std.testing.expectEqual(q.h.idx(7, 7, 7), s1);
    // Pure sampling does not disturb the state.
    try std.testing.expectEqual(before, domainDigest(&q));
    // A two-site superposition makes collapse observable in the digest.
    const second = q.h.idx(3, 4, 5);
    q.psi[second] = Cx.one;
    const superposed = domainDigest(&q);
    const measured = try measureSite(&q, 12345);
    try std.testing.expect(measured == s1 or measured == second);
    try std.testing.expectEqual(@as(fixed.Raw, fixed.Scale), q.normSq().raw);
    const collapsed = domainDigest(&q);
    try std.testing.expect(!std.mem.eql(u8, &collapsed, &superposed));
}

test "label sampling weights match interior populations on a uniform state" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa, 1, 10, 0);
    defer q.deinit(gpa);
    const amp = Q128.one.div(try Q128.fromInteger(qb.BASIS).sqrt()) catch unreachable;
    q.prepareUniformInterior(amp);
    const w = labelWeights(&q);
    var total = Q128.zero;
    for (w) |x| total = total.add(x);
    // Interior norm ~= 1; each label class holds its census share.
    const interior_norm = q.normSq(); // shell is zero here
    try std.testing.expect(total.sub(interior_norm).abs().raw < fixed.Scale / 1000);
    try std.testing.expect(interior_norm.sub(Q128.one).abs().raw < fixed.Scale / 100);
    // e0 is the unique 421 deficit; e1..e7 carry 422 each.
    const expected = [_]Q128{
        Q128.fromRatio(421, qb.BASIS) catch unreachable,
    } ++ [_]Q128{Q128.fromRatio(422, qb.BASIS) catch unreachable} ** 7;
    for (w, expected) |got, want| {
        try std.testing.expect(got.sub(want).abs().raw < fixed.Scale / 500);
    }
}

test "measureLabel projects onto the label subspace and is absorbing" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa, 1, 10, 0);
    defer q.deinit(gpa);
    const amp = Q128.one.div(try Q128.fromInteger(qb.BASIS).sqrt()) catch unreachable;
    q.prepareUniformInterior(amp);
    // Put amplitude on a shell site too: label measurement must project it out.
    q.psi[q.h.idx(15, 7, 7)] = Cx.one;
    const label = try measureLabel(&q, 777);
    // Only the measured label retains population; shell is gone.
    for (0..8) |l| {
        const pop = q.labelPopulation(@intCast(l));
        if (l == label) {
            try std.testing.expect(pop.cmp(Q128.one) > 0);
        } else {
            try std.testing.expectEqual(@as(fixed.Raw, 0), pop.raw);
        }
    }
    try std.testing.expectEqual(@as(fixed.Raw, 0), q.shellPopulation().raw);
    try std.testing.expect(q.normSq().sub(Q128.one).abs().raw < fixed.Scale / 100);
    // Absorbing: every later label draw returns the same class.
    for (0..16) |i| {
        const again = try sampleLabel(&q, @intCast(1000 + i));
        try std.testing.expectEqual(label, again);
    }
}

test "collapseToLabel rejects empty classes and out-of-range labels" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa, 1, 10, 0);
    defer q.deinit(gpa);
    try q.prepareBasis(7, 7, 7); // origin is e0
    try std.testing.expectError(error.ZeroNorm, collapseToLabel(&q, 3));
    // Failed projection leaves the state untouched.
    try std.testing.expectEqual(@as(fixed.Raw, fixed.Scale), q.normSq().raw);
    try collapseToLabel(&q, 0);
    try std.testing.expectEqual(@as(fixed.Raw, fixed.Scale), q.normSq().raw);
}

test "selector edges and zero state are rejected without mutation" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa, 1, 10, 0);
    defer q.deinit(gpa);
    const digest0 = domainDigest(&q);
    try std.testing.expectError(error.ZeroNorm, sampleSite(&q, 0));
    try std.testing.expectError(error.ZeroNorm, sampleLabel(&q, 0));
    try q.prepareBasis(1, 2, 3);
    const digest1 = domainDigest(&q);
    try std.testing.expectError(error.InvalidSelector, sampleSite(&q, SELECTOR_MAX));
    try std.testing.expectError(error.InvalidSelector, sampleLabel(&q, SELECTOR_MAX));
    try std.testing.expectError(error.OutOfRange, collapseToSite(&q, qb.DOMAIN));
    try std.testing.expectError(error.OutOfRange, siteProbability(&q, qb.DOMAIN));
    try std.testing.expectError(error.OutOfRange, describeSite(&q, qb.DOMAIN));
    try std.testing.expectEqual(digest1, domainDigest(&q));
    _ = digest0;
}

test "site measurement covers shell sites and describeSite reports labels" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa, 1, 10, 0);
    defer q.deinit(gpa);
    const shell_idx = q.h.idx(15, 7, 7);
    q.psi[shell_idx] = Cx.one;
    const info = try describeSite(&q, shell_idx);
    try std.testing.expect(info.shell);
    try std.testing.expect(info.label == null);
    const measured = try measureSite(&q, 42);
    try std.testing.expectEqual(shell_idx, measured);
    try std.testing.expectEqual(@as(fixed.Raw, fixed.Scale), q.normSq().raw);
    // An interior site reports its e-label.
    const origin = try describeSite(&q, q.h.idx(7, 7, 7));
    try std.testing.expect(!origin.shell);
    try std.testing.expectEqual(@as(?u3, 0), origin.label);
}

test "runLabelShots reproduces deterministically and counts sum to shots" {
    const gpa = std.testing.allocator;
    var q = try testQubit(gpa, 1, 10, 0);
    defer q.deinit(gpa);
    const amp = Q128.one.div(try Q128.fromInteger(qb.BASIS).sqrt()) catch unreachable;
    q.prepareUniformInterior(amp);
    const a = try runLabelShots(&q, 4096, 42);
    const b = try runLabelShots(&q, 4096, 42);
    try std.testing.expectEqual(a.counts, b.counts);
    var sum: u32 = 0;
    for (a.counts) |c| sum += c;
    try std.testing.expectEqual(@as(u32, 4096), sum);
    // Uniform interior: no class should be starved or dominant.
    for (a.counts) |c| {
        try std.testing.expect(c > 300 and c < 800);
    }
}
