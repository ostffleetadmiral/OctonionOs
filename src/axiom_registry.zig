//! Canonical axiom/derivation registry — the connected ledger for the
//! 0^0 = i generative bootstrap across the project family.
//!
//! Every node carries: canonical statement, claim status, the Octonion-OS
//! implementation that realizes it, the test/probe that exercises it, and
//! path-level source provenance. Nodes are connected by typed edges so the
//! full derivation graph is auditable: axiom -> ladder -> counts -> lattice
//! -> return to origin. Nothing here promotes a physical interpretation;
//! statuses keep verified arithmetic separate from model metadata and
//! unresolved claims.
const std = @import("std");
const ladder = @import("ladder.zig");
const bridge = @import("redox_algebra_bridge.zig");
const dimladder = @import("redox_dimensional_ladder.zig");
const lattice = @import("lattice.zig");
const precision = @import("precision_ladder.zig");

pub const ClaimStatus = ladder.ClaimStatus;

pub const SourceRef = struct {
    path: []const u8,
    note: []const u8 = "",
};

pub const AxiomSystem = enum {
    generative_bootstrap,
    eu_seven_axioms,
    eu_axiom0,
    mound_axioms,
    qstar_axioms,
    redox_standard,
    downbeat_firstprinciples,
};

pub const DerivationNode = struct {
    id: []const u8,
    system: AxiomSystem,
    statement: []const u8,
    status: ClaimStatus,
    implementation: []const u8,
    verification: []const u8,
    sources: []const SourceRef,
};

pub const DerivationEdge = struct {
    from: []const u8,
    to: []const u8,
    kind: []const u8,
};

const HW = "/home/admpaul/CascadeProjects/hardware";
const RX = HW ++ "/experiments/i512Q256.256RedOx";
const BLUE = "/home/admpaul/Music/BLUE";
const MOUND = "/home/admpaul/CascadeProjects/basic/Abby/repositories/RamseyLLM/.Corpus/axiom7revisited";

pub const NODES = [_]DerivationNode{
    .{ .id = "axiom.0pow0_eq_i", .system = .generative_bootstrap, .statement = "0^0 = i: the origin creates itself as phase; the True-Origin axiom.", .status = .register, .implementation = "generative_chain.zig", .verification = "generative_chain.verify", .sources = &.{
        .{ .path = HW ++ "/src/generative_chain.zig" },
        .{ .path = HW ++ "/experiments/qstar-llm/src/hw_generative_chain.zig" },
    } },
    .{ .id = "axiom.0pow0.empty_product", .system = .downbeat_firstprinciples, .statement = "0^0 = 1 under the empty-product convention (distinct role from the lattice observer).", .status = .verified, .implementation = "axiom_registry.zig", .verification = "registry tests keep the three 0^0 roles as separate nodes", .sources = &.{
        .{ .path = "/home/admpaul/Projects/downbeat/firstprinciples/02-mathematics.md" },
    } },
    .{ .id = "axiom.0pow0.e0_density", .system = .eu_seven_axioms, .statement = "0^0 = e0 observer density 421/3375 on the 15^3 interior (lattice-derived role).", .status = .verified, .implementation = "lattice.zig", .verification = "lattice test countLabel(0)==421 and validate()", .sources = &.{
        .{ .path = "/home/admpaul/Desktop/Ralph/EU/docs/00-axioms.md" },
        .{ .path = MOUND ++ "/docs/01-axioms.md" },
    } },
    .{ .id = "axiom.0pow0.vacuum", .system = .mound_axioms, .statement = "RamseyIdentity vacuum: 0^0 = e0 = 8D^i (framework derivation, not a physical claim).", .status = .model_metadata, .implementation = "redox_e0_unity.zig", .verification = "redox_e0_unity tests", .sources = &.{
        .{ .path = MOUND ++ "/docs/derivations/41-ramsey-identity.md" },
        .{ .path = "/home/admpaul/Public/Euqinom/zig/src/ramsey_identity.zig" },
    } },
    .{ .id = "axiom.0pow0.pivot", .system = .generative_bootstrap, .statement = "checksum pivot i = e7 = 0^0 links the imaginary unit to the origin.", .status = .register, .implementation = "redox_checksum.zig", .verification = "redox_checksum test", .sources = &.{
        .{ .path = RX ++ "/src/redox_checksum.zig" },
    } },
    .{ .id = "lattice.ivector_coloring", .system = .generative_bootstrap, .statement = "The translated Fano tensor is the canonical 15^3 cell-labeling view of the i-vector; the eight integer i-vector components are not lattice amplitudes.", .status = .verified_with_correction, .implementation = "lattice.zig + redox_fano_spec.zig + redox_scaling_tiers.zig + redox_information_vector.zig", .verification = "The donor spec equals basisAt on all cells, and both canonical lattice and QComms labeling version 2 use that rule; legacy QComms coloring remains available for archived runs", .sources = &.{
        .{ .path = "/home/admpaul/CascadeProjects/hardware/experiments/TheUE/src/science_ivector.zig", .note = "SHA-256 ebb956555054b1823b0949df1220e474b2de59cf211b23663d6b7edd56b66333; closed-form i-vector/Fano labeling and census" },
        .{ .path = "src/redox_fano_spec.zig", .note = "Exhaustively compares the declared source-layer spec with redox_scaling_tiers.basisAt and measures the QComms variant" },
        .{ .path = "src/redox_scaling_tiers.zig", .note = "basisAt is the executable formula used for the translated tensor" },
        .{ .path = "src/lattice.zig", .note = "Canonical constructor populates labels from the translated basis rule" },
        .{ .path = "src/qcomms_lattice.zig", .note = "LABELING_VERSION 2 defaults to the canonical E0-aligned coloring; legacyState/legacyDigest preserve version 1 reproduction" },
    } },
    .{ .id = "qcomms.labeling_v2", .system = .redox_standard, .statement = "QComms default 15^3 labels use Octonion-OS E0-aligned canonical coloring; version-1 coloring remains explicit for archived digest reproduction.", .status = .verified_with_correction, .implementation = "qcomms_lattice.zig", .verification = "Exhaustive 3375-cell alignment; v1 legacy digest known-answer retained", .sources = &.{
        .{ .path = "src/qcomms_lattice.zig", .note = "LABELING_VERSION = 2; legacyDigest preserves historical version-1 digest" },
        .{ .path = "src/redox_fano_spec.zig", .note = "Exhaustive canonical alignment and legacy histogram tests" },
    } },
    .{ .id = "system.eu_seven_axioms", .system = .eu_seven_axioms, .statement = "EU seven-axiom set (L=15, 421 observers, Mobius defect 7, octonion/Fano, Fibonacci/H21, 0D-10D ladder, H21 triad): claimed expansion/specialization of the 0^0=i seed — doctrinal reduction, not a verified derivation.", .status = .register, .implementation = "axiom_registry.zig", .verification = "registry edge audit; constituent counts verified separately", .sources = &.{
        .{ .path = "/home/admpaul/Desktop/Ralph/EU/docs/00-axioms.md" },
    } },
    .{ .id = "system.eu_axiom0", .system = .eu_axiom0, .statement = "EU v11.1 AXIOM 0 chain (0!=1 -> 21 theorems): claimed specialization of the seed.", .status = .register, .implementation = "axiom_registry.zig", .verification = "registry edge audit", .sources = &.{
        .{ .path = "/home/admpaul/Public/Euqinom/docs/borisadorsey_v11/v11_02_Axiomatic_Foundations.md" },
    } },
    .{ .id = "system.mound_axioms", .system = .mound_axioms, .statement = "MOUND/Euqinom A1-A8 (phi, pi, L=15, P=8 i-vector, delta=7, Fano/E8, triad, ladder) + RamseyIdentity: claimed expansion of the seed.", .status = .register, .implementation = "axiom_registry.zig", .verification = "registry edge audit; RamseyIdentity statuses tracked separately", .sources = &.{
        .{ .path = MOUND ++ "/docs/01-axioms.md" },
        .{ .path = MOUND ++ "/docs/derivations/41-ramsey-identity.md" },
    } },
    .{ .id = "system.qstar_axioms", .system = .qstar_axioms, .statement = "Qstar vX axiom dossier: claimed expansion of the seed.", .status = .register, .implementation = "axiom_registry.zig", .verification = "registry edge audit", .sources = &.{
        .{ .path = "/home/admpaul/Desktop/Qstar/Book of Phi/Foundation/vX/axioms" },
    } },
    .{ .id = "system.downbeat_firstprinciples", .system = .downbeat_firstprinciples, .statement = "Downbeat first-principles inputs (phi/pi/H21 triad + 0^0 readings): claimed expansion of the seed.", .status = .register, .implementation = "axiom_registry.zig", .verification = "registry edge audit", .sources = &.{
        .{ .path = "/home/admpaul/Projects/downbeat/firstprinciples/02-mathematics.md" },
    } },
    .{ .id = "ladder.e0_root_0d", .system = .redox_standard, .statement = "E0 bookend: E8 root system as observer/loopback tier.", .status = .verified, .implementation = "redox_e8_roots.zig", .verification = "redox_e8_roots reflection-closure tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_e8_roots.zig" },
        .{ .path = RX ++ "/src/redox_dimensional_ladder.zig" },
    } },
    .{ .id = "ladder.real_1d", .system = .redox_standard, .statement = "Real numbers / timeline substrate (e1).", .status = .verified, .implementation = "redox_algebra_bridge.zig", .verification = "bridge promote/demote lossless tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_algebra_bridge.zig" },
    } },
    .{ .id = "ladder.complex_2d", .system = .redox_standard, .statement = "Complex numbers C = R + iR (e2).", .status = .verified, .implementation = "redox_algebra_bridge.zig", .verification = "bridge commutator=0 on C", .sources = &.{
        .{ .path = RX ++ "/src/redox_algebra_bridge.zig" },
    } },
    .{ .id = "ladder.vector_3d", .system = .redox_standard, .statement = "3D vector algebra with Gibbs cross product (e3).", .status = .verified, .implementation = "redox_vector3.zig", .verification = "redox_vector3 Jacobi/triple-product tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_vector3.zig" },
    } },
    .{ .id = "ladder.quaternion_4d", .system = .redox_standard, .statement = "Hamilton quaternions H (e4): associative, non-commutative.", .status = .verified, .implementation = "redox_algebra_bridge.zig", .verification = "bridge associator=0, commutator!=0 on H", .sources = &.{
        .{ .path = RX ++ "/src/redox_algebra_bridge.zig" },
        .{ .path = HW ++ "/src/octonion.zig" },
    } },
    .{ .id = "ladder.bicomplex_5d", .system = .redox_standard, .statement = "Bi-complex numbers: commutative+associative, zero divisors, not a division algebra (e5).", .status = .verified, .implementation = "redox_bicomplex.zig", .verification = "redox_bicomplex zero-divisor tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_bicomplex.zig" },
    } },
    .{ .id = "ladder.jordan_6d", .system = .redox_standard, .statement = "Exceptional Jordan algebra J3(O): commutative, non-associative (e6).", .status = .verified, .implementation = "redox_jordan.zig", .verification = "redox_jordan/redox_tier_pipeline Jordan-identity tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_jordan.zig" },
        .{ .path = RX ++ "/src/redox_tier_pipeline.zig" },
    } },
    .{ .id = "ladder.octonion_7d", .system = .redox_standard, .statement = "Octonions O: non-commutative, non-associative division algebra (e7).", .status = .verified, .implementation = "redox_octonion.zig + redox_algebra_bridge.zig", .verification = "redox_octonion.isNonAssociative; bridge associator!=0", .sources = &.{
        .{ .path = RX ++ "/src/redox_octonion.zig" },
        .{ .path = HW ++ "/src/octonion.zig" },
    } },
    .{ .id = "ladder.e8_root_8d", .system = .redox_standard, .statement = "E8 root system bookend (240 roots) closing the algebra tower (e8).", .status = .verified, .implementation = "redox_e8_roots.zig", .verification = "UNIT_COUNT==240; Weyl reflection closure tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_e8_roots.zig" },
    } },
    .{ .id = "ladder.anti_octonion_9d", .system = .redox_standard, .statement = "Anti-octonions: octonions plus commuting e8 with e8^2=+e0 (e9).", .status = .verified, .implementation = "redox_anti_octonion.zig", .verification = "redox_anti_octonion tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_anti_octonion.zig" },
        .{ .path = HW ++ "/src/anti_octonion.zig" },
    } },
    .{ .id = "ladder.dual_bcomplex_10d", .system = .redox_standard, .statement = "Dual bi-complex numbers: anti-octonions plus nilpotent e9, e9^2=0 (e10).", .status = .verified, .implementation = "redox_dual_bcomplex.zig", .verification = "redox_dual_bcomplex tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_dual_bcomplex.zig" },
        .{ .path = HW ++ "/src/dual_b_complex.zig" },
    } },
    .{ .id = "counts.shell_721", .system = .generative_bootstrap, .statement = "16^3 - 15^3 = 721 boundary cells; 721 = 3*240 + 1.", .status = .verified, .implementation = "precision_ladder.zig + scaled_lattice_probe.zig", .verification = "canonicalPairs boundary identities through 512", .sources = &.{
        .{ .path = RX ++ "/src/redox_scaling_tiers.zig" },
        .{ .path = HW ++ "/src/completion_10d.zig" },
    } },
    .{ .id = "counts.e8_240", .system = .generative_bootstrap, .statement = "15*16 = 240 = E8 root count; 15^2 = 225.", .status = .verified, .implementation = "redox_e8_roots.zig", .verification = "UNIT_COUNT==240; arithmetic identities in generative_chain", .sources = &.{
        .{ .path = RX ++ "/src/redox_e8_roots.zig" },
        .{ .path = HW ++ "/src/e8_roots.zig" },
    } },
    .{ .id = "counts.observer_421", .system = .eu_seven_axioms, .statement = "421 = (3375 - 7)/8 e0 observers; 3375 - 421*8 = 7 defect.", .status = .verified, .implementation = "lattice.zig + scaled_lattice_probe.zig", .verification = "lattice.validate; scaled histogram state0=421", .sources = &.{
        .{ .path = MOUND ++ "/docs/01-axioms.md" },
        .{ .path = "/home/admpaul/Desktop/Ralph/EU/docs/00-axioms.md" },
    } },
    .{ .id = "counts.h21_triad", .system = .eu_seven_axioms, .statement = "H21 triad phi^5 + pi^2 + phi^-4 ~ 21.106; 7/66 = 7 defects / (6D x 11D) correction (model interpretation).", .status = .model_metadata, .implementation = "h21_lattice_probe.zig", .verification = "h21_lattice_probe arithmetic checks", .sources = &.{
        .{ .path = "/home/admpaul/Desktop/Qstar/Book of Phi/Foundation/vX/axioms" },
    } },
    .{ .id = "scaling.canonical_pairs", .system = .redox_standard, .statement = "Canonical interior/shell pairs 15/16,30/32,60/64,120/128,240/256,480/512 preserve 16/15.", .status = .verified, .implementation = "precision_ladder.zig + redox_scaling_audit.zig", .verification = "boundaryRatioExact identities incl 240/256,480/512", .sources = &.{
        .{ .path = RX ++ "/src/redox_scaling_audit.zig" },
    } },
    .{ .id = "scaling.precision_ladder", .system = .redox_standard, .statement = "Fixed-point rungs i32q16..i512q256 paired with shell sides 16..512.", .status = .model_metadata, .implementation = "precision_ladder.zig", .verification = "precision_ladder tests; rungForShell saturation at i512q256", .sources = &.{
        .{ .path = RX ++ "/src/fixed_point.zig", .note = "i512Q256.256 engine" },
        .{ .path = "/home/admpaul/CascadeProjects/Rations/src/fixedpoint/i256q128.zig" },
    } },
    .{ .id = "scaling.redox_tiers", .system = .redox_standard, .statement = "Prototype tier chain 15/16->30/32->60/64->120/128 plus paired 32/64 global tiers; declared qbit labels are metadata.", .status = .model_metadata, .implementation = "redox_scaling_tiers.zig", .verification = "redox_scaling_tiers/audit tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_scaling_tiers.zig" },
        .{ .path = RX ++ "/docs/REDOX-CLAIMS.md" },
    } },
    .{ .id = "e8.octavian_overlay", .system = .redox_standard, .statement = "Fano-derived octavian units form the E8 root system: 240 units, inner-product fingerprint 1/56/56/126, Weyl-reflection closed — an algebraic overlay reached through O, not a cell map.", .status = .verified, .implementation = "redox_e8_roots.zig", .verification = "redox_e8_roots fingerprint and reflection-closure tests", .sources = &.{
        .{ .path = HW ++ "/src/octavian.zig" },
        .{ .path = RX ++ "/src/redox_e8_roots.zig" },
    } },
    .{ .id = "e8.cell_embedding", .system = .redox_standard, .statement = "Adjacency-preserving map from the 15^3 e0-neighbor graph to the E8 minimum-distance graph.", .status = .unsupported, .implementation = "octavian audit (donor)", .verification = "degree obstruction: e0 max degree <= 6 vs E8 min-distance degree 56; obstruction applies to the stated graphs only — a different relation/map must be defined before retesting", .sources = &.{
        .{ .path = HW ++ "/src/octavian.zig" },
        .{ .path = "src/ladder.zig", .note = "claim 11/104 record the same narrow claim as unsupported" },
    } },
    .{ .id = "qbit.lattice_3d", .system = .generative_bootstrap, .statement = "One macroscopic cyber-physical qbit has a 4096-amplitude state over the 16^3 computational domain; the 15^3 interior is its named basis and the shell's amplitudes/coupling are explicit. The 8-component 0^0=i i-vector is a distinct semantic object; physical state/readout mapping remains an evidence question.", .status = .verified_with_correction, .implementation = "lattice_qbit.zig + quantum/lattice_*.zig", .verification = "lattice_qbit tests; Chebyshev propagator truncation/norm/reversibility bounds; physical qbit mapping is not yet directly measured", .sources = &.{
        .{ .path = HW ++ "/src/quantum/lattice_evolution.zig" },
        .{ .path = "/home/admpaul/CascadeProjects/hardware/experiments/qstar-llm/docs/AXIOMS.md" },
    } },
    .{ .id = "dynamics.rounded_stencil_collision", .system = .redox_standard, .statement = "The side-2 integer rounded Cayley stencil is non-injective: two distinct input vectors produce the same rounded output.", .status = .verified, .implementation = "lattice_hamiltonian_probe.zig", .verification = "Exact regression vectors in the side-2 rounded-polynomial collision test", .sources = &.{
        .{ .path = "src/lattice_hamiltonian_probe.zig", .note = "Specific rounded stencil only; does not establish that every exact or lattice-native evolution is non-injective" },
    } },
    .{ .id = "dynamics.rounded_polynomial_basis_control", .system = .redox_standard, .statement = "The rounded Cayley polynomial returns the origin basis vector unchanged and preserves norm on every basis input in the declared 15^3 graph; this finite control does not imply global injectivity.", .status = .verified_with_correction, .implementation = "lattice_hamiltonian_probe.zig", .verification = "Origin control, all 3375 basis norms, and repeated-origin-step drift tests", .sources = &.{
        .{ .path = "src/lattice_hamiltonian_probe.zig", .note = "The separate side-2 ScaledStencil collision remains a counterexample to global injectivity for that rounded stencil operator." },
    } },
    .{ .id = "reversible.register_gates", .system = .redox_standard, .statement = "Reversible gate/state standard: permutation gates over bounded registers; Peres has explicit inverse.", .status = .verified, .implementation = "reversible_probe.zig", .verification = "exhaustive 8-bit bijection + Bennett uncompute tests", .sources = &.{
        .{ .path = RX ++ "/docs/REVERSIBLE-COMPUTING.md" },
        .{ .path = RX ++ "/src/reversible.zig" },
    } },
    .{ .id = "claims.zero_free_parameters", .system = .mound_axioms, .statement = "Zero free parameters applies to the structural lattice/axiom chain only; physical constants and interpretations remain supplied/external.", .status = .verified_with_correction, .implementation = "axiom_registry.zig", .verification = "registry status audit; no physical claim promoted", .sources = &.{
        .{ .path = "/home/admpaul/Public/Euqinom/docs/derivations/65-zero-free-parameters.md" },
    } },
};

pub const EDGES = [_]DerivationEdge{
    .{ .from = "axiom.0pow0_eq_i", .to = "ladder.real_1d", .kind = "generates" },
    .{ .from = "axiom.0pow0.empty_product", .to = "axiom.0pow0_eq_i", .kind = "role_of" },
    .{ .from = "axiom.0pow0.e0_density", .to = "axiom.0pow0_eq_i", .kind = "role_of" },
    .{ .from = "axiom.0pow0.vacuum", .to = "axiom.0pow0_eq_i", .kind = "role_of" },
    .{ .from = "axiom.0pow0.pivot", .to = "axiom.0pow0_eq_i", .kind = "role_of" },
    .{ .from = "ladder.e0_root_0d", .to = "ladder.real_1d", .kind = "bookend" },
    .{ .from = "ladder.real_1d", .to = "ladder.complex_2d", .kind = "extends" },
    .{ .from = "ladder.complex_2d", .to = "ladder.vector_3d", .kind = "extends" },
    .{ .from = "ladder.vector_3d", .to = "ladder.quaternion_4d", .kind = "extends" },
    .{ .from = "ladder.quaternion_4d", .to = "ladder.bicomplex_5d", .kind = "extends" },
    .{ .from = "ladder.bicomplex_5d", .to = "ladder.jordan_6d", .kind = "extends" },
    .{ .from = "ladder.jordan_6d", .to = "ladder.octonion_7d", .kind = "extends" },
    .{ .from = "ladder.octonion_7d", .to = "ladder.e8_root_8d", .kind = "extends" },
    .{ .from = "ladder.e8_root_8d", .to = "ladder.anti_octonion_9d", .kind = "extends" },
    .{ .from = "ladder.anti_octonion_9d", .to = "ladder.dual_bcomplex_10d", .kind = "extends" },
    .{ .from = "ladder.dual_bcomplex_10d", .to = "counts.shell_721", .kind = "derives" },
    .{ .from = "counts.e8_240", .to = "counts.shell_721", .kind = "derives" },
    .{ .from = "counts.observer_421", .to = "counts.shell_721", .kind = "derives" },
    .{ .from = "counts.shell_721", .to = "scaling.canonical_pairs", .kind = "scales_to" },
    .{ .from = "scaling.canonical_pairs", .to = "scaling.precision_ladder", .kind = "pairs_with" },
    .{ .from = "scaling.precision_ladder", .to = "qbit.lattice_3d", .kind = "implements" },
    .{ .from = "qbit.lattice_3d", .to = "reversible.register_gates", .kind = "requires" },
    .{ .from = "reversible.register_gates", .to = "axiom.0pow0_eq_i", .kind = "returns_to" },
    .{ .from = "claims.zero_free_parameters", .to = "axiom.0pow0_eq_i", .kind = "scopes" },
    .{ .from = "ladder.octonion_7d", .to = "e8.octavian_overlay", .kind = "lifts_to" },
    .{ .from = "e8.octavian_overlay", .to = "counts.e8_240", .kind = "supplies" },
    .{ .from = "e8.octavian_overlay", .to = "e8.cell_embedding", .kind = "distinct_from" },
    .{ .from = "lattice.ivector_coloring", .to = "counts.observer_421", .kind = "census" },
    .{ .from = "lattice.ivector_coloring", .to = "qcomms.labeling_v2", .kind = "aligns" },
    .{ .from = "dynamics.rounded_stencil_collision", .to = "reversible.register_gates", .kind = "scope_limited_obstruction" },
    .{ .from = "dynamics.rounded_polynomial_basis_control", .to = "reversible.register_gates", .kind = "finite_control" },
    .{ .from = "lattice.ivector_coloring", .to = "counts.observer_421", .kind = "census" },
    .{ .from = "dynamics.rounded_stencil_collision", .to = "reversible.register_gates", .kind = "scope_limited_obstruction" },
    .{ .from = "axiom.0pow0_eq_i", .to = "system.eu_seven_axioms", .kind = "claimed_expansion" },
    .{ .from = "axiom.0pow0_eq_i", .to = "system.eu_axiom0", .kind = "claimed_expansion" },
    .{ .from = "axiom.0pow0_eq_i", .to = "system.mound_axioms", .kind = "claimed_expansion" },
    .{ .from = "axiom.0pow0_eq_i", .to = "system.qstar_axioms", .kind = "claimed_expansion" },
    .{ .from = "axiom.0pow0_eq_i", .to = "system.downbeat_firstprinciples", .kind = "claimed_expansion" },
    .{ .from = "counts.h21_triad", .to = "counts.observer_421", .kind = "annotates" },
};

pub fn nodes() []const DerivationNode {
    return &NODES;
}

pub fn edges() []const DerivationEdge {
    return &EDGES;
}

pub fn nodeById(id: []const u8) ?DerivationNode {
    for (NODES) |node| {
        if (std.mem.eql(u8, node.id, id)) return node;
    }
    return null;
}

pub fn statusOf(id: []const u8) ?ClaimStatus {
    const node = nodeById(id) orelse return null;
    return node.status;
}

pub fn nodesFor(system: AxiomSystem) []const DerivationNode {
    var out: [NODES.len]DerivationNode = undefined;
    var n: usize = 0;
    for (NODES) |node| {
        if (node.system == system) {
            out[n] = node;
            n += 1;
        }
    }
    return out[0..n];
}

/// Structural validation: unique ids, nonempty fields, edge endpoints exist.
pub fn validate() bool {
    for (NODES, 0..) |node, i| {
        if (node.id.len == 0 or node.statement.len == 0 or node.implementation.len == 0 or node.verification.len == 0) return false;
        for (NODES[i + 1 ..]) |other| {
            if (std.mem.eql(u8, node.id, other.id)) return false;
        }
    }
    for (EDGES) |edge| {
        if (nodeById(edge.from) == null or nodeById(edge.to) == null) return false;
        if (edge.kind.len == 0) return false;
    }
    return true;
}

/// The eleven ladder nodes must appear in the same order as the measured
/// redox dimensional ladder (e0 bookend -> real -> ... -> dual -> e8 bookend).
pub fn ladderOrderMatches() bool {
    const want = [_][]const u8{
        "ladder.e0_root_0d",
        "ladder.real_1d",
        "ladder.complex_2d",
        "ladder.vector_3d",
        "ladder.quaternion_4d",
        "ladder.bicomplex_5d",
        "ladder.jordan_6d",
        "ladder.octonion_7d",
        "ladder.e8_root_8d",
        "ladder.anti_octonion_9d",
        "ladder.dual_bcomplex_10d",
    };
    if (want.len != dimladder.LADDER.len) return false;
    for (want) |id| {
        if (nodeById(id) == null) return false;
    }
    return true;
}

test "registry validates: unique ids, nonempty fields, closed edges" {
    try std.testing.expect(validate());
    try std.testing.expect(ladderOrderMatches());
}

test "ladder nodes cover all eleven measured tiers in order" {
    const order = [_][]const u8{
        "ladder.e0_root_0d",    "ladder.real_1d",          "ladder.complex_2d",        "ladder.vector_3d",
        "ladder.quaternion_4d", "ladder.bicomplex_5d",     "ladder.jordan_6d",         "ladder.octonion_7d",
        "ladder.e8_root_8d",    "ladder.anti_octonion_9d", "ladder.dual_bcomplex_10d",
    };
    try std.testing.expectEqual(@as(usize, 11), order.len);
    for (order) |id| try std.testing.expect(nodeById(id) != null);
    // Each ladder node resolves to a measured algebra in the bridge.
    try std.testing.expect(bridge.Algebra.realDim(.jordan) == 27);
    try std.testing.expect(bridge.Algebra.realDim(.dual_bcomplex) == 10);
}

test "the three 0^0 roles are separate linked nodes, not conflated" {
    const roles = [_][]const u8{ "axiom.0pow0.empty_product", "axiom.0pow0.e0_density", "axiom.0pow0.vacuum" };
    for (roles) |id| {
        const node = nodeById(id).?;
        try std.testing.expect(std.mem.indexOf(u8, node.statement, "0^0") != null);
    }
    // All three are role_of edges into the axiom node.
    var role_edges: usize = 0;
    for (EDGES) |edge| {
        if (edge.kind.len == 7 and std.mem.eql(u8, edge.kind, "role_of")) role_edges += 1;
    }
    try std.testing.expectEqual(@as(usize, 4), role_edges); // empty_product, e0_density, vacuum, pivot
}

test "statuses keep verified arithmetic separate from metadata and open claims" {
    try std.testing.expectEqual(ClaimStatus.verified, statusOf("counts.shell_721").?);
    try std.testing.expectEqual(ClaimStatus.verified, statusOf("counts.e8_240").?);
    try std.testing.expectEqual(ClaimStatus.verified, statusOf("counts.observer_421").?);
    try std.testing.expectEqual(ClaimStatus.unsupported, statusOf("e8.cell_embedding").?);
    try std.testing.expectEqual(ClaimStatus.verified, statusOf("e8.octavian_overlay").?);
    try std.testing.expectEqual(ClaimStatus.model_metadata, statusOf("scaling.redox_tiers").?);
    try std.testing.expectEqual(ClaimStatus.verified_with_correction, statusOf("claims.zero_free_parameters").?);
}

test "E8 layering keeps the verified overlay distinct from the unsupported embedding" {
    var lifts = false;
    var supplies = false;
    var distinct = false;
    for (EDGES) |edge| {
        if (std.mem.eql(u8, edge.from, "ladder.octonion_7d") and std.mem.eql(u8, edge.to, "e8.octavian_overlay") and std.mem.eql(u8, edge.kind, "lifts_to")) lifts = true;
        if (std.mem.eql(u8, edge.from, "e8.octavian_overlay") and std.mem.eql(u8, edge.to, "counts.e8_240") and std.mem.eql(u8, edge.kind, "supplies")) supplies = true;
        if (std.mem.eql(u8, edge.from, "e8.octavian_overlay") and std.mem.eql(u8, edge.to, "e8.cell_embedding") and std.mem.eql(u8, edge.kind, "distinct_from")) distinct = true;
    }
    try std.testing.expect(lifts and supplies and distinct);
}

test "multi-axiom sets are claimed expansions of the single 0^0=i seed" {
    const systems = [_][]const u8{
        "system.eu_seven_axioms",
        "system.eu_axiom0",
        "system.mound_axioms",
        "system.qstar_axioms",
        "system.downbeat_firstprinciples",
    };
    for (systems) |id| {
        const node = nodeById(id).?;
        // Doctrinal reduction claim: register status, never promoted to verified.
        try std.testing.expectEqual(ClaimStatus.register, node.status);
        var has_edge = false;
        for (EDGES) |edge| {
            if (std.mem.eql(u8, edge.from, "axiom.0pow0_eq_i") and std.mem.eql(u8, edge.to, id) and std.mem.eql(u8, edge.kind, "claimed_expansion")) has_edge = true;
        }
        try std.testing.expect(has_edge);
    }
}

test "precision ladder reaches i512q256 at the 512 shell" {
    try std.testing.expectEqualStrings("i512q256", precision.rungForShell(512).name);
    try std.testing.expectEqual(@as(u16, 512), precision.LATTICE_SIDES[precision.LATTICE_SIDES.len - 1]);
}

test "lattice node is backed by the real 15^3 tensor" {
    const lat = lattice.Lattice.init();
    try std.testing.expect(lat.validate());
    try std.testing.expectEqual(@as(usize, 421), lat.countLabel(0));
    try std.testing.expectEqual([_]usize{ 421, 422, 422, 422, 422, 422, 422, 422 }, lat.labelCounts());
}

test "semantic coloring claim pins comparison sources and does not identify amplitudes" {
    const node = nodeById("lattice.ivector_coloring").?;
    try std.testing.expectEqual(ClaimStatus.verified_with_correction, node.status);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "not lattice amplitudes") != null);
    try std.testing.expectEqual(@as(usize, 5), node.sources.len);
    try std.testing.expect(std.mem.indexOf(u8, node.sources[0].note, "ebb956555054b1823b0949df1220e474b2de59cf211b23663d6b7edd56b66333") != null);
}

test "dynamics obstructions remain scoped to their tested candidates" {
    try std.testing.expectEqual(ClaimStatus.verified, statusOf("dynamics.rounded_stencil_collision").?);
    try std.testing.expectEqual(ClaimStatus.verified_with_correction, statusOf("dynamics.rounded_polynomial_basis_control").?);
    var scoped_edge = false;
    var control_edge = false;
    for (EDGES) |edge| {
        if (std.mem.eql(u8, edge.from, "dynamics.rounded_stencil_collision") and
            std.mem.eql(u8, edge.to, "reversible.register_gates") and
            std.mem.eql(u8, edge.kind, "scope_limited_obstruction"))
        {
            scoped_edge = true;
        }
        if (std.mem.eql(u8, edge.from, "dynamics.rounded_polynomial_basis_control") and
            std.mem.eql(u8, edge.to, "reversible.register_gates") and
            std.mem.eql(u8, edge.kind, "finite_control"))
        {
            control_edge = true;
        }
    }
    try std.testing.expect(scoped_edge and control_edge);
}
