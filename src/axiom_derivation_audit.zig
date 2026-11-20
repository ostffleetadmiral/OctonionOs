//! Per-axiom derivation audit — every axiom in the corpus, viewed as a
//! LOOP rather than a tree.
//!
//! The primitive reading treats `0^0 = i` as a root that everything
//! reduces down to. That is backwards. The framework's actual shape is
//! a loop:
//!
//!   * The i-vector `i = [e0^i, e1^i, ..., e7^i]` is PRIMAL — the
//!     8-component information/imaginary object. It is not derived;
//!     it is the thing.
//!   * `0^0 = i` is a FIXED POINT on the loop, not a root: the origin
//!     operation returns the full vector (self-reference — the quine
//!     law). Its executable shadows are the e0 multiplicative identity
//!     and the period-8 phase closure (`8^i = i`). The identification
//!     of the empty product with the vector is convention.
//!   * Euqinom AXIOM 0 (`0 != 1`) is the complementary shadow:
//!     distinction makes the 8 components countable.
//!   * MOUND's "0 free parameters" chain is a SECOND loop rooted in
//!     mathematical theorems (Hurwitz -> O -> E8 -> 240 -> L=15),
//!     parallel to — not derived from — the i-vector loop.
//!   * phi and pi are POSITION-DERIVED constants: the dimensional
//!     ladder assigns each e-slot a type — odd labels sit on spherical
//!     tiers (S^1,S^3,S^5,S^7 whose volumes are powers of pi) and the
//!     self-similar 15->16 scaling positions carry phi (phi^2=phi+1).
//!     The positioning rule is framework structure; pi's appearance is
//!     forced by spherical volumes, phi's by the self-similar ratio.
//!   * The checksum palindrome E=mc^2 <-> i <-> E=mc^-2 is centered
//!     on the i-vector — its pivot IS the 0^0=i fixed point.
//!
//! "i" is the i-vector — the 8-component structure — NOT the complex
//! imaginary unit. Every axiom below carries an EMERGENCE path (how
//! the i-vector/lattice generates it); reading the same path backward
//! is the reduction direction. A loop has no root, only a fixed point.
//!
//! Sources audited (read-only provenance):
//!   - hardware/src/generative_chain.zig          (bootstrap, sha 0fa81a16…)
//!   - Desktop/Ralph/EU/docs/derivations/01-axioms.md (EU A1–A7)
//!   - Desktop/Qstar/.../vX/axioms/               (same EU set)
//!   - Public/Euqinom/docs/borisadorsey_v11/      (AXM 1–7 = EU set)
//!   - Public/Euqinom/zig/src/*.zig + docs/concepts/ (AXIOM 0 chain)
//!   - axiom7revisited/docs/01-axioms.md + derivations/65 (MOUND A1–A8)
//!   - downbeat/firstprinciples/00-index.md       (phi/pi/H21 inputs)
//!   - axiom7revisited/docs/derivations/41-ramsey-identity.md
//!   - hardware/experiments/qstar-llm/docs/AXIOMS.md (impl axioms)
//!   - TheUE/ref/theconvo.md                      (conversation record)
const std = @import("std");
const ladder = @import("ladder.zig");
const lattice = @import("lattice.zig");
const gen = @import("generative_chain.zig");
const precision = @import("precision_ladder.zig");
const scaled = @import("scaled_lattice_probe.zig");
const redox_lattice = @import("qcomms_lattice.zig");
const redox_checksum = @import("redox_checksum.zig");

pub const ClaimStatus = ladder.ClaimStatus;

pub const StepStatus = enum { verified, definitional, gap };

pub const AuditStep = struct {
    id: []const u8,
    status: StepStatus,
    note: []const u8,
};

pub const AxiomAudit = struct {
    id: []const u8,
    systems: []const []const u8,
    statement: []const u8,
    /// Emergence path: i-vector/lattice outward to this axiom.
    /// Empty only for the primal object itself. Reduction is the same
    /// path traversed backward — the loop has no root.
    path: []const AuditStep,
    status: ClaimStatus,
    /// The honest remainder: what is NOT generated/verified.
    gap: []const u8,
    /// Versioned semantic mapping. Facts remain stable; interpretation can
    /// evolve without rewriting the evidence record.
    semantic_map: []const SemanticMapping = &.{},
    evidence: []const EvidenceRef = &.{},
};

pub const SemanticMapping = struct {
    version: []const u8,
    interpretation: []const u8,
    basis: []const u8,
    confidence: MappingConfidence,
};

pub const MappingConfidence = enum { arithmetic, structural, interpretive, speculative };

pub const EvidenceRef = struct {
    path: []const u8,
    sha256: []const u8,
    fact: []const u8,
    evidence_kind: EvidenceKind,
    semantic_target: []const u8,
};

pub const EvidenceKind = enum {
    exact_arithmetic,
    exhaustive_code_check,
    formal_theorem,
    implementation_contract,
    source_claim,
    semantic_correspondence,
    physical_hypothesis,
};

// -- Shared step descriptors (emergence direction: ivector outward) --
const PRIMAL: AuditStep = .{ .id = "ivector.primal", .status = .verified, .note = "i = [e0^i..e7^i], 8 components; represented by redox_information_vector.Vector.values[8]i512" };
const IVEC8: AuditStep = .{ .id = "ivector.eight_components", .status = .verified, .note = "8 components e0..e7; count matches AXIOM-0's 8 states and phase period 8" };
const A0: AuditStep = .{ .id = "euq.axiom0_states", .status = .verified, .note = "0!=1 -> {0,1} -> 2^3=8 states -> 7 nonzero, distinct (integer check below)" };
const FANO: AuditStep = .{ .id = "fano.pg2_2", .status = .verified, .note = "7 nonzero F2^3 vectors form PG(2,2): 7 lines, 3 pts/line, XOR closure (integer check below)" };
const OCT: AuditStep = .{ .id = "octonion.units", .status = .verified, .note = "Fano lines drive the octonion product table; non-associative (generative_chain.verify)" };
const E8OV: AuditStep = .{ .id = "e8.octavian_overlay", .status = .verified, .note = "Fano-derived octavian units form the 240-root E8 system (redox_e8_roots, overlay not cell map)" };
const L15: AuditStep = .{ .id = "lattice.l15", .status = .verified, .note = "15^3=3375 interior, 16^3=4096 shell, 421 e0, 721 foam (lattice.zig validate)" };
const COUNTS: AuditStep = .{ .id = "counts.identities", .status = .verified, .note = "721=3*240+1, 15*16=240, 15^2=225, 3375-421*8=7 (generative_chain.verify)" };
const PHASE8: AuditStep = .{ .id = "phase.period8", .status = .verified, .note = "both phase conventions close after exactly 8 transits (lattice.zig phase tests)" };
const E0ID: AuditStep = .{ .id = "e0.identity", .status = .verified, .note = "e0 is the multiplicative identity of the octonion algebra (generative_chain.verify)" };

pub const AUDIT = [_]AxiomAudit{
    // -- The primal object and the fixed point --
    .{ .id = "ivector.primal", .systems = &.{"all"}, .statement = "i = [e0^i, e1^i, ..., e7^i]: the 8-component information/imaginary vector — the primal object of the framework; every axiom is a view of its unfolding.", .path = &.{}, .status = .verified_with_correction, .gap = "8-component representation verified; component meanings and observer-shift dynamics are semantic model mappings, not consequences of the array type", .semantic_map = &.{
        .{ .version = "v1", .interpretation = "Eight named algebra components e0..e7.", .basis = "redox_information_vector.Component enum and Vector.values[8]i512; dimension and labels verified in code.", .confidence = .arithmetic },
        .{ .version = "v2", .interpretation = "A single information-vector object organizing the lattice/algebra ladder; its axioms are semantic views of this common structure.", .basis = "User's convergence method + donor mappings in science_ivector and RamseyIdentity; cross-project correspondence, not a theorem deriving every mapping.", .confidence = .structural },
        .{ .version = "v3", .interpretation = "The i-vector itself is superposed until measured; the cyber-physical qbit is its macroscopic lattice analogue, distinct from a conventional microscopic quantum bit.", .basis = "User's overarching inherently-quantum-universe premise and 0^0=i interpretation; software superposition/collapse exists, while the full i-vector/physical measurement map remains an open question.", .confidence = .interpretive },
    }, .evidence = &.{
        .{ .path = "src/redox_information_vector.zig", .sha256 = "local-tree-uncommitted", .fact = "Component enum has e0..e7; Vector.values is [8]i512.", .evidence_kind = .implementation_contract, .semantic_target = "eight-component i-vector representation" },
        .{ .path = "/home/admpaul/CascadeProjects/hardware/experiments/TheUE/src/science_ivector.zig", .sha256 = "ebb956555054b1823b0949df1220e474b2de59cf211b23663d6b7edd56b66333", .fact = "Closed-form cell labels, center seam, mirror folds, and 421 e0 census are checked.", .evidence_kind = .exhaustive_code_check, .semantic_target = "i-vector as lattice-wide labeling rule" },
        .{ .path = "/home/admpaul/Public/Euqinom/docs/concepts/21_ramsey_identity.md", .sha256 = "298b570a7a37edc93e429c17fba023b8293d7b31744698a106766b33f5e12830", .fact = "Defines i=[e0^i..e7^i] and records observer-shift/8D^i semantics.", .evidence_kind = .source_claim, .semantic_target = "observer and loopback meanings of components" },
    } },
    .{ .id = "fixedpoint.0pow0_eq_i", .systems = &.{ "Generative bootstrap", "TheUE", "BLUE/JIZO cyber-physical qbit" }, .statement = "0^0 = i: the origin operation returns the full i-vector as a fixed point on the loop; the framework interprets i as superposed until measured.", .path = &.{ PRIMAL, E0ID, PHASE8, .{ .id = "ivector.identification", .status = .definitional, .note = "the origin, e0 observer, checksum pivot, and full i-vector are identified by the framework's semantic mapping" }, .{ .id = "ivector.superposition_until_measurement", .status = .definitional, .note = "the user's inherently-quantum-universe premise assigns pre-measurement superposition to i; software collapse is implemented, while the full i-vector/physical measurement map remains open" } }, .status = .register, .gap = "checked arithmetic/algebra and separate physical transport/sensor records converge semantically; the calibrated mapping from the lattice/i-vector state to physical observables remains an open question, not a negative verdict", .semantic_map = &.{
        .{ .version = "v1", .interpretation = "The generative-chain seed, declared as 0^0=i.", .basis = "hardware generative_chain.zig explicitly accepts the seed by definition and checks downstream consistency.", .confidence = .structural },
        .{ .version = "v2", .interpretation = "The common semantic fixed point where independently checked lattice, algebra, and checksum facts are read as the origin/i-vector returning to itself.", .basis = "Cross-project convergence: verified integer identities and algebraic checks, linked by explicit semantic correspondence.", .confidence = .interpretive },
        .{ .version = "v3", .interpretation = "The i-vector remains in superposition until measured; cyber-physical qbit denotes its macroscopic lattice analogue, not a microscopic quantum bit.", .basis = "User's premise plus explicit framework interpretation; software superposition/collapse is verified in a separate state-vector model, while the full i-vector and physical measurement bridge remains open.", .confidence = .interpretive },
    }, .evidence = &.{
        .{ .path = "/home/admpaul/CascadeProjects/hardware/src/generative_chain.zig", .sha256 = "0fa81a16b7ea8cabf5405fe7b229edd59b5abef8459c7eba6d4a2743d59c82e5", .fact = "verifyChain accepts 0^0=i by definition, checks downstream algebra/counts, then closes at +1=0^0=i.", .evidence_kind = .implementation_contract, .semantic_target = "nontrivial bootstrap loop" },
        .{ .path = "/home/admpaul/CascadeProjects/hardware/experiments/TheUE/src/science_descent.zig", .sha256 = "685e01664ac42d4c36a400379c0ae04e106624c8ed230f3556b92cfd54ba20c9", .fact = "Layered tests recompute integer floor, lattice census, Fano completeness, and ladder contracts.", .evidence_kind = .exhaustive_code_check, .semantic_target = "independent verification paths" },
        .{ .path = "/home/admpaul/CascadeProjects/hardware/src/final_audit.zig", .sha256 = "faab7315c3c9ce26d84ac080c484ddcf67ab77bb3158af32d298c4224da592c8", .fact = "Separates exact arithmetic from interpretation, construction, numerology, and unverified claims.", .evidence_kind = .source_claim, .semantic_target = "evidence boundary for semantic convergence" },
    } },
    .{ .id = "fixedpoint.period8", .systems = &.{ "RamseyIdentity P-239", "EU A2" }, .statement = "Period-8 closure: 8^i = i / the phase cycle returns after 8 transits.", .path = &.{ PRIMAL, IVEC8, PHASE8 }, .status = .verified_with_correction, .gap = "period-8 closure verified as phase-cycle arithmetic; '8^i=i' as algebraic exponentiation is the framework reading" },
    .{ .id = "checksum.palindrome_i", .systems = &.{ "Generative bootstrap", "RamseyIdentity P-237", "Euqinom palindromic_conservation" }, .statement = "Checksum palindrome E=mc^2 <-> i <-> E=mc^-2 centered on the i-vector: the pivot is the framework's 0^0=i fixed point, interpreted as superposed until measurement.", .path = &.{ PRIMAL, .{ .id = "fixedpoint.0pow0_eq_i", .status = .definitional, .note = "the palindrome's middle slot is i; its origin/fixed-point interpretation is the semantic map" }, .{ .id = "checksum.algebraic_palindrome", .status = .verified, .note = "forward(m,c²)*inverse(m,c²)=m² and exponent cancellation are integer/algebraic checks" }, .{ .id = "checksum.physical_reading", .status = .gap, .note = "the E=mc² physical interpretation and 6D routing remain distinct from the algebra; a calibrated full-i-vector measurement map remains open" } }, .status = .verified_with_correction, .gap = "the checksum arithmetic is verified; its semantic identification with 0^0=i is a framework correspondence; physical measurement/readout of the superposed i-vector remains open", .semantic_map = &.{
        .{ .version = "v1", .interpretation = "Forward/inverse algebraic checksum: opposing powers cancel and preserve the mass-squared invariant.", .basis = "redox_checksum.zig and hardware checksum_6d.zig integer/algebraic checks.", .confidence = .arithmetic },
        .{ .version = "v2", .interpretation = "The i-vector is the midpoint/pivot of the forward and return paths; the origin fixed point is where the checksum closes.", .basis = "RamseyIdentity P-237 and hardware checksum_6d semantics, connected to the generative-chain return.", .confidence = .interpretive },
    }, .evidence = &.{
        .{ .path = "src/redox_checksum.zig", .sha256 = "local-tree-uncommitted", .fact = "Integer forward/inverse quantities multiply to mass squared for divisible inputs.", .evidence_kind = .exhaustive_code_check, .semantic_target = "algebraic checksum invariant" },
        .{ .path = "/home/admpaul/CascadeProjects/hardware/src/checksum_6d.zig", .sha256 = "9379367ce816945d68d8226f8c549af7eb7dc8e073e93a70c78f92d347d39039", .fact = "Defines the e7 pivot and checks opposing exponents, mass conservation, and Möbius self-inverse.", .evidence_kind = .implementation_contract, .semantic_target = "checksum pivot and return path" },
        .{ .path = "/home/admpaul/CascadeProjects/hardware/experiments/i512Q256.256RedOx/docs/REDOX-CLAIMS.md", .sha256 = "not-pinned", .fact = "Classifies checksum physics as rejected/inconsistent: an algebraic identity is not a derived physical law.", .evidence_kind = .source_claim, .semantic_target = "physical interpretation boundary" },
        .{ .path = "/home/admpaul/CascadeProjects/basic/Abby/repositories/RamseyLLM/.Corpus/axiom7revisited/docs/derivations/41-ramsey-identity.md", .sha256 = "c92db0978e5892ee0bbcaf718fb3bace9718b55d72b9de225b4426b7d974a53f", .fact = "P-237 expresses E=mc² ↔ i ↔ E=mc⁻² as a framework identity.", .evidence_kind = .source_claim, .semantic_target = "checksum palindrome semantic mapping" },
    } },
    .{ .id = "euq.axiom0_distinction", .systems = &.{"Euqinom v11.1"}, .statement = "AXIOM 0: 0 != 1 — the binary shadow of the fixed point: distinction makes the 8 components countable.", .path = &.{ PRIMAL, .{ .id = "distinction.0ne1", .status = .definitional, .note = "0 and 1 distinct is the postulate" }, A0, FANO }, .status = .verified_with_correction, .gap = "combinatorial facts verified; 'isomorphic to octonion units' is the interpretive bridge; 0!=1 and 0^0=i are complementary shadows of one fixed point, not rival seeds" },

    // -- EU A1-A7 (shared by Qstar vX, Euqinom v11), emergence direction --
    .{ .id = "eu.A1_l15", .systems = &.{ "EU A1", "Qstar vX", "Euqinom v11", "MOUND A3" }, .statement = "Lattice size L = 15 (15^3 interior, 16^3 shell).", .path = &.{ PRIMAL, OCT, E8OV, COUNTS, .{ .id = "l15.selection", .status = .definitional, .note = "L=15 enters via 15*16=240 and L(L+1)=240; the selection of 15 is the primal lattice choice — EU calls it self-justified" }, L15 }, .status = .verified_with_correction, .gap = "counts verified; why 15 (not another side) is the lattice scale is the one adopted choice in the loop" },
    .{ .id = "eu.A2_period8", .systems = &.{ "EU A2", "MOUND A4" }, .statement = "Period = 8 cyclic structure (i-vector length / Bott / rank(E8)).", .path = &.{ PRIMAL, IVEC8, E8OV, PHASE8 }, .status = .verified_with_correction, .gap = "8-fold structure verified on three independent carriers (vector length, E8 rank, phase period); 'period' as a dynamical cycle has two unadjudicated modulo-8 conventions" },
    .{ .id = "eu.A3_delta7", .systems = &.{ "EU A3", "MOUND A5" }, .statement = "Mobius defect delta = 3375 - 421*8 = 7.", .path = &.{ L15, COUNTS }, .status = .verified, .gap = "identity verified in lattice.zig; topological 'Mobius twist' interpretation is register" },
    .{ .id = "eu.A4_fano", .systems = &.{ "EU A4", "MOUND A6", "Qstar vX" }, .statement = "Fano plane: 7 oriented lines defining octonion multiplication.", .path = &.{ PRIMAL, A0, FANO, OCT }, .status = .verified_with_correction, .gap = "PG(2,2) incidence and octonion table verified; the AXIOM-0-state-to-unit identification is the definitional bridge" },
    .{ .id = "eu.A5_phi", .systems = &.{ "EU A5", "MOUND A1", "Downbeat" }, .statement = "Golden ratio phi — dimensional-position axiom assigned to the self-similar 15->16 lattice transition.", .path = &.{ PRIMAL, .{ .id = "phi.lattice_position", .status = .verified, .note = "hardware dimensional_ladder describes phi as the characteristic ratio of reversal symmetry, 7-defect recursion, and 15->16 shell positioning; Euqinom assigns phi to its even-spoke positions" }, .{ .id = "phi.defining_equation", .status = .verified, .note = "phi^2=phi+1 uniquely specifies phi once the self-similarity equation is accepted" }, .{ .id = "phi.position_to_equation", .status = .definitional, .note = "the user's dimensional-position derivation identifies the self-similarity equation with phi^2=phi+1; the equation has not yet been independently formalized from the discrete position rules" } }, .status = .verified_with_correction, .gap = "phi is treated as a ladder-position axiom as requested; the corpus provides the semantic derivation path, while its equation-level formalization remains open" },
    .{ .id = "eu.A6_ladder", .systems = &.{ "EU A6", "MOUND A8", "Euqinom v11" }, .statement = "Dimensional ladder 0D-10D.", .path = &.{ PRIMAL, OCT, .{ .id = "ladder.eleven_tiers", .status = .verified, .note = "redox_dimensional_ladder 11 tiers; generative_chain spine covers all algebras incl. anti-octonion/dual-bicomplex bookends" } }, .status = .verified_with_correction, .gap = "algebra tower verified; physical 'dimension' reading is model metadata" },
    .{ .id = "eu.A7_triad", .systems = &.{ "EU A7", "MOUND A7", "Downbeat" }, .statement = "H21 triad phi^5 + pi^2 + phi^-4 ~ 21.106; 7/66 correction.", .path = &.{ .{ .id = "h21.arithmetic", .status = .verified, .note = "h21_lattice_probe checks the triad arithmetic and 7/66 = 7/(6*11) form" }, .{ .id = "h21.interpretation", .status = .gap, .note = "21cm lattice-distance rule is model metadata, not generated" } }, .status = .model_metadata, .gap = "arithmetic verified; physical calibration interpretation unresolved" },

    // -- Qstar-llm implementation axioms --
    .{ .id = "qllm.A1_grid", .systems = &.{"Qstar-llm A1"}, .statement = "Grid: edge(s)=15*2^s, shell 16/15, 8^s qubits, 8^(s+1) resolution.", .path = &.{ L15, .{ .id = "scaling.tiers", .status = .verified, .note = "precision_ladder/scaled_lattice_probe verify 16/15 pairs and volumes through 512^3" } }, .status = .verified_with_correction, .gap = "geometry verified; qbit/universe counts are supplied metadata" },
    .{ .id = "qllm.A2_e0_placement", .systems = &.{"Qstar-llm A2"}, .statement = "421 E0 nodes placed by (x+y+z) mod 3 == 0 rule with multiplicative hash.", .path = &.{ L15, .{ .id = "e0.count_421", .status = .verified, .note = "421 e0 labels verified in lattice.zig" }, .{ .id = "e0.placement_rule", .status = .gap, .note = "donor's specific placement/hash rule differs from the lattice label rule; not cross-verified" } }, .status = .verified_with_correction, .gap = "count verified; exact placement rule unverified against this lattice" },
    .{ .id = "qllm.A3_mobius", .systems = &.{"Qstar-llm A3"}, .statement = "Mobius twist boundary transform.", .path = &.{ L15, COUNTS, .{ .id = "mobius.twist", .status = .definitional, .note = "boundary transform rule is a model convention" } }, .status = .model_metadata, .gap = "defect count verified; twist dynamics are convention" },
    .{ .id = "qllm.A4_octonion_routing", .systems = &.{"Qstar-llm A4"}, .statement = "8 e-values route octonion/gate algebra across the lattice.", .path = &.{ FANO, OCT, .{ .id = "routing.labels", .status = .verified, .note = "Fano labels e0..e7 per cell verified; gate mapping is adapter-level" } }, .status = .verified_with_correction, .gap = "label structure verified; quantum-gate interpretation is adapter semantics" },
    .{ .id = "qllm.A5_phi_cooling", .systems = &.{"Qstar-llm A5"}, .statement = "phi-cooling schedule for Grover iteration count.", .path = &.{ .{ .id = "phi.lattice_position", .status = .verified, .note = "phi parameter is sourced by the dimensional-position axiom eu.A5_phi" }, .{ .id = "cooling.algorithm", .status = .definitional, .note = "the cooling schedule uses phi in the declared Grover heuristic" } }, .status = .model_metadata, .gap = "lattice-position origin is recorded; the cooling schedule remains an algorithmic heuristic, not a consequence of lattice geometry" },
    .{ .id = "qllm.A6_11dim", .systems = &.{"Qstar-llm A6"}, .statement = "11-dimensional routing ladder.", .path = &.{ PRIMAL, IVEC8, .{ .id = "ladder.eleven_tiers", .status = .verified, .note = "same 11-tier ladder as eu.A6" } }, .status = .verified_with_correction, .gap = "ladder verified; routing use is implementation detail" },
    .{ .id = "qllm.A7_lambdah", .systems = &.{"Qstar-llm A7"}, .statement = "Hubble wavelength lambda_H fundamental scale.", .path = &.{.{ .id = "h21.physical", .status = .gap, .note = "physical constant scale; imported, not generated by the loop" }}, .status = .register, .gap = "physical scale input; register-level" },

    // -- The second loop: MOUND zero-free-parameters --
    .{ .id = "mound.A2_pi", .systems = &.{ "MOUND A2", "Downbeat" }, .statement = "Circle constant pi — dimensional-position axiom assigned to spherical ladder tiers S^1,S^3,S^5,S^7.", .path = &.{ PRIMAL, .{ .id = "pi.spherical_positions", .status = .verified, .note = "hardware dimensional_ladder explicitly types e1/e3/e5/e7 as S^1/S^3/S^5/S^7 and e2/e4/e6 as N^3 transitions" }, .{ .id = "pi.sphere_volumes", .status = .verified, .note = "standard sphere-volume formulae contain powers of pi at each listed odd sphere dimension" }, .{ .id = "pi.position_to_constant", .status = .definitional, .note = "the user's dimensional-position derivation assigns pi as the geometric constant at the spherical positions; this is a positional axiom, not a primitive independent seed" } }, .status = .verified_with_correction, .gap = "the source documents the sphere-position → pi path; a separate formal proof of the ladder's position assignment is not encoded in this port" },
    .{ .id = "mound.zero_free_parameters", .systems = &.{ "MOUND claim", "Euqinom" }, .statement = "Zero free parameters: Hurwitz -> O -> E8 -> L=15 -> P=8 -> delta=7 -> all constants.", .path = &.{ .{ .id = "zfp.theorem_chain", .status = .verified, .note = "derivations/65: Hurwitz/Chevalley/Fano/phi theorems -> constants, code-tested in donor" }, .{ .id = "zfp.parallel_loop", .status = .definitional, .note = "this loop is rooted in mathematical theorems + phi/pi — parallel to the i-vector loop, not a reduction of it" } }, .status = .verified_with_correction, .gap = "internally verified zero-parameter chain; a second fixed-point loop whose constants are external theorems — the two loops share the lattice counts but neither generates the other" },

    // -- Downbeat readings --
    .{ .id = "db.0pow0_readings", .systems = &.{"Downbeat"}, .statement = "0^0 readings: empty product = 1; lattice-derived = 421/3375.", .path = &.{ L15, .{ .id = "density.421_3375", .status = .verified, .note = "421 e0 / 3375 cells verified in lattice.zig" }, .{ .id = "empty_product.one", .status = .definitional, .note = "standard convention, not derived" } }, .status = .verified_with_correction, .gap = "density verified; the 0^0=i generative reading is the fixed-point role (see fixedpoint.0pow0_eq_i) — three roles kept distinct" },

    // -- RamseyIdentity --
    .{ .id = "ri.P237_mirror", .systems = &.{"RamseyIdentity"}, .statement = "Mirror duality E=mc^2 <-> i <-> E=mc^-2.", .path = &.{ PRIMAL, .{ .id = "mirror.framework", .status = .definitional, .note = "framework duality statement; cpti_checksum verifies arithmetic form only" } }, .status = .model_metadata, .gap = "checksum arithmetic verified; physical mirror interpretation unresolved" },
    .{ .id = "ri.P238_vacuum", .systems = &.{"RamseyIdentity"}, .statement = "Vacuum emergence: 0^0 = e0 = 8D^i — the same fixed-point identification expressed in RamseyIdentity's own axioms.", .path = &.{ PRIMAL, E0ID, .{ .id = "vacuum.internal_axioms", .status = .definitional, .note = "derived from RamseyIdentity axioms 2.1-2.3 + interpretive step — internal derivation of the same fixed point, parallel root" } }, .status = .model_metadata, .gap = "internal derivation exists; it derives the SAME fixed-point statement, not the i-vector loop" },
    .{ .id = "ri.P239_period8", .systems = &.{"RamseyIdentity"}, .statement = "Period-8 identity 8^i = i.", .path = &.{ PRIMAL, IVEC8, PHASE8 }, .status = .verified_with_correction, .gap = "period-8 closure verified as phase arithmetic; algebraic-exponentiation reading is framework convention" },

    // -- TheUE --
    .{ .id = "theue.chiral_algebra", .systems = &.{"TheUE/ChiralMath"}, .statement = "ChiralAlgebra 7-tuple q=(a,b,c,x,y,z,t) with hydrogen/CMB calibration.", .path = &.{ PRIMAL, .{ .id = "chiral.model", .status = .definitional, .note = "model construction; conversation record, not a derivation artifact" } }, .status = .model_metadata, .gap = "model metadata; physical calibration claims unverified" },
};

// ---------------------------------------------------------------------------
// Combinatorial verifications (integer-only)
// ---------------------------------------------------------------------------

/// The 8 states of {0,1}^3, index = x*4 + y*2 + z.
pub fn axiom0States() [8]u8 {
    var out: [8]u8 = undefined;
    for (0..8) |i| out[i] = @intCast(i);
    return out;
}

/// The 7 nonzero states as Fano points, encoded as 1..7.
pub fn nonzeroStates() [7]u8 {
    var out: [7]u8 = undefined;
    var n: usize = 0;
    for (axiom0States()) |s| {
        if (s != 0) {
            out[n] = s;
            n += 1;
        }
    }
    return out;
}

pub fn xor3(a: u8, b: u8) u8 {
    return a ^ b;
}

/// Fano lines from the 7 nonzero vectors: {a, b, a XOR b} for a < b,
/// deduplicated. Expect exactly 7 lines of 3 points each.
pub fn fanoLinesFromStates() [7][3]u8 {
    var lines: [7][3]u8 = undefined;
    var n: usize = 0;
    const pts = nonzeroStates();
    for (pts, 0..) |a, ai| {
        for (pts[ai + 1 ..]) |b| {
            const c = xor3(a, b);
            if (c == 0 or c == a or c == b) continue;
            var sorted = [_]u8{ a, b, c };
            std.mem.sort(u8, &sorted, {}, struct {
                fn lt(_: void, x: u8, y: u8) bool {
                    return x < y;
                }
            }.lt);
            var dup = false;
            for (lines[0..n]) |l| {
                if (l[0] == sorted[0] and l[1] == sorted[1] and l[2] == sorted[2]) dup = true;
            }
            if (!dup and n < 7) {
                lines[n] = .{ sorted[0], sorted[1], sorted[2] };
                n += 1;
            }
        }
    }
    return lines;
}

/// PG(2,2) incidence checks on the derived lines.
pub fn fanoIncidenceOk() bool {
    const lines = fanoLinesFromStates();
    var line_count: usize = 0;
    for (lines) |l| {
        if (l[0] == 0 or l[1] == 0 or l[2] == 0) continue;
        if (l[0] == l[1] or l[1] == l[2] or l[0] == l[2]) return false;
        const ok = (xor3(l[0], l[1]) == l[2]) or (xor3(l[0], l[2]) == l[1]) or (xor3(l[1], l[2]) == l[0]);
        if (!ok) return false;
        line_count += 1;
    }
    if (line_count != 7) return false;
    const pts = nonzeroStates();
    for (pts, 0..) |a, ai| {
        for (pts[ai + 1 ..]) |b| {
            var cover: usize = 0;
            for (lines[0..line_count]) |l| {
                var has_a = false;
                var has_b = false;
                for (l) |p| {
                    if (p == a) has_a = true;
                    if (p == b) has_b = true;
                }
                if (has_a and has_b) cover += 1;
            }
            if (cover != 1) return false;
        }
    }
    for (pts) |p| {
        var deg: usize = 0;
        for (lines[0..line_count]) |l| {
            for (l) |q| {
                if (q == p) deg += 1;
            }
        }
        if (deg != 3) return false;
    }
    return true;
}

/// i-vector: 8 components indexed 0..7 (e0..e7).
pub const IVECTOR_LEN = 8;

/// Map an AXIOM-0 state index to its i-vector component claim:
/// state 0 (all-zero) -> e0 (observer/identity); states 1..7 -> e1..e7.
/// This is the definitional bridge, exposed for audit — not a derivation.
pub fn stateToComponent(state: u8) u3 {
    return @intCast(state);
}

/// The fixed point's executable shadow: the phase cycle closes after
/// exactly PHASE_STEPS_PER_CYCLE transits under BOTH conventions.
pub fn phasePeriodVerified() bool {
    const conventions = [_]lattice.PhaseConvention{ .quarter_turn_per_transit, .three_quarter_turn_per_transit };
    for (conventions) |conv| {
        var phase = lattice.Phase{};
        for (0..lattice.PHASE_STEPS_PER_CYCLE) |_| phase.transit(conv);
        if (phase.eighth_turns != 0) return false;
    }
    return lattice.PHASE_STEPS_PER_CYCLE == IVECTOR_LEN;
}

// ---------------------------------------------------------------------------
// Table validation
// ---------------------------------------------------------------------------

pub fn validate() bool {
    var primal_count: usize = 0;
    for (AUDIT, 0..) |a, i| {
        if (a.id.len == 0 or a.statement.len == 0 or a.gap.len == 0) return false;
        for (AUDIT[i + 1 ..]) |b| {
            if (std.mem.eql(u8, a.id, b.id)) return false;
        }
        if (std.mem.eql(u8, a.id, "ivector.primal")) {
            primal_count += 1;
            if (a.path.len != 0) return false;
        } else if (a.path.len == 0) return false;
        for (a.semantic_map) |mapping| {
            if (mapping.version.len == 0 or mapping.interpretation.len == 0 or mapping.basis.len == 0) return false;
        }
        for (a.evidence) |ref| {
            if (ref.path.len == 0 or ref.sha256.len == 0 or ref.fact.len == 0 or ref.semantic_target.len == 0) return false;
        }
    }
    return primal_count == 1;
}

fn hasStep(a: AxiomAudit, step_id: []const u8) bool {
    for (a.path) |s| {
        if (std.mem.eql(u8, s.id, step_id)) return true;
    }
    return false;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "audit table is complete and well-formed (loop semantics)" {
    try std.testing.expect(validate());
    const want = [_][]const u8{
        "ivector.primal",             "fixedpoint.0pow0_eq_i", "fixedpoint.period8", "checksum.palindrome_i",
        "euq.axiom0_distinction",     "eu.A1_l15",             "eu.A2_period8",      "eu.A3_delta7",
        "eu.A4_fano",                 "eu.A5_phi",             "eu.A6_ladder",       "eu.A7_triad",
        "qllm.A1_grid",               "qllm.A2_e0_placement",  "qllm.A3_mobius",     "qllm.A4_octonion_routing",
        "qllm.A5_phi_cooling",        "qllm.A6_11dim",         "qllm.A7_lambdah",    "mound.A2_pi",
        "mound.zero_free_parameters", "db.0pow0_readings",     "ri.P237_mirror",     "ri.P238_vacuum",
        "ri.P239_period8",            "theue.chiral_algebra",
    };
    try std.testing.expectEqual(want.len, AUDIT.len);
    for (want) |id| {
        var found = false;
        for (AUDIT) |a| {
            if (std.mem.eql(u8, a.id, id)) found = true;
        }
        try std.testing.expect(found);
    }
}

test "semantic mappings retain multiple interpretations with provenance" {
    for (AUDIT) |entry| {
        for (entry.semantic_map) |mapping| {
            try std.testing.expect(mapping.version.len != 0);
            try std.testing.expect(mapping.interpretation.len != 0);
            try std.testing.expect(mapping.basis.len != 0);
        }
    }
    try std.testing.expect(AUDIT[0].semantic_map.len >= 2);
    try std.testing.expect(AUDIT[1].semantic_map.len >= 2);
    try std.testing.expect(AUDIT[3].semantic_map.len >= 2);
    try std.testing.expect(AUDIT[0].evidence.len >= 3);
    try std.testing.expect(AUDIT[1].evidence.len >= 3);
    try std.testing.expect(AUDIT[3].evidence.len >= 3);
    for (AUDIT) |entry| {
        for (entry.evidence) |ref| {
            try std.testing.expect(ref.path.len != 0);
            try std.testing.expect(ref.sha256.len != 0);
            try std.testing.expect(ref.fact.len != 0);
            try std.testing.expect(ref.semantic_target.len != 0);
        }
    }
}

test "AXIOM 0: 8 states, 7 nonzero, all distinct" {
    const states = axiom0States();
    try std.testing.expectEqual(@as(usize, 8), states.len);
    const nz = nonzeroStates();
    try std.testing.expectEqual(@as(usize, 7), nz.len);
    for (nz) |s| try std.testing.expect(s != 0);
    for (nz, 0..) |a, i| {
        for (nz[i + 1 ..]) |b| try std.testing.expect(a != b);
    }
    try std.testing.expectEqual(@as(u8, 8), @as(u8, 1) << 3);
}

test "AXIOM 0 nonzero states form PG(2,2) Fano incidence" {
    try std.testing.expect(fanoIncidenceOk());
    const lines = fanoLinesFromStates();
    var count: usize = 0;
    for (lines) |l| {
        if (l[0] != 0) count += 1;
    }
    try std.testing.expectEqual(@as(usize, 7), count);
}

test "i-vector has 8 components matching the 8 AXIOM-0 states and phase period" {
    try std.testing.expectEqual(@as(usize, 8), IVECTOR_LEN);
    try std.testing.expectEqual(@as(u3, 0), stateToComponent(0));
    try std.testing.expectEqual(@as(u3, 7), stateToComponent(7));
    try std.testing.expect(phasePeriodVerified());
}

test "the 0^0=i fixed point carries verified executable shadows" {
    // e0 identity + period-8 closure are the checkable content of the
    // fixed-point statement; the i-identification stays definitional.
    const fp = AUDIT[1];
    try std.testing.expect(std.mem.eql(u8, fp.id, "fixedpoint.0pow0_eq_i"));
    try std.testing.expect(hasStep(fp, "e0.identity"));
    try std.testing.expect(hasStep(fp, "phase.period8"));
    try std.testing.expect(hasStep(fp, "ivector.identification"));
}

test "lattice counts underlying the emergence paths verify" {
    const lat = lattice.Lattice.init();
    try std.testing.expect(lat.validate());
    try std.testing.expectEqual(@as(usize, 421), lat.countLabel(0));
    try std.testing.expectEqual(@as(u64, 3375), precision.volume(15));
    try std.testing.expectEqual(@as(u64, 721), scaled.foamCount(15, 16));
    var foam: usize = 0;
    for (0..redox_lattice.Shell) |z| {
        for (0..redox_lattice.Shell) |y| {
            for (0..redox_lattice.Shell) |x| {
                if (redox_lattice.shellState(@intCast(x), @intCast(y), @intCast(z)) == redox_lattice.Foam) foam += 1;
            }
        }
    }
    try std.testing.expectEqual(@as(usize, 721), foam);
}

test "generative chain verifies (bootstrap links are code-checked)" {
    try gen.verify();
}

test "register-status axioms all name their gap; exactly one primal node" {
    for (AUDIT) |a| {
        if (a.status == .register) {
            try std.testing.expect(a.gap.len > 0);
        }
    }
    for (AUDIT) |a| {
        if (!std.mem.eql(u8, a.id, "ivector.primal")) {
            try std.testing.expect(a.path.len > 0);
        }
    }
}

test "emergence paths run ivector-outward for the structural axioms" {
    try std.testing.expect(hasStep(AUDIT[5], "lattice.l15")); // eu.A1_l15
    try std.testing.expect(hasStep(AUDIT[7], "counts.identities")); // eu.A3_delta7
    try std.testing.expect(hasStep(AUDIT[8], "fano.pg2_2")); // eu.A4_fano
    try std.testing.expect(hasStep(AUDIT[4], "fano.pg2_2")); // euq.axiom0_distinction
    // phi/pi are dimensional-position axioms, not external roots
    try std.testing.expect(hasStep(AUDIT[9], "phi.lattice_position")); // eu.A5_phi
    try std.testing.expect(hasStep(AUDIT[19], "pi.spherical_positions")); // mound.A2_pi
}

test "checksum palindrome on i: pivot is the fixed point, wings collapse" {
    const cs = AUDIT[3];
    try std.testing.expect(std.mem.eql(u8, cs.id, "checksum.palindrome_i"));
    try std.testing.expect(hasStep(cs, "fixedpoint.0pow0_eq_i"));
    try std.testing.expect(hasStep(cs, "checksum.algebraic_palindrome"));
    // the algebraic palindrome itself: forward * inverse == mass^2
    try std.testing.expect(redox_checksum.productIsMassSquared(8, 2));
    try std.testing.expect(!redox_checksum.productIsMassSquared(8, 3));
}

test "i-vector representation is exactly eight signed integer components" {
    const vector = @import("redox_information_vector.zig").Vector{};
    try std.testing.expectEqual(@as(usize, 8), vector.values.len);
    for (vector.values) |component| try std.testing.expectEqual(@as(i512, 0), component);
}

test "True-Origin lattice and semantic i-vector cardinalities stay distinct" {
    const lat = lattice.Lattice.init();
    const counts = lat.labelCounts();
    try std.testing.expectEqual(@as(usize, 8), counts.len);
    try std.testing.expectEqual(@as(usize, 3375), lat.labels.len);
    try std.testing.expectEqual(@as(usize, 421), counts[0]);
    try std.testing.expectEqual(@as(usize, 422), counts[1]);
    try std.testing.expectEqual(@as(usize, 422), counts[7]);
    try std.testing.expectEqual(@as(u3, 0), lat.labelAtSigned(.{ .x = 0, .y = 0, .z = 0 }).?);
    try std.testing.expectEqual(@as(usize, 7), lattice.Lattice.index(.{ .x = 0, .y = 0, .z = 0 }).? / lattice.SLICE_NODE_COUNT);
    try std.testing.expectEqual(@as(usize, 8), @import("redox_information_vector.zig").COMPONENT_COUNT);
}
