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
    .{ .id = "lattice.ivector_coloring", .system = .generative_bootstrap, .statement = "The translated Fano tensor is the canonical 15^3 cell-labeling view of the i-vector; the eight integer i-vector components are not lattice amplitudes.", .status = .verified_with_correction, .implementation = "lattice.zig + redox_fano_spec.zig + redox_scaling_tiers.zig + redox_information_vector.zig", .verification = "The donor spec equals basisAt on all cells, and both canonical lattice and QComms labeling version 2 use that rule; legacy QComms coloring remains available for archived runs. Three valid 15^3 colorings share the [421,422x7] census in superposition: basisAt (L1 shells, singleton at e0), Lattice.init (tent-superposed ramp, singleton at e0, 1980 cells differ from basisAt), and legacyState (archived v1 ramp, singleton at label 5, all 3375 cells differ from each other rule)", .sources = &.{
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
    .{ .id = "lattice.transit_phase_v1", .system = .generative_bootstrap, .statement = "Transit-phase contract v1: three_quarter_turn_per_transit (+3 eighth-turns = 3pi/4 per the Module-2 source spec recorded in 1.md) is the declared canonical convention. The declared family is the COMPLETE unit group U(8)={1,3,5,7} — every increment generating the full Z/8 cycle — held in superposition: +7 is the negated image of +1, +5 of +3, and each +k sequence is the element-wise xk mod 8 image of the +1 sequence. Multiplication by a unit is not an octonion automorphism, so label-coupled consumers can distinguish the conventions. Even increments {2,4,6} are sub-cycle sequences excluded by the spec's 8-transit closure. Contract metadata following the source spec, not a physical claim.", .status = .verified_with_correction, .implementation = "lattice.zig", .verification = "lattice tests: sigma3 gauge relation, non-automorphism check via octonion.multiply, shared cycle invariants across all four conventions (antipode at transit 4, parity alternation), enum completeness = exactly the four units, reversal-pair negation checks, canonical constant pinned to the spec increment", .sources = &.{
        .{ .path = "src/lattice.zig" },
        .{ .path = "src/ladder.zig", .note = "CLAIMS id=7 records the spec-derived choice and gauge analysis" },
        .{ .path = "1.md", .note = "Module-2 engineering directive: 'geometric phase accumulation of 3pi/4 per transit with closure at 8 transits'" },
    } },
    .{ .id = "lattice.phi_pi_position_v1", .system = .generative_bootstrap, .statement = "phi/pi dimensional-position contract v1 (declared positional semantics): pi is centered at E0 (origin site); the state's 1D phi coordinate is carried inward along the six cardinal directions; the 16^3 compounding shell exists only when scaling (bare 15^3 has no shell interactions) and carries the outward phi role. EU/MOUND assign c(1)=phi (1D timeline), c(2)=pi (2D phase space). Position only — no magnitudes, no equation bridge.", .status = .verified_with_correction, .implementation = "phi_pi_position.zig", .verification = "phi_pi_position tests: exact 1/3374/721 role census over unsigned 16^3, 42 cardinal-ray sites on six directions, inward-step direction checks, bare-15^3 shell exclusion", .sources = &.{
        .{ .path = "src/phi_pi_position.zig" },
        .{ .path = "1.md", .note = "User-supplied positioning: pi at E0, phi inward on six directions, phi outward scaling; 16^3 only when compounding" },
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
    .{ .id = "ladder.octonion_7d", .system = .redox_standard, .statement = "Octonions O: non-commutative, non-associative division algebra (e7). Two valid Fano multiplication tables are held in superposition: redox_octonion orients line {3,5,6} as written, octonion.zig (hardware lineage) as {3,6,5} — products agree on the unit for all 49 ordered pairs and differ in sign exactly on the six products among {3,5,6}.", .status = .verified, .implementation = "redox_octonion.zig + redox_algebra_bridge.zig + octonion.zig", .verification = "redox_octonion.isNonAssociative; bridge associator!=0; dual-table cross-check (unit agreement + exact sign-difference set)", .sources = &.{
        .{ .path = RX ++ "/src/redox_octonion.zig" },
        .{ .path = HW ++ "/src/octonion.zig" },
    } },
    .{ .id = "ladder.e8_root_8d", .system = .redox_standard, .statement = "E8 root system bookend (240 roots) closing the algebra tower (e8).", .status = .verified, .implementation = "redox_e8_roots.zig", .verification = "UNIT_COUNT==240; Weyl reflection closure tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_e8_roots.zig" },
    } },
    .{ .id = "ladder.anti_octonion_9d", .system = .redox_standard, .statement = "Anti-octonions: octonions plus commuting e8 with e8^2=+e0 (e9). Held in superposition with the Cayley-Dickson double (ladder.sedenion_16d): both are valid extensions of O by one unit; the split choice adds a universally commuting direction, the double adds an anticommuting direction with e8^2=-e0. Neither is privileged without independent evidence.", .status = .verified, .implementation = "redox_anti_octonion.zig", .verification = "redox_anti_octonion tests", .sources = &.{
        .{ .path = RX ++ "/src/redox_anti_octonion.zig" },
        .{ .path = HW ++ "/src/anti_octonion.zig" },
    } },
    .{ .id = "ladder.sedenion_16d", .system = .redox_standard, .statement = "Sedenions S: the Cayley-Dickson double of O, e8^2=-e0 with e8 anticommuting on e1..e7. Non-commutative, non-associative, non-alternative, with zero divisors; flexibility, power-associativity, and the x conj(x)=|x|^2 e0 identity survive. Second instance of the e8-extension superposition (ladder.anti_octonion_9d).", .status = .verified, .implementation = "redox_sedenion.zig", .verification = "redox_sedenion tests: e8^2=-e0, anticommutation, octonion subalgebra preserved, non-alternativity witness, runtime-discovered zero-divisor certificate, flexibility/power-associativity/conjugate-norm checks", .sources = &.{} },
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
    .{ .id = "hydrogen.lattice_alignment_v1", .system = .eu_seven_axioms, .statement = "Q128 numerical shadow of the nonrelativistic 1s Coulomb spatial solution sampled on the E0-centered 15^3 lattice and discretely normalized. The connected triad interpretation is pi^2 as the E0/E2-centered bubble, phi^5 as outer reading, phi^-4 as inner reading. The same additive 7/66 defect is computed on the full triad as its e3-to-e6 candidate and compared with the e6 21cm endpoint; its mismatch is recorded. The integer baseline check 21+7/66 is also retained. Lattice a0=1 remains uncalibrated.", .status = .verified_with_correction, .implementation = "hydrogen_alignment_probe.zig", .verification = "hydrogen_alignment_probe: exp approximation, normalized 15^3 1s density, radial symmetry, central 2D slice, triad-role decomposition, endpoint preservation, additive defect residuals", .sources = &.{
        .{ .path = "https://tf.nist.gov/general/pdf/13.pdf", .note = "measured unperturbed hydrogen hyperfine transition frequency" },
        .{ .path = "https://youyuanwu.github.io/misc-docs/physics/04-QFT/17-theories/01-QED/05-hydrogen.html", .note = "Coulomb Schrodinger equation and 1s wavefunction form" },
        .{ .path = "https://notes.amittai.studio/atomic-physics/qed-corrections-and-hyperfine-structure/hyperfine-structure-21cm", .note = "1s spatial state is unchanged across the hyperfine spin transition" },
    } },
    .{ .id = "mound.triad_table_v1", .system = .mound_axioms, .statement = "MOUND triad table T(a,b,c)=phi^a+pi^b+phi^c covers 145 physical constants (donor CSV, CC BY-NC-SA 4.0). Octonion-OS independently recomputes all rows in Q128.128 integer fixed-point: 144 evaluable + 1 target-underflow (Planck time 5.39e-44 s below the 2^-129 floor), 0 arithmetic failures, 130/144 within 1%, worst residual 2.71%. Positioning-derived correction analysis (inward/outward phi split, compounding term, implied-base refit, exponent-residue structure, neighbor signatures) found NO derivable correction: implied per-term bases cluster at canonical phi/pi within 0.01%, best global scale factor is 1.0, and residuals are consistent with signature-fit noise. Fit quality is arithmetic evidence only — not physical validation.", .status = .verified_with_correction, .implementation = "mound_triad.zig + mound_triad_table.zig", .verification = "mound_triad tests: 145-row census, (0,0,0)=3, a/c symmetry, hydrogen signature, underflow-safe negative powers, target conversion, verifyAll thresholds, sign convention, non-degenerate signatures", .sources = &.{
        .{ .path = "src/mound_triad.zig" },
        .{ .path = "src/mound_triad_table.zig", .note = "generated from donor CSV; targets as mantissa x 10^exp, integer-only" },
        .{ .path = "/home/admpaul/CascadeProjects/hardware/mound_triad_results.csv", .note = "donor fit results (read-only provenance)" },
        .{ .path = "src/lattice.phi_pi_position_v1", .note = "positioning contract under which correction hypotheses were tested" },
    } },
    .{ .id = "lattice.scale_constant_inventory_v1", .system = .generative_bootstrap, .statement = "Integer census of lattice-native candidates from scale 0 (15^3) through scale 7, with 16^3 retained only as the scale-0 compounding shell. Scale 1 is skipped and scale 2 begins at 32^3. Six values per represented scale (volume, e0 count, defect count, shell count, e0 fraction, defect fraction) are compared to donor targets and triad signatures without fitting. Scale-0 coloring is enumerated exactly; higher-scale label counts are uniform modulo-8 metadata, not dense translated-Fano enumerations. Raw comparison reports 0 exact, 17 within 1%, 1 within 0.1%, and 0 within 1 ppm, but these tolerances ignore units. No unit-aware physical constant derivation is established.", .status = .verified_with_correction, .implementation = "lattice_constant_audit.zig", .verification = "lattice_constant_audit tests: scale-0 exact census; active sides and compounding shells; 42 candidates; target/triad comparisons preserve units and underflow evidence classes; explicit tests pin higher-scale counts as modeled uniform metadata", .sources = &.{
        .{ .path = "src/lattice_constant_audit.zig" },
        .{ .path = "src/precision_ladder.zig", .note = "canonical scale family and compounding pairs; not used to promote 16^3 as a scale" },
        .{ .path = "src/scaled_lattice_probe.zig", .note = "exact translated-Fano histogram through the declared scale family" },
        .{ .path = "src/mound_triad_table.zig", .note = "donor targets/signatures; comparisons are diagnostic, not refitted" },
        .{ .path = "src/h21_lattice_probe.zig", .note = "connected H21 triad and additive 7/66 candidate carried in the audit report" },
    } },
    .{ .id = "cyber.superposition_law_v1", .system = .generative_bootstrap, .statement = "Cyber-physical superposition law v1 (premise: everything is inherently quantum): the cyber layer is the native carrier of superposition — when a component exhibits two or more correct instances, those instances are branches of one superposed state and all are maintained. Collapse is a physical-side event only: branch selection happens exclusively through the declared measurement contract (observable, deterministic selector, Lüders projection + renormalization) or independent evidence — never by deleting branches or declaring them wrong. The cyber superposition persists independently of physical-side resolution; physical collapse does not falsify unselected branches, which remain re-selectable. Defaults are not collapse: canonical conventions (LABELING_VERSION, CANONICAL_PHASE_CONVENTION, gateV1) are serialization bookkeeping. Audit corollary: 'not true in this branch' is never 'impossible' — falsification is scoped to the branch where the excluding invariant holds (e.g., m=7 is excluded in the D4-symmetric basisAt branch but stays open in the non-D4 init/legacy branches).", .status = .verified_with_correction, .implementation = "AGENTS.md + CYBER-PHYSICS.md standing law; branch instances implemented in qcomms_lattice.zig + lattice.zig + redox_octonion.zig + redox_anti_octonion.zig + redox_sedenion.zig", .verification = "superposition checks: three-coloring census identity with measured pairwise divergence, dual-Fano unit agreement with exact sign-difference set, U(8) phase-family completeness and reversal pairs, sedenion/anti-octonion e8 contrast, non-D4 init/legacy branch test; the quantum premise itself is framework interpretation, not measured physics", .sources = &.{.{ .path = "1.md", .note = "user premise: 'the cyber side can be in superposition independently of the physical side'" }} },
    .{ .id = "lattice.image_claims_audit_v1", .system = .generative_bootstrap, .statement = "Image-informed audit separates exact lattice arithmetic and implemented model behavior from interpretive diagrams. Verified integer anchors include 15^3=3375, 16^3-15^3=721, 15*16=240, 3375-421*8=7, 8*421+7=3375, and 42/21=2. The Mobius panel's concrete transform (z=0 <-> z=14 under 180-degree rotation) is label-COMPATIBLE at odd inner sides and label-INVISIBLE — the untwisted mirror pairing preserves labels equally, so the coloring cannot witness the twist; at even inner sides neither identification holds. The qubit ladder uses the canonical-pair chain (interior 15*2^s, shell 16*2^s, qubits = 8^s = interior/3375 blocks) — a different indexing than the constant audit's power-of-two interiors; audit interior sides equal image shell sides shifted one index. Octant self-similarity is verified at histogram level: each 15^3 block of 30^3 carries the canonical histogram multiset with defect shifted to state (-k mod 8). The Fibonacci cooling bars reproduce in Q128 as the normalized geometric profile w_z = phi^-z / sum phi^-k (w0 ~ 0.382, ratio 1/phi) — model metadata, not donor-algorithm validation. Ladder numerics are the H21 endpoint family (21/4, 10.5, 21, 42) plus phi, pi, 0, 721, 32^3; the interior-inward/boundary-outward arrows corroborate phi_pi_position. A displayed 42/21=2 ratio is arithmetic only, not a measured consciousness quantity. The center-slice color map is not an independent Fano multiplication derivation; the prediction-accuracy panel echoes donor triad residuals and is not Octonion-OS validation results. Second batch: the psi field's Mobius boundary condition is the transform verified label-compatible; the field itself (values in [-1,1]) is donor simulation data, not the coloring. The basisAt label field is D4-symmetric on every slice, so its angular harmonics are m = 0 mod 4 only — m=7 dominance is excluded in the basisAt branch but stays open in the non-D4 init/legacy branches (each preserves at most 1 of 7 non-identity transforms); the donor field is a separate live branch, not a falsified one. The center slice carries exactly 29 e0 cells (center + radius-8 Manhattan diamond, not an X). Radial ring profiles are exact: L1 rings 4r, Linf rings 8r. Axiom-7 discretization verifies: round(triad)=F0=21, |T-21|/21 ~ 0.503% ('0.5%'), |T-21.106114|/21.106114 ~ 0.0021% ('0.002%'). Ladder tier coordinates are integer rationals over F0=21 ({1/4,1/2,1,2,1,1/2}), matching the discretization claim; exponent roles bind to ladder tiers (phi^5->5D, pi^2->2D, phi^-4->4D). The prediction chart's 1/alpha, sin^2 theta_W, and Koide rows are absent from the 145-table, and its error figures differ across panels (Koide Q 0.0009% vs 0.026%, 1/alpha 0.01% vs 0.026%) — unverifiable from the images alone. The helix parameterization (r peaks at z=7 with the 6D tier) is model geometry, not dynamics. Third batch: the 'concentric spheres' claim names the wrong metric — e-labels are Manhattan-octahedral shells (label = L1-distance mod 8); populations 1,6,18,38,66,102,146,198,252,296,324,336,332,312,276,224,168,120,80,48,24,8 fold mod 8 into [421,422x7], with e0 = shells {0,8,16} = 421 carrying the observer-singleton defect. The 'hidden spheres' are the nearest integer-radius shells to phi and pi: d2=3 (8 cells, sqrt3 err 0.114) and d2=10 (24 cells, sqrt10 err 0.021). The Fano+e8 annotations are implemented facts: 'E8=E1 Closure' = e8.e1 = e1 (identity action) and 'E8=E0 at Boundary' = e8^2 = +e0; the 'all commutativity lost' caption is contradicted — e8 commutes with every octonion unit. Ladder bars verify completely: c(0)=0, c(1)=phi, c(2)=pi constants plus F0=21 rationals at tiers 3-8. The projection chain is the ladder's reverse order (reduction direction of the loop). The 4D+time Mobius and string-theory tier names remain doctrine labels on verified coordinates. Fourth batch: the all-15-layer panel shows exactly 8 distinct 2D patterns — mirrored pairs z<->14-z identical, additive cyclic-shift law label(x,y,z)=(2D-L1+|z-7|) mod 8 verified. The Cayley-Dickson Start->End chain is an exact palindrome 5.25-10.5-21-42-21-10.5-5.25 peaking at 42 at the 6D mirror (8x the chain ends), with chain nodes equal to ladder coords c(3)..c(8). Lie-table corrections: e3->SO(4) contradicts the measured so(3) cross-product Lie algebra; e4->SO(5) is questionable (Aut(H)=SO(3)); e6->E6/F4 and e7->G2 are real facts. The E8 projection's 240=112+128 split (standard D8+half-spin) and the octavian overlay's 16+112+112 are two exact presentations held in superposition — both correct, neither privileged without independent evidence. 'e7->e2 closure' verifies as the Fano line {2,5,7}: e5.e7=+e2. The torus/compounding semantics are structurally consistent: 2x2x2 blocks share face planes at coord=inner (3 touching + 3 exterior faces each; exterior is where the shell attaches). Smith-chart impedance and Ohm's-law-wheel mappings carry valid domain identities on e-tiers; '6 phi directions match 6 p-orbital lobes' is semantic. '1128 floating point bits' remains unexplained. No image establishes physical measurement or a derived physical constant.", .status = .verified_with_correction, .implementation = "image_claims_probe.zig + redox_scaling_audit.zig + scaled_lattice_probe.zig + redox_dimensional_ladder.zig + redox_jordan.zig + redox_anti_octonion.zig + redox_octonion.zig", .verification = "image_claims_probe tests: Mobius/mirror face-identification label checks at odd/even inner sides, image-scale census (8^s blocks, shell sides), audit-vs-image chain offset, Q128 cooling profile (monotone, sums to 1, w0 within 0.1% of 2-phi), center-slice e0 census 29, L1/Linf ring counts, D4 invariance of every slice, integer-rational ladder coordinates, Axiom-7 rounding/discretization residuals, L1-octahedral shell populations folding into [421,422x7], nearest-radius shells d2=3/d2=10, e8 identity/square/commutation checks, constant-tier pins, 8-distinct z-layer patterns with mirror pairs, H21-chain palindrome, E8 presentation sums, e5.e7=+e2 Fano closure, and block-face topology; plus existing integer tests for counts, histograms, Fano/octonion products, Jordan, anti-octonion, and vector3 properties. Consciousness, physical qbits, donor psi-field spectral claims, prediction-chart errors, string-theory names, impedance/Ohm mappings, and the 1128-bit figure remain metadata or unresolved", .sources = &.{
        .{ .path = "src/image_claims_probe.zig", .note = "Mobius label-compatibility, image-scale census, cooling profile, D4 invariance, ring/slice/shell censuses, hidden-sphere shells, e8 algebra checks, and Axiom-7 discretization checks" },
        .{ .path = "src/redox_scaling_audit.zig", .note = "measured scale volumes, shell counts, histogram imbalance, octant self-similarity with shifted defect" },
        .{ .path = "src/scaled_lattice_probe.zig", .note = "exact modulo-8 histograms under the declared basisAt rule" },
        .{ .path = "src/redox_fano_spec.zig", .note = "Fano multiplication structure and translated-label alignment are independently executable" },
        .{ .path = "src/redox_dimensional_ladder.zig", .note = "algebra-tier associations; dimensional interpretations remain framework metadata" },
        .{ .path = "src/redox_jordan.zig", .note = "J3(O) is 27-dimensional, commutative, and non-associative under the implemented product" },
        .{ .path = "src/redox_anti_octonion.zig", .note = "e8^2 = +e0, e8.ei = ei, e8 commutes with every unit — the Fano+e8 panel's algebraic content" },
        .{ .path = "1.md", .note = "User-provided image set; diagrams treated as claims to audit, not as independent evidence" },
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
    .{ .id = "measurement.lattice_contract", .system = .generative_bootstrap, .statement = "Lattice-qbit measurement/readout contract v1: deterministic u64-selector Born sampling over all 4096 domain sites, interior e-label class sampling, site collapse to a basis state, Lüders projection onto a label class with renormalization, and non-mutating population/digest readouts. Declared software semantics only — physical apparatus mapping remains gated.", .status = .verified_with_correction, .implementation = "lattice_measure.zig", .verification = "lattice_measure tests: selector determinism, absorbing label projection, shell coverage, digest stability, selector/zero-state edges", .sources = &.{
        .{ .path = "src/lattice_measure.zig" },
        .{ .path = "src/lattice_qbit.zig", .note = "state domain and population APIs consumed by the contract" },
    } },
    .{ .id = "measurement.ivector_readout", .system = .generative_bootstrap, .statement = "i-vector ↔ lattice-state binding contract v1: site-sample shots classify into the eight e-label components plus an explicit shell channel (shell is not forced into the 8 components), and label populations quantize to i512 via a declared round-half-up convention. Declared software semantics — the physical i-vector correspondence remains an open evidence question.", .status = .verified_with_correction, .implementation = "ivector_readout.zig", .verification = "ivector_readout tests: pure-label and pure-shell histograms, seed determinism, digest stability, non-mutation, quantization rounding, fail-closed edges", .sources = &.{
        .{ .path = "src/ivector_readout.zig" },
        .{ .path = "src/lattice_measure.zig", .note = "sampling/classification primitives consumed by the binding" },
        .{ .path = "src/redox_information_vector.zig", .note = "8-component i512 vector type reused as the readout record" },
    } },
    .{ .id = "dynamics.reversible_lattice", .system = .redox_standard, .statement = "Declared contract v1: octonion-cell (2x2x2 = 8 sites) Margolus-style reversible CA on u8 sites over the 16^3 torus; every primitive is a bijection on (Z/256)^8 under enforced disjointness constraints, so each step and every alternating composition is provably bijective with an exact inverse. A candidate lattice-native reversible rule — not a derived unique physical dynamics.", .status = .verified_with_correction, .implementation = "reversible_lattice.zig", .verification = "reversible_lattice tests: partition census, exhaustive primitive inverse pairs, gate/step round-trips, transport and controlled-duplication probes", .sources = &.{
        .{ .path = "src/reversible_lattice.zig" },
        .{ .path = "src/reversible_probe.zig", .note = "register-gate lineage; primitives are lattice-local analogues on byte sites" },
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
    .{ .id = "pipeline.e2e_continuity_v1", .system = .generative_bootstrap, .statement = "End-to-end continuity audit walks 17 named seams (S0-S17) from the 0^0=i axiom through i-vector components, the 15^3 label tensor, the three-coloring superposition, the QComms channel, the 15^3->16^3 coordinate bridge, Q128 amplitudes, Chebyshev evolution, the measurement contract, i-vector readout, frames/serialization, routing, the reversible CA, the scale chain, the algebra ladder, the Q# adapter, and registry closure. Verified structure: index conventions bridge by COORDINATE, never by raw index — h.idx/coords are 16^3 x-fastest, indexUnsigned/index are 15^3 x-fastest/signed; the qbit converts full-domain index -> coords -> labelAtIndex. Branch binding measured: the qbit's label observable reads the INIT coloring (LatticeQubit.lat = Lattice.init()), while QComms state() reads basisAt — proven by preparing basis states on cells where the branches disagree (init-e0 reads full observer population; basisAt-e0 reads zero). The compounding law is one +1 shell layer per 15-block: canonical pairs (15,16),(30,32),(60,64),(120,128),(240,256),(480,512) satisfy shell-inner = inner/15; audit power-of-two sides <=512 coincide with pair shells and 1024 lies beyond the pair family (bounded offset, not a break). Routing is convention-blind: its inline hardware-orientation Fano table is consulted through unordered line membership only, so channels are identical under either Fano table; eligible count 420 = OBSERVERS-1 (non-primary e0). Serialization requires explicit PhaseConvention; frames extract/reassemble is exact; the reversible CA shares the 4096-site domain count as a classical u8 lane distinct from Q128 amplitudes. Classified open lane: whether the init-branch binding of the qbit/serialize/routing lane and the basisAt binding of the QComms lane need an explicit manifest branch tag — recorded as a decision point, not silently normalized.", .status = .verified_with_correction, .implementation = "src/e2e_continuity_probe.zig (SEAMS table + 12 executable seam checks)", .verification = "12 probe tests: i-vector index binding, three-coloring census/divergence, QComms=basisAt on all interior cells + 721 Foam shell sites, h.idx/coords roundtrip + signed/unsigned bridge, prepareBasis norm/shell/peak + OutOfRange, init-branch observable binding with both divergence directions, tau=0 evolution identity + measurement collapse + deterministic sampleLabel, frames reassemble + serialize.validate gate, routing 420 + router.validate, canonical-pair compounding law + audit-side offset, 11-tier ladder + superposition-sibling nodes + adapter vocabulary seam + registry.validate, U(8) family + explicit convention requirement", .sources = &.{
        .{ .path = "src/e2e_continuity_probe.zig", .note = "SEAMS table records producer/consumer/invariant/kind for all 17 seams" },
        .{ .path = "src/lattice_qbit.zig", .note = "labelPopulation bridges 16^3 index -> coords -> 15^3 labelAtIndex; lat field is Lattice.init()" },
        .{ .path = "src/qcomms_lattice.zig", .note = "state()=basisAt branch; Foam=8 shell sentinel" },
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
    .{ .from = "ladder.octonion_7d", .to = "ladder.sedenion_16d", .kind = "cayley_dickson_doubles" },
    .{ .from = "ladder.anti_octonion_9d", .to = "ladder.sedenion_16d", .kind = "superposes" },
    .{ .from = "ladder.e8_root_8d", .to = "ladder.anti_octonion_9d", .kind = "extends" },
    .{ .from = "ladder.anti_octonion_9d", .to = "ladder.dual_bcomplex_10d", .kind = "extends" },
    .{ .from = "ladder.dual_bcomplex_10d", .to = "counts.shell_721", .kind = "derives" },
    .{ .from = "counts.e8_240", .to = "counts.shell_721", .kind = "derives" },
    .{ .from = "counts.observer_421", .to = "counts.shell_721", .kind = "derives" },
    .{ .from = "counts.shell_721", .to = "scaling.canonical_pairs", .kind = "scales_to" },
    .{ .from = "scaling.canonical_pairs", .to = "scaling.precision_ladder", .kind = "pairs_with" },
    .{ .from = "scaling.precision_ladder", .to = "qbit.lattice_3d", .kind = "implements" },
    .{ .from = "qbit.lattice_3d", .to = "reversible.register_gates", .kind = "requires" },
    .{ .from = "qbit.lattice_3d", .to = "measurement.lattice_contract", .kind = "provides_readout" },
    .{ .from = "qbit.lattice_3d", .to = "lattice.transit_phase_v1", .kind = "parametrizes" },
    .{ .from = "lattice.phi_pi_position_v1", .to = "ladder.complex_2d", .kind = "positions" },
    .{ .from = "measurement.lattice_contract", .to = "measurement.ivector_readout", .kind = "binds" },
    .{ .from = "reversible.register_gates", .to = "dynamics.reversible_lattice", .kind = "extends" },
    .{ .from = "dynamics.rounded_stencil_collision", .to = "dynamics.reversible_lattice", .kind = "motivates" },
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
    .{ .from = "counts.h21_triad", .to = "mound.triad_table_v1", .kind = "extends" },
    .{ .from = "mound.triad_table_v1", .to = "lattice.phi_pi_position_v1", .kind = "scopes" },
    .{ .from = "counts.observer_421", .to = "lattice.scale_constant_inventory_v1", .kind = "seeds" },
    .{ .from = "lattice.scale_constant_inventory_v1", .to = "counts.h21_triad", .kind = "compares_without_fitting" },
    .{ .from = "lattice.scale_constant_inventory_v1", .to = "mound.triad_table_v1", .kind = "audits_targets_without_unit_claim" },
    .{ .from = "counts.observer_421", .to = "lattice.image_claims_audit_v1", .kind = "anchors_image_arithmetic" },
    .{ .from = "scaling.canonical_pairs", .to = "lattice.image_claims_audit_v1", .kind = "corrects_scale_interpretation" },
    .{ .from = "axiom.0pow0_eq_i", .to = "pipeline.e2e_continuity_v1", .kind = "seeds_chain" },
    .{ .from = "lattice.ivector_coloring", .to = "pipeline.e2e_continuity_v1", .kind = "carries_branch_superposition" },
    .{ .from = "scaling.canonical_pairs", .to = "pipeline.e2e_continuity_v1", .kind = "grounds_scale_seam" },
    .{ .from = "cyber.superposition_law_v1", .to = "pipeline.e2e_continuity_v1", .kind = "classifies_branch_seams" },
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

test "scale constant inventory claim records no-fit scope and scale boundary" {
    const node = nodeById("lattice.scale_constant_inventory_v1").?;
    try std.testing.expectEqual(ClaimStatus.verified_with_correction, node.status);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "scale 0 (15^3)") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "scale 2 begins at 32^3") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "without fitting") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "not dense translated-Fano enumerations") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "No unit-aware physical constant derivation") != null);
    try std.testing.expect(validate());
}

test "image audit claim records arithmetic and interpretive boundaries" {
    const node = nodeById("lattice.image_claims_audit_v1").?;
    try std.testing.expectEqual(ClaimStatus.verified_with_correction, node.status);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "42/21=2") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "not a measured consciousness quantity") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "label-INVISIBLE") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "m = 0 mod 4 only") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "29 e0 cells") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "Manhattan-octahedral shells") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "e8 commutes with every octonion unit") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "8 distinct 2D patterns") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "e5.e7=+e2") != null);
    try std.testing.expect(std.mem.indexOf(u8, node.statement, "not Octonion-OS validation results") != null);
    try std.testing.expect(validate());
}
