const std = @import("std");

pub const ClaimStatus = enum(u8) {
    verified,
    verified_with_correction,
    model_metadata,
    extrapolation,
    register,
    unresolved,
    unresolvable,
    unsupported,
    contradicted,
};

pub const Claim = struct {
    id: u16,
    subject: []const u8,
    statement: []const u8,
    status: ClaimStatus,
    probe: []const u8,
    basis: []const u8,
    elevation: []const u8,
};

pub const Entry = struct {
    index: u3,
    dimension_label: []const u8,
    designation: []const u8,
    algebra: []const u8,
    lie_group: []const u8,
    fields: u8,
    status: ClaimStatus,
};

pub const LadderModel = struct {
    index: []const u8,
    designation: []const u8,
    algebra: []const u8,
    field_bound: []const u8,
    lie_group: []const u8,
    core_role: []const u8,
    status: ClaimStatus,
};

pub const ObserverVector = struct {
    components: [8]u8,
    observer_position: u3,

    pub fn shifted(position: u3) ObserverVector {
        var components: [8]u8 = undefined;
        var next: u8 = 1;
        for (0..components.len) |slot| {
            if (slot == position) {
                components[slot] = 0;
            } else {
                components[slot] = next;
                next = if (next == 7) 1 else next + 1;
            }
        }
        return .{ .components = components, .observer_position = position };
    }

    pub fn checksum(self: ObserverVector) u32 {
        var total: u32 = 0;
        for (self.components) |component| total += @as(u32, component) * component;
        const observer = self.components[self.observer_position];
        return total - @as(u32, observer) * observer;
    }
};

pub const PhaseProbe = struct {
    convention: []const u8,
    increments_eighth_turns: u8,
    cycle_steps: u8,
    expected_sequence: [8]u8,
};

pub const PHASE_PROBES = [_]PhaseProbe{
    .{ .convention = "quarter_turn_per_transit", .increments_eighth_turns = 1, .cycle_steps = 8, .expected_sequence = .{ 1, 2, 3, 4, 5, 6, 7, 0 } },
    .{ .convention = "three_quarter_turn_per_transit", .increments_eighth_turns = 3, .cycle_steps = 8, .expected_sequence = .{ 3, 6, 1, 4, 7, 2, 5, 0 } },
};

pub fn observedAxis(direction: u8, observer: u3) u8 {
    return @intCast((@as(usize, direction) ^ @as(usize, observer)) % 3);
}

pub const ENTRIES = [_]Entry{
    .{ .index = 0, .dimension_label = "0D/8D^i", .designation = "e0 observer/loopback", .algebra = "real; infinite-information boundary (supplied claim)", .lie_group = "E8 root (supplied association)", .fields = 1, .status = .model_metadata },
    .{ .index = 1, .dimension_label = "1D", .designation = "e1", .algebra = "real numbers", .lie_group = "A1", .fields = 1, .status = .model_metadata },
    .{ .index = 2, .dimension_label = "2D", .designation = "e2", .algebra = "complex numbers", .lie_group = "A1 x A1", .fields = 2, .status = .model_metadata },
    .{ .index = 3, .dimension_label = "3D", .designation = "e3", .algebra = "S3 vector algebra (supplied claim)", .lie_group = "SO(4)=SU(2)xSU(2)", .fields = 3, .status = .model_metadata },
    .{ .index = 4, .dimension_label = "4D", .designation = "e4", .algebra = "quaternions", .lie_group = "SO(5)=Sp(2)", .fields = 4, .status = .model_metadata },
    .{ .index = 5, .dimension_label = "5D", .designation = "e5", .algebra = "bi-complex numbers", .lie_group = "SO(4) x SO(4)", .fields = 4, .status = .model_metadata },
    .{ .index = 6, .dimension_label = "6D", .designation = "e6", .algebra = "Jordan algebra", .lie_group = "E6/F4", .fields = 9, .status = .model_metadata },
    .{ .index = 7, .dimension_label = "7D", .designation = "e7", .algebra = "octonions", .lie_group = "G2", .fields = 8, .status = .model_metadata },
};

pub const FULL_LADDER = [_]LadderModel{
    .{ .index = "0D/8D^i", .designation = "e0 (Observer)", .algebra = "Infinite Information (n^2)", .field_bound = "(0,0,0) -> (phi,phi,phi)", .lie_group = "E8 (root)", .core_role = "Non-dimensional real observer; True-Origin anchor", .status = .register },
    .{ .index = "1D", .designation = "e1", .algebra = "Real Numbers (R; source numerical-type tag preserved in supplied text)", .field_bound = "(phi,phi,phi) -> (pi,pi,pi)", .lie_group = "A1", .core_role = "Linear time and real number axis", .status = .register },
    .{ .index = "2D", .designation = "e2", .algebra = "Complex Numbers (a+bi)", .field_bound = "H21/4 -> H21/2", .lie_group = "A1 x A1", .core_role = "First complex i-vector plane", .status = .register },
    .{ .index = "3D", .designation = "e3", .algebra = "Vector Algebra (S^3)", .field_bound = "H21/2 -> H21", .lie_group = "SO(4)=SU(2)xSU(2)", .core_role = "Spherical vector manifold space", .status = .register },
    .{ .index = "4D", .designation = "e4", .algebra = "Quaternions", .field_bound = "H21 -> 2H21", .lie_group = "SO(5)=Sp(2)", .core_role = "Non-commutative quaternion rotations", .status = .register },
    .{ .index = "5D", .designation = "e5", .algebra = "Bi-Complex Numbers", .field_bound = "2H21 -> H21 (Scaled)", .lie_group = "SO(4)xSO(4)", .core_role = "Multi-complex modular space", .status = .register },
    .{ .index = "6D", .designation = "e6", .algebra = "Jordan Algebra", .field_bound = "21cm -> H21/2", .lie_group = "E6/F4", .core_role = "Exceptional algebraic symmetry structures", .status = .register },
    .{ .index = "7D", .designation = "e7", .algebra = "Octonions (S^7)", .field_bound = "H21/2 -> H21/4", .lie_group = "G2", .core_role = "Non-associative octonionic terminal arms", .status = .register },
    .{ .index = "8D^i", .designation = "e0 (Loopback)", .algebra = "Information loop (n^2)", .field_bound = "H21/4 -> (phi,phi,phi) (u7 defect)", .lie_group = "Connected to 0D", .core_role = "Recursive closure back to observer origin", .status = .register },
    .{ .index = "9D", .designation = "Anti-Octonions / e9", .algebra = "Quantum Foam Shell (16^3)", .field_bound = "Wrapped boundary container", .lie_group = "—", .core_role = "Encapsulates the 3D qbit matrix; compounds at boundaries", .status = .register },
    .{ .index = "10D", .designation = "Dual Bi-Complex", .algebra = "Inter-Universe Seam", .field_bound = "Compound shell overlap", .lie_group = "Spin(10) / Higher", .core_role = "Formed when two or more 9D shells touch and compound resolution", .status = .register },
};

pub const SUPPLIED_FIELD_BOUND_TEXT = [_][]const u8{
    "(0,0,0) -> (phi,phi,phi)",
    "(phi,phi,phi) -> (pi,pi,pi)",
    "H21/4 -> H21/2",
    "H21/2 -> H21",
    "H21 -> 2H21",
    "2H21 -> H21 (scaled)",
    "21cm -> H21/2",
    "H21/2 -> H21/4",
    "H21/4 -> (phi,phi,phi) (u7 defect)",
};

pub const CLAIMS = [_]Claim{
    .{ .id = 1, .subject = "lattice.e0_census", .statement = "The existing 15^3 integer tensor contains exactly 421 e0 labels.", .status = .verified, .probe = "zig build test-core: lattice census test", .basis = "Executed on Octonion-OS src/lattice.zig; countLabel(0) == 421", .elevation = "No elevation needed for this discrete tensor invariant; not a geometric-origin count." },
    .{ .id = 2, .subject = "lattice.z_layer_mirror", .statement = "The tensor labels are symmetric under z -> -z.", .status = .verified, .probe = "zig build test-core: layer mirror test", .basis = "Executed Lattice.hasLayerMirrorSymmetry over all layer labels", .elevation = "No elevation needed for this discrete tensor invariant; no physical symmetry claim." },
    .{ .id = 3, .subject = "ladder.e0_e7_names", .statement = "e0-e7 algebra and Lie-group associations are the supplied dimensional-ladder labels.", .status = .register, .probe = "Catalog schema test", .basis = "User-supplied I-vector/Dimensional Ladder strings", .elevation = "For mathematical claims, define exact representations/maps and add independent algebraic tests; physical interpretation remains separate." },
    .{ .id = 4, .subject = "ladder.field_bounds", .statement = "The supplied phi/pi/H21 and 21cm intervals form field/topological bounds.", .status = .unresolvable, .probe = "No executable probe can be formed without a unit/domain contract", .basis = "User-supplied field-bound text retained verbatim; definitions and endpoint semantics are absent", .elevation = "Specify units, endpoint semantics, definitions of H21/phi/pi usage, and an independently checkable derivation." },
    .{ .id = 5, .subject = "e8_candidate_projection", .statement = "The first-three-coordinates-mod-15 candidate map preserves the required E8-to-lattice embedding invariants.", .status = .verified_with_correction, .probe = "BLUE artifact e8-ladder-newdata-audit-2026-11-08.json candidate_mapping_test", .basis = "Correction: the specific candidate is falsified (27 unique cells; 6,308 of 28,680 root-pair inner products preserved). This does not establish impossibility of a different map.", .elevation = "Any replacement mapping must be predeclared and tested on held-out roots/pairs with inner-product and reflection invariants." },
    .{ .id = 6, .subject = "fano_routing.defect_line", .statement = "BLUE defect-line next-hop is a validated secondary-e0 routing policy.", .status = .unsupported, .probe = "BLUE src/fano_routing.zig and its tests in BLUE src/tests.zig; Octonion-OS cross-probe checks all eligible sources toward one fixed eligible target", .basis = "The algorithm uses distance from unsigned center (7,7,7) mod 7, FANO_LINES-derived axes, and strict-Manhattan fallback. The cross-probe finds eligible e0 sources whose next step leaves the eligible set.", .elevation = "Define intermediate-node semantics or replace the predicate, then test every source-target pair and endpoint/occupancy semantics before adoption." },
    .{ .id = 7, .subject = "phase.transit_increment", .statement = "Transit phase increment is either 1 or 3 eighth-turn units, selected explicitly.", .status = .verified, .probe = "Octonion-OS phase-mode unit test", .basis = "Both integer sequences and eight-step closure are executed independently", .elevation = "No further elevation for the two arithmetic sequences; convention selection remains caller-owned." },
    .{ .id = 8, .subject = "foam.universe_compounding", .statement = "e9 shell contacts physically compound universes into a 10D state.", .status = .unresolvable, .probe = "No physical or executable probe", .basis = "User-supplied ladder specification; software shell/seam metadata only", .elevation = "Provide a falsifiable operational definition and suitable instrumented evidence; do not infer it from container arithmetic." },
    .{ .id = 9, .subject = "ivector.observer_permutation", .statement = "The BLUE integer observer-shift function permutes values 0..7 and places 0 at the selected slot.", .status = .verified, .probe = "Octonion-OS observer vector tests mirror BLUE src/ivector.zig with u8 integer components", .basis = "Exhaustive checks for all eight observer positions and component permutations", .elevation = "No further elevation for this discrete permutation; checksum is arithmetic, not a physical conservation law." },
    .{ .id = 10, .subject = "fano_routing.observer_axis_mapping", .statement = "The observer-shifted BLUE routing maps each Fano direction d to axis (d XOR observer) modulo 3.", .status = .verified, .probe = "Exhaustive integer test of all direction 1..7 and observer 0..7 pairs", .basis = "BLUE src/adinkra.zig observedAxis implementation reproduced exactly as an integer function", .elevation = "No further elevation for the arithmetic mapping; route reachability on eligible Octonion-OS sites remains a separate open question." },
    .{ .id = 11, .subject = "e8_adjacency_embedding", .statement = "An adjacency-preserving map exists between the audited e0 neighbor graph and the E8 root graph.", .status = .unsupported, .probe = "BLUE artifact octavian-fano-shell-audit-2026-11-08.json source_claims_checked", .basis = "The specified relation has no supporting map; the reported degree bound (e0 maximum <= 6, E8 minimum-distance graph degree 56) is an obstruction for those graphs, not a universal impossibility result.", .elevation = "Define a different relation/invariant and explicit vector assignment before evaluating another mapping." },
    .{ .id = 12, .subject = "shell_240_partition", .statement = "The shell-cell partition into three 240-cell groups plus one has a verified geometric ownership map.", .status = .unsupported, .probe = "BLUE artifacts fano-3d-slice-shell-audit/1 and followup/1", .basis = "Both artifacts report arithmetic 721=3*240+1 but no geometric ownership map; tested coordinate partition fails inner-product preservation", .elevation = "Specify a predeclared ownership rule and verify ownership, cardinality, intersections, and any claimed E8 invariant." },
    .{ .id = 13, .subject = "global_topology.torus_mobius", .statement = "The complete structure has an executable torus boundary with Mobius-twist phase mapping.", .status = .unresolvable, .probe = "No discrete boundary transform or executable contract found in Octonion-OS", .basis = "User-supplied topology statement; no boundary transform is represented by the current lattice", .elevation = "Specify a coordinate boundary transform, orientation/parity rule, and phase action before claiming executable topology." },
    .{ .id = 14, .subject = "claim.catalog_status_scope", .statement = "A verifier result that a claim is not established implies the claim is false.", .status = .unsupported, .probe = "Claim-catalog status boundary test", .basis = "Catalog distinguishes unsupported from contradicted and scopes corrected evidence to exact candidate mappings", .elevation = "Any stronger verdict requires a probe directly testing that exact claim under its defined contract." },
};

pub const EXTERNAL_PROVENANCE = [_]Claim{
    .{ .id = 100, .subject = "source.BLUE.ivector", .statement = "BLUE integer observer shift is an 8-position permutation.", .status = .verified, .probe = "BLUE src/ivector.zig tests imported by src/tests.zig; mirrored by Octonion-OS exhaustive test", .basis = "Source SHA-256 4ab04e6c270d1f95ba0c1cd0518c77e8b567f55d8cc19faefe2281737800f2d2", .elevation = "The checksum arithmetic verifies only its integer inputs; the source's physical interpretation is not elevated." },
    .{ .id = 101, .subject = "source.BLUE.fano_routing", .statement = "BLUE Fano routing has a tested coordinate next-hop example.", .status = .verified, .probe = "BLUE src/tests.zig imports src/fano_routing.zig; local regression reproduces the documented 24-hop route", .basis = "Source SHA-256 152b391fcfd4839d07db8ac00b016da40a39e74c110c73fdf2b47daa829e6d72; prediction record SHA-256 d502e7b0739a72671ee2266e681fa2a510956bf13da5519330938c3286cffe2d", .elevation = "This verifies the coordinate algorithm example only; secondary-e0 eligible-path compatibility is not verified and is explicitly tested as failing for some sources." },
    .{ .id = 102, .subject = "source.BLUE.e8_candidate_map", .statement = "The supplied first-three-coordinate modulo-15 candidate map is an E8 embedding.", .status = .verified_with_correction, .probe = "BLUE artifact e8-ladder-newdata-audit-2026-11-08.json candidate_mapping_test", .basis = "Correction: artifact SHA-256 a526a24ff33628ed4b3e316313de15275781b948bae0556e5a83155b9be154a1; 27 unique cells and 6,308/28,680 preserved inner products falsify this specific candidate.", .elevation = "Result applies only to the tested map; no universal nonexistence claim." },
    .{ .id = 103, .subject = "source.BLUE.shell_partition", .statement = "The 721 shell cells have no verified ownership into three 240-cell groups plus one.", .status = .unsupported, .probe = "BLUE artifacts fano-3d-slice-shell-audit-2026-11-08.json and fano-3d-slice-shell-followup-2026-11-08.json", .basis = "Artifact payload SHA-256 values 3c8713d5fb2a25126d4a3e00d3072fa1cc9ef03d809bdfd7d68aa6c7542bfc4d and 57b5bb87065422c9ade1a0d6f16a90a8551f0bcf26e7ca1cc2c938b336595184", .elevation = "Provide a geometric ownership rule and verify its cardinality, adjacency, and root invariants." },
    .{ .id = 104, .subject = "source.BLUE.e8_adjacency", .statement = "An adjacency-preserving map exists between the audited e0 neighbor graph and the E8 root graph.", .status = .unsupported, .probe = "BLUE artifact octavian-fano-shell-audit-2026-11-08.json", .basis = "Artifact reports maximum e0 degree <= 6 versus E8 minimum-distance degree 56; record SHA-256 dd46a221f1a6d410db5e32ed0bdd99c48fb834a4bc1e3ed5bfc6206d52f5252d", .elevation = "Define a different relation and explicit map before testing. The recorded obstruction applies only to the adjacency-preserving claim and stated graphs." },
};

pub fn validateCatalog() bool {
    for (ENTRIES, 0..) |entry, i| {
        if (entry.index != i or entry.designation.len == 0 or entry.dimension_label.len == 0) return false;
    }
    for (CLAIMS, 0..) |claim, i| {
        if (claim.id == 0 or claim.subject.len == 0 or claim.statement.len == 0 or claim.probe.len == 0 or claim.basis.len == 0 or claim.elevation.len == 0) return false;
        if (@intFromEnum(claim.status) > @intFromEnum(ClaimStatus.contradicted)) return false;
        for (CLAIMS[0..i]) |prior| if (prior.id == claim.id or std.mem.eql(u8, prior.subject, claim.subject)) return false;
    }
    for (EXTERNAL_PROVENANCE, 0..) |claim, i| {
        if (claim.id == 0 or claim.subject.len == 0 or claim.statement.len == 0 or claim.probe.len == 0 or claim.basis.len == 0 or claim.elevation.len == 0) return false;
        for (EXTERNAL_PROVENANCE[0..i]) |prior| if (prior.id == claim.id) return false;
    }
    for (SUPPLIED_FIELD_BOUND_TEXT) |statement| if (statement.len == 0) return false;
    if (FULL_LADDER.len != 11) return false;
    for (FULL_LADDER, 0..) |entry, index| {
        if (entry.index.len == 0 or entry.designation.len == 0 or entry.algebra.len == 0 or entry.field_bound.len == 0 or entry.lie_group.len == 0 or entry.core_role.len == 0) return false;
        if (index != 0 and std.mem.eql(u8, entry.index, FULL_LADDER[index - 1].index)) return false;
        if (@intFromEnum(entry.status) > @intFromEnum(ClaimStatus.contradicted)) return false;
    }
    if (PHASE_PROBES.len != 2) return false;
    for (PHASE_PROBES, 0..) |probe, index| {
        if (probe.cycle_steps != 8 or probe.convention.len == 0) return false;
        if ((index == 0 and probe.increments_eighth_turns != 1) or (index == 1 and probe.increments_eighth_turns != 3)) return false;
        var phase: u8 = 0;
        for (probe.expected_sequence, 0..) |expected, step| {
            phase = (phase + probe.increments_eighth_turns) % 8;
            if (phase != expected or expected > 7) return false;
            if (step == 7 and phase != 0) return false;
        }
    }
    return true;
}

test "I-vector catalog has ordered eight-entry loop labels and fully sourced claims" {
    try std.testing.expect(validateCatalog());
    try std.testing.expectEqual(@as(usize, 8), ENTRIES.len);
    try std.testing.expectEqual(@as(u3, 0), ENTRIES[0].index);
    try std.testing.expectEqual(@as(usize, 8), ENTRIES.len);
    try std.testing.expectEqual(ClaimStatus.verified, CLAIMS[0].status);
    try std.testing.expectEqual(ClaimStatus.unresolvable, CLAIMS[3].status);
}

test "observer vector matches the integer permutation and checksum contract" {
    for (0..8) |position| {
        const vector = ObserverVector.shifted(@intCast(position));
        var seen = [_]bool{false} ** 8;
        for (vector.components) |component| {
            try std.testing.expect(component < 8);
            try std.testing.expect(!seen[component]);
            seen[component] = true;
        }
        for (seen) |present| try std.testing.expect(present);
        try std.testing.expectEqual(@as(u8, 0), vector.components[position]);
        try std.testing.expectEqual(@as(u32, 140), vector.checksum());
    }
}

test "BLUE observer axis mapping follows XOR slot then modulo-three class" {
    for (0..8) |observer| {
        for (1..8) |direction| {
            const expected: u8 = @intCast((direction ^ observer) % 3);
            try std.testing.expectEqual(expected, observedAxis(@intCast(direction), @intCast(observer)));
        }
    }
}
