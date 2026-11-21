//! End-to-end continuity audit.
//!
//! Walks every seam of the pipeline from the `0^0 = i` axiom to the
//! algebra ladder, asserting that each producer's output contract is
//! honored by its consumer's input contract. Each SEAMS entry records
//! producer -> consumer, the invariant carried across the seam, and a
//! status: `verified` (executable check below), `convention` (declared
//! choice, not a break), or `open_lane` (named gap, never silent).
//!
//! Chain: axiom -> i-vector -> 15^3 labels -> (three-coloring
//! superposition) -> QComms channel / 16^3 domain -> Q128 amplitudes ->
//! evolution -> measurement contract -> i-vector readout ->
//! frames/serialize -> routing -> reversible CA -> scaling chain ->
//! algebra ladder -> Q# adapter.
//!
//! Findings recorded while mapping:
//!  - `LatticeQubit.lat` is `Lattice.init()` — the qbit's label
//!    observable reads the INIT coloring branch; QComms reads basisAt.
//!    Both branches share the census; S6 proves which branch is read.
//!  - `routing.zig` carries an inline copy of the hardware-orientation
//!    Fano table; it is used through unordered line membership only, so
//!    it is convention-blind (identical channels under either table).
//!  - The constant-audit side chain reaches 1024^3, one step beyond the
//!    canonical-pair family's max shell 512^3; the shell-side offset
//!    holds exactly for sides <= 512.
//!  - Signed Coord (routing, lattice API) vs unsigned Hamiltonian
//!    coords (quantum lane) are bridged by `index()`/`coordFromIndex()`
//!    with the +7 offset, and by `coords()` inside the 16^3 domain.

const std = @import("std");
const lattice = @import("lattice.zig");
const tiers = @import("redox_scaling_tiers.zig");
const qcomms = @import("qcomms_lattice.zig");
const qbit = @import("lattice_qbit.zig");
const ham = @import("quantum/lattice_hamiltonian.zig");
const measure = @import("lattice_measure.zig");
const readout = @import("ivector_readout.zig");
const ivector = @import("redox_information_vector.zig");
const serialize = @import("serialize.zig");
const smith_table = @import("smith_table.zig");
const frames = @import("frames.zig");
const routing = @import("routing.zig");
const reversible = @import("reversible_lattice.zig");
const ladder_scale = @import("precision_ladder.zig");
const dimladder = @import("redox_dimensional_ladder.zig");
const registry = @import("axiom_registry.zig");
const adapter = @import("qsharp_adapter.zig");
const fp = @import("fixed_point.zig");

const Q128 = fp.Q128;

pub const SeamKind = enum { verified, convention, open_lane };

pub const Seam = struct {
    id: []const u8,
    producer: []const u8,
    consumer: []const u8,
    invariant: []const u8,
    kind: SeamKind,
};

pub const SEAMS = [_]Seam{
    .{ .id = "S0.axiom_ivector", .producer = "0^0=i", .consumer = "ivector.Vector", .invariant = "component enum e0..e7 = label index 0..7", .kind = .verified },
    .{ .id = "S1.ivector_labels", .producer = "i-vector", .consumer = "15^3 tensor", .invariant = "census [421,422x7], e0 singleton at origin", .kind = .verified },
    .{ .id = "S2.coloring_superposition", .producer = "three valid colorings", .consumer = "shared census", .invariant = "one census, pairwise divergence 1980/3375/3375", .kind = .verified },
    .{ .id = "S3.labels_qcomms", .producer = "basisAt", .consumer = "qcomms state/shellState", .invariant = "interior labels, Foam=8 shell sentinel", .kind = .verified },
    .{ .id = "S4.interior_domain", .producer = "15^3 interior", .consumer = "16^3 Hamiltonian domain", .invariant = "coords(idx) roundtrip; shell iff any coord==15; 721 sites", .kind = .verified },
    .{ .id = "S5.domain_amplitudes", .producer = "16^3 domain", .consumer = "Q128 psi[4096]", .invariant = "prepareBasis: unit norm, zero shell, peak at site", .kind = .verified },
    .{ .id = "S6.label_observable_branch", .producer = "Lattice.init labels", .consumer = "label observable", .invariant = "the qbit reads the INIT coloring branch", .kind = .verified },
    .{ .id = "S7.evolution", .producer = "amplitudes", .consumer = "Chebyshev propagator", .invariant = "tau=0 identity; unitary bounds live in quantum lane", .kind = .verified },
    .{ .id = "S8.measurement", .producer = "state", .consumer = "lattice_measure contract", .invariant = "site+label observables, Lüders projection, deterministic selectors", .kind = .verified },
    .{ .id = "S9.measure_ivector", .producer = "label populations", .consumer = "ivector readout", .invariant = "population index k -> component e_k; digest deterministic", .kind = .verified },
    .{ .id = "S10.frames_serialize", .producer = "Lattice.init tensor", .consumer = "frames + wall-v2 manifest", .invariant = "extract/reassemble exact; validate() gates census+mirror+smith", .kind = .verified },
    .{ .id = "S11.routing", .producer = "init labels + signed Coord", .consumer = "routing.Router", .invariant = "420 eligible (e0 minus origin); Fano channels convention-blind", .kind = .verified },
    .{ .id = "S12.reversible_ca", .producer = "16^3 domain", .consumer = "Margolus CA", .invariant = "SITE_COUNT == DOMAIN == 4096", .kind = .verified },
    .{ .id = "S13.scale_chain", .producer = "canonical pairs", .consumer = "constant-audit sides", .invariant = "audit side s<=512 appears as pair shell; offset holds <=512 only", .kind = .verified },
    .{ .id = "S14.algebra_ladder", .producer = "redox_* tiers", .consumer = "registry", .invariant = "11-tier order; superposition siblings registered", .kind = .verified },
    .{ .id = "S15.qsharp_adapter", .producer = "bounded simulator", .consumer = "Q# vocabulary", .invariant = "adapter maps vocabulary only — no runtime coupling", .kind = .convention },
    .{ .id = "S16.phase_conventions", .producer = "Phase + U(8) family", .consumer = "serializeAlloc explicit param", .invariant = "serialization requires explicit convention selection", .kind = .verified },
    .{ .id = "S17.registry_closure", .producer = "registry", .consumer = "validate()", .invariant = "unique ids, closed edges, ladder order", .kind = .verified },
};

fn tableUnderTest() smith_table.Table {
    var result: smith_table.Table = .{ .entries = undefined };
    for (0..15) |row| {
        for (0..15) |column| {
            const x: i8 = @intCast(@as(i16, @intCast(column)) - 7);
            const y: i8 = @intCast(@as(i16, @intCast(row)) - 7);
            result.entries[smith_table.index(x, y).?] = .{
                .gamma_re = 0,
                .gamma_im = 0,
                .impedance_re = smith_table.SCALE,
                .impedance_im = 0,
                .state = .finite,
            };
        }
    }
    result.entries[smith_table.index(7, 0).?].state = .open;
    result.entries[smith_table.index(-7, 0).?].state = .short;
    return result;
}

test "S0/S9 i-vector binding: population index k lands on component e_k" {
    var w = [_]Q128{Q128.zero} ** 8;
    w[3] = Q128.fromInteger(1);
    const v = try readout.populationsToIVector(&w, 8);
    for (0..8) |k| {
        const component: ivector.Component = @enumFromInt(@as(u3, @intCast(k)));
        try std.testing.expectEqual(if (k == 3) @as(i512, 8) else 0, v.at(component));
    }
}

test "S1/S2 labels: three colorings carry one census in superposition" {
    const lattice_tensor = lattice.Lattice.init();
    var h_state = [_]usize{0} ** 8;
    var h_legacy = [_]usize{0} ** 8;
    var h_init = [_]usize{0} ** 8;
    var d_si: usize = 0;
    var d_sl: usize = 0;
    var d_il: usize = 0;
    for (0..15) |z| for (0..15) |y| for (0..15) |x| {
        const s = qcomms.state(@intCast(x), @intCast(y), @intCast(z));
        const l = qcomms.legacyState(@intCast(x), @intCast(y), @intCast(z));
        const i = lattice_tensor.labels[lattice.Lattice.indexUnsigned(x, y, z)];
        h_state[s] += 1;
        h_legacy[l] += 1;
        h_init[i] += 1;
        if (s != i) d_si += 1;
        if (s != l) d_sl += 1;
        if (i != l) d_il += 1;
    };
    const census = [_]usize{ 421, 422, 422, 422, 422, 422, 422, 422 };
    try std.testing.expectEqual(census, h_state);
    try std.testing.expectEqual(census, h_init);
    var legacy_sorted = h_legacy;
    std.mem.sort(usize, &legacy_sorted, {}, std.sort.asc(usize));
    try std.testing.expectEqual(census, legacy_sorted);
    try std.testing.expectEqual(@as(usize, 1980), d_si);
    try std.testing.expectEqual(@as(usize, 3375), d_sl);
    try std.testing.expectEqual(@as(usize, 3375), d_il);
    // e0 singleton at the signed origin in the init/basisAt branches.
    try std.testing.expectEqual(@as(usize, 421), lattice_tensor.countLabel(0));
    try std.testing.expectEqual(@as(u3, 0), lattice_tensor.labels[lattice.Lattice.indexUnsigned(7, 7, 7)]);
    try std.testing.expectEqual(@as(u64, 0), tiers.basisAt(7, 7, 7, 15));
}

test "S3 labels -> QComms channel: interior equals basisAt, shell is Foam" {
    for (0..15) |z| for (0..15) |y| for (0..15) |x| {
        try std.testing.expectEqual(tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), 15), qcomms.state(@intCast(x), @intCast(y), @intCast(z)));
    };
    var foam: usize = 0;
    for (0..16) |z| for (0..16) |y| for (0..16) |x| {
        const s = qcomms.shellState(@intCast(x), @intCast(y), @intCast(z));
        if (s == qcomms.Foam) {
            foam += 1;
            try std.testing.expect(x == 15 or y == 15 or z == 15);
        }
    };
    try std.testing.expectEqual(@as(usize, 721), foam);
    // Foam is a sentinel outside the u3 label range.
    try std.testing.expectEqual(@as(u8, 8), qcomms.Foam);
}

test "S4 interior -> 16^3 domain: coordinate bridge and shell census" {
    const h = ham.Hamiltonian.canonical(Q128.fromInteger(1), Q128.fromInteger(10));
    var interior: usize = 0;
    var shell: usize = 0;
    for (0..16) |z| for (0..16) |y| for (0..16) |x| {
        const i = h.idx(x, y, z);
        const c = h.coords(i);
        try std.testing.expectEqual(x, c.x);
        try std.testing.expectEqual(y, c.y);
        try std.testing.expectEqual(z, c.z);
        const on_shell = x == 15 or y == 15 or z == 15;
        try std.testing.expectEqual(on_shell, h.isShell(i));
        if (on_shell) shell += 1 else interior += 1;
    };
    try std.testing.expectEqual(@as(usize, 3375), interior);
    try std.testing.expectEqual(@as(usize, 721), shell);
    try std.testing.expectEqual(@as(usize, 4096), qbit.DOMAIN);
    try std.testing.expectEqual(@as(usize, 3375), qbit.BASIS);
    try std.testing.expectEqual(qbit.DOMAIN - qbit.BASIS, qbit.SHELL_SITES);
    try std.testing.expectEqual(qbit.DOMAIN, reversible.SITE_COUNT);
    // Signed/unsigned bridge: coord (s-7) <-> index(s) roundtrip.
    for (0..15) |z| for (0..15) |y| for (0..15) |x| {
        const flat = lattice.Lattice.indexUnsigned(x, y, z);
        const c = lattice.Lattice.coordFromIndex(flat).?;
        try std.testing.expectEqual(@as(i8, @intCast(x)) - 7, c.x);
        try std.testing.expectEqual(@as(i8, @intCast(y)) - 7, c.y);
        try std.testing.expectEqual(@as(i8, @intCast(z)) - 7, c.z);
        try std.testing.expectEqual(flat, lattice.Lattice.index(c).?);
    };
}

test "S5 domain -> amplitudes: prepareBasis gives unit norm, dark shell, peak at site" {
    const gpa = std.testing.allocator;
    var q = try qbit.LatticeQubit.init(gpa, Q128.fromInteger(1), Q128.fromInteger(10), Q128.zero);
    defer q.deinit(gpa);
    try q.prepareBasis(3, 4, 5);
    try std.testing.expectEqual(Q128.fromInteger(1).raw, q.normSq().raw);
    try std.testing.expectEqual(Q128.zero.raw, q.shellPopulation().raw);
    try std.testing.expectEqual(q.h.idx(3, 4, 5), q.peak().index);
    try std.testing.expectError(error.OutOfRange, q.prepareBasis(15, 0, 0));
}

test "S6 the qbit's label observable reads the init-coloring branch" {
    const gpa = std.testing.allocator;
    var q = try qbit.LatticeQubit.init(gpa, Q128.fromInteger(1), Q128.fromInteger(10), Q128.zero);
    defer q.deinit(gpa);
    const lat = lattice.Lattice.init();
    // Find a cell that is e0 in the init branch but not in basisAt:
    // preparing a basis state there must read full observer population —
    // proving the observable follows init, not basisAt.
    var proven = false;
    for (0..15) |z| for (0..15) |y| for (0..15) |x| {
        if (lat.labels[lattice.Lattice.indexUnsigned(x, y, z)] == 0 and tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), 15) != 0) {
            try q.prepareBasis(x, y, z);
            try std.testing.expectEqual(Q128.fromInteger(1).raw, q.observerPopulation().raw);
            proven = true;
            break;
        }
    };
    try std.testing.expect(proven);
    // Mirror check: a cell that is e0 in basisAt but not init reads zero.
    var mirror = false;
    for (0..15) |z| for (0..15) |y| for (0..15) |x| {
        if (lat.labels[lattice.Lattice.indexUnsigned(x, y, z)] != 0 and tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), 15) == 0) {
            try q.prepareBasis(x, y, z);
            try std.testing.expectEqual(Q128.zero.raw, q.observerPopulation().raw);
            mirror = true;
            break;
        }
    };
    try std.testing.expect(mirror);
}

test "S7/S8 amplitudes -> evolution -> measurement contract" {
    const gpa = std.testing.allocator;
    var q = try qbit.LatticeQubit.init(gpa, Q128.fromInteger(1), Q128.fromInteger(10), Q128.zero);
    defer q.deinit(gpa);
    try q.prepareBasis(7, 7, 7);
    // tau=0 evolution is the identity on the state.
    q.evolve(Q128.zero, 4);
    try std.testing.expectEqual(Q128.fromInteger(1).raw, q.normSq().raw);
    try std.testing.expectEqual(q.h.idx(7, 7, 7), q.peak().index);
    // Label observable on the origin basis state returns e0.
    try std.testing.expectEqual(@as(u3, 0), try measure.sampleLabel(&q, 1));
    // Site collapse lands on the measured site with unit norm.
    const site = try measure.sampleSite(&q, 2);
    try measure.collapseToSite(&q, site);
    try std.testing.expectEqual(site, q.peak().index);
    try std.testing.expectEqual(Q128.fromInteger(1).raw, q.normSq().raw);
}

test "S10 lattice -> frames + serialize: exact roundtrip and gated manifest" {
    var lattice_tensor = lattice.Lattice.init();
    const fs = frames.extract(&lattice_tensor);
    const rebuilt = frames.reassemble(&fs).?;
    try std.testing.expectEqualSlices(u3, &lattice_tensor.labels, &rebuilt.labels);
    const table = tableUnderTest();
    try std.testing.expect(serialize.validate(&lattice_tensor, &table));
}

test "S11 labels -> routing: eligible e0 observers and valid default graph" {
    const lattice_tensor = lattice.Lattice.init();
    try std.testing.expectEqual(@as(usize, 420), routing.eligibleCount(&lattice_tensor));
    try std.testing.expectEqual(routing.ELIGIBLE_SITE_COUNT, qbit.OBSERVERS - 1);
    const router = routing.Router.init(lattice_tensor);
    try std.testing.expect(router.validate());
}

test "S13 scale chain: canonical pairs and audit-side offset" {
    const pairs = ladder_scale.canonicalPairs();
    try std.testing.expectEqual(@as(usize, 6), pairs.len);
    const inners = [_]u16{ 15, 30, 60, 120, 240, 480 };
    const shells = [_]u16{ 16, 32, 64, 128, 256, 512 };
    for (pairs, 0..) |p, k| {
        try std.testing.expectEqual(inners[k], p.inner);
        try std.testing.expectEqual(shells[k], p.shell);
        // Compounding law: one +1 shell layer per canonical 15-block.
        try std.testing.expectEqual(p.inner / 15, p.shell - p.inner);
        try std.testing.expectEqual(p.inner, ladder_scale.canonicalInner(p.shell));
    }
    // Audit power-of-two sides <=512 are exactly pair shells; 1024 lies
    // beyond the pair family — the offset is bounded, not a break.
    const audit_sides = [_]u16{ 32, 64, 128, 256, 512 };
    for (audit_sides) |s| {
        var found = false;
        for (pairs) |p| if (p.shell == s) {
            found = true;
        };
        try std.testing.expect(found);
    }
}

test "S14/S15/S17 ladder, adapter, and registry closure" {
    // The measured ladder is exactly 11 tiers; superposition siblings
    // (sedenion, dual Fano) are registered off-ladder.
    try std.testing.expectEqual(@as(usize, 11), dimladder.LADDER.len);
    try std.testing.expect(registry.nodeById("ladder.sedenion_16d") != null);
    try std.testing.expect(registry.nodeById("ladder.anti_octonion_9d") != null);
    try std.testing.expect(registry.nodeById("cyber.superposition_law_v1") != null);
    // Adapter: vocabulary-level register over the bounded simulator.
    var reg = try adapter.Register.init(2);
    try reg.h(0);
    try reg.cnot(0, 1);
    _ = try reg.measure(42);
    _ = try reg.measureAndReset(1, 43);
    // Registry closure: unique ids, closed edges, ladder order.
    try std.testing.expect(registry.validate());
}

test "S16 phase family: serialization requires explicit convention" {
    // The declared family is the complete unit group U(8); serialization
    // takes the convention as an explicit parameter, not a default.
    const info = @typeInfo(lattice.PhaseConvention).Enum;
    try std.testing.expectEqual(@as(usize, 4), info.fields.len);
    var seen = [_]bool{false} ** 8;
    inline for (info.fields) |field| seen[field.value] = true;
    for ([_]u8{ 1, 3, 5, 7 }) |u| try std.testing.expect(seen[u]);
    try std.testing.expectEqual(lattice.PhaseConvention.three_quarter_turn_per_transit, lattice.CANONICAL_PHASE_CONVENTION);
    for ([_]lattice.PhaseConvention{ .quarter_turn_per_transit, .three_quarter_turn_per_transit, .five_quarter_turn_per_transit, .seven_quarter_turn_per_transit }) |conv| {
        var phase = lattice.Phase{};
        for (0..lattice.PHASE_STEPS_PER_CYCLE) |_| phase.transit(conv);
        try std.testing.expectEqual(@as(u3, 0), phase.eighth_turns);
    }
}
