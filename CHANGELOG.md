# Changelog

All notable changes to the Octonion-OS lattice engine. The canonical
claim/evidence ledger is `src/axiom_registry.zig`; this file records what
changed in the engine and documentation, not verdict promotions.

## e6ddb9b — Audit e2e continuity; restore superposed instances; screen image claims

This section covers the work arc since `cad6b47` — the standalone
transition, QComms alignment, contract v1s, scale audits, the
superposition law, and the e2e continuity audit — all committed in
`e6ddb9b`.

### Added

- `lattice.image_claims_audit_v1` + `src/image_claims_probe.zig` —
  reconciled the supplied ladder, scale, Fano, Möbius, cooling, and
  prediction diagrams against executable integer checks. Newly verified:
  the Möbius z=0↔z=14 180° identification is label-compatible at odd
  inner sides and label-invisible (the coloring cannot distinguish twist
  from mirror; even inner sides support neither identification); the
  panels' qubit ladder is the canonical-pair chain (interior 15·2^s,
  shell 16·2^s, qubits = 8^s blocks of 15³) — a different indexing than
  the constant audit's power-of-two interiors (audit side k = image shell
  side k−1); each 15³ octant of 30³ carries the canonical histogram
  multiset with a shifted defect; the Fibonacci cooling bars reproduce in
  Q128 as `w_z = φ^{-z}/Σφ^{-k}`. Second-batch additions: the ψ-field
  Möbius boundary condition is the verified transform (field itself is
  donor data); every slice's label field is D4-symmetric so a dominant
  m=7 angular harmonic is impossible for `basisAt` — the spectral panels
  belong to the donor ψ field; the center slice carries exactly 29 e0
  cells (center + radius-8 Manhattan diamond); radial rings are exact
  (L1 `4r`, Chebyshev `8r`); Axiom-7 discretization verifies —
  `round(φ⁵+π²+φ⁻⁴) = F₀ = 21`, residuals 0.503%/0.0021% — and the
  v11.0 ladder coordinates are integer rationals over F₀. The prediction
  chart's 1/α, sin²θ_W, Koide rows are absent from the 145-table and its
  figures disagree across panels; the helix parameterization is model
  geometry. Third-batch additions: e-labels are exactly Manhattan-
  octahedral shells `{k,k+8,k+16}` — populations fold mod 8 into
  `[421,422×7]` with e0's 421 set by the observer singleton — correcting
  the "Chebyshev shells" title; "hidden spheres" are the nearest integer-
  radius shells to φ (d²=3, 8 cells) and π (d²=10, 24 cells); the
  Fano+e8 annotations verify as implemented algebra (`e8·e1=e1`,
  `e8²=+e0`), while the "all commutativity lost" caption is contradicted
  since e8 commutes with every unit; ladder bars fully verify
  (`0, φ, π` constants + F₀ rationals); the 10D→0D projection chain is
  the reduction direction. Fourth-batch additions: the 15 z-slices carry
  exactly 8 distinct 2D patterns (mirrored pairs `z↔14−z`, cyclic-shift
  law `2D-L1+|z−7| mod 8`); the Cayley-Dickson Start→End chain is an
  exact palindrome `5.25…42…5.25` peaking at the 6D mirror (42 = 8× the
  ends); Lie-table corrections recorded (e3→SO(4) contradicts measured
  so(3), e4→SO(5) questionable; e7→G2, e6→E6/F4 verified); E8 splits
  `112+128` (standard) and `16+112+112` (octavian) both exact;
  "e7→e2 closure" verifies as `e5·e7=+e2`; L15-touch/L16-outward face
  topology verified (interface at coord=inner, 3+3 faces per block);
  Smith-chart/Ohm-wheel mappings are domain-valid semantics; the
  "1128 bits" capacity figure is unexplained and flagged for a source.
- **Convention-superposition audit**: recorded the standing rule that
  coexisting correct instances are never collapsed. Restored/completed
  silently dropped instances: the phase-generator family is now the
  complete unit group U(8) = {1,3,5,7} (+5/+7 are the negated images);
  `redox_sedenion.zig` implements the Cayley-Dickson e8 double
  (`e8²=−e0`, anticommuting, non-alternative, runtime-discovered zero
  divisors) as the second extension instance. Declared already-live
  superpositions: three 15³ colorings sharing census `[421,422×7]`
  (pairwise divergence 1980/3375/3375, legacy singleton at label 5)
  and two Fano tables ({3,5,6}/{3,6,5} — unit-identical, sign differs
  on exactly the {3,5,6} products). Registered `ladder.sedenion_16d`
  with `superposes`/`cayley_dickson_doubles` edges (sibling, not a new
  rung); the 11-tier ladder order is unchanged.
- **Cyber-physical superposition law v1**: formalized the governing
  rule (premise: everything is inherently quantum) — the cyber layer
  natively carries superposition as coexisting verified branches;
  collapse is physical-side only via the declared measurement contract
  or independent evidence; defaults/canonical choices are bookkeeping,
  not collapse; falsification is branch-scoped, never "impossible".
  Applied immediately to the m=7 audit finding: excluded in the
  D4-symmetric `basisAt` branch (theorem), structurally open in the
  non-D4 init/legacy branches (≤1 of 7 transforms preserved) — the
  donor field is a live branch. Registered `cyber.superposition_law_v1`;
  CYBER-PHYSICS.md gained the formal law section.
- `pipeline.e2e_continuity_v1` + `src/e2e_continuity_probe.zig` — full
  end-to-end continuity audit: a SEAMS table records all 17 pipeline
  transitions (axiom → i-vector → labels → colorings → QComms →
  15³→16³ bridge → amplitudes → evolution → measurement → readout →
  frames/serialize → routing → reversible CA → scale chain → ladder →
  adapter → registry) with producer/consumer/invariant/kind, backed by
  12 executable checks. Measured branch binding: the qbit label
  observable + frames + serialize + routing read the `Lattice.init`
  branch while QComms reads `basisAt` — proven on divergence cells in
  both directions. Compounding law sharpened to `shell − inner =
  inner/15` per canonical pair; audit sides ≤512 equal pair shells.
  Routing Fano usage shown convention-blind (unordered line membership).
  Recorded open lane: whether serialized manifests need an explicit
  branch tag — decision point, not normalized.
- Registered exact count identities separately from framework
  readings; the 42/21 ratio does not establish consciousness, diagram
  qbit counts are not physical measurements, and the prediction panel is
  not independently reproduced.
- `src/lattice_constant_audit.zig` — exact scale-0-through-scale-7
  lattice-native count/fraction inventory compared against all 145 MOUND
  target values and independently against all representable donor triad
  evaluations, without fitting. Scale 0 stays 15³; scale 1 and the
  16³ compounding shell are omitted as standalone levels; scale 2 starts
  at 32³. The audit reports nearest candidates with scale/kind provenance,
  exact and threshold match counts, Q128 target underflows, target
  conversion/arithmetic errors, triad-evaluation underflows, and H21
  `7/66` context. Scale-0 coloring is enumerated exactly; higher-scale
  label populations are uniform modulo-8 metadata, not dense translated-
  Fano enumerations. Comparisons are arithmetic observations, not physical
  constant derivations. Registered as `lattice.scale_constant_inventory_v1`.
- `src/hydrogen_alignment_probe.zig` — Q128 integer implementation of the
  hydrogen nonrelativistic 1s Coulomb spatial solution on the E0-centered
  15³ interior, normalized as a discrete lattice state with a computed 2D
  central density slice. The 21 cm hyperfine line is modeled separately as
  a spin flip retaining the same spatial state; `a₀=1` lattice step remains
  an explicit, uncalibrated scale convention. The ladder's e3 H21 and e6
  21cm endpoint triples are preserved distinctly; the e6 correction is
  `21 cm + 7/66 cm = 21.1060606… cm`, close to the measured wavelength.
  Added a tested triad-role decomposition: π² is centered at E0, φ⁵ is
  the outer reading, and φ⁻⁴ the inner reading. The same additive
  `7/66` increment is applied to the full triad as its e3→e6 candidate;
  its mismatch with measured 21cm is retained alongside the integer-baseline
  `21 + 7/66` check.
- `src/mound_triad.zig` + `src/mound_triad_table.zig` — MOUND triad
  operator `T(a,b,c)=φ^a+π^b+φ^c` evaluated over the donor's 145-row
  constants table in Q128.128 integer fixed-point. Targets stored as
  exact `mantissa × 10^exp` integers (no float literals). Negative
  exponents use reciprocal-base powers so |exp|≤214 underflows safely
  to zero with an `underflowed` flag. `verifyAll` recomputes every row
  and reports residual statistics: 144 evaluable + 1 target-underflow
  (Planck time), 0 arithmetic failures, 130 within 1%, worst 2.71%.
  Positioning-derived correction hypotheses tested and rejected —
  residuals are signature-fit noise. Registered as
  `mound.triad_table_v1`.

- `src/phi_pi_position.zig` — φ/π dimensional-position contract v1:
  π anchored at E0, φ carried inward on the six cardinal directions,
  and the 16³ compounding shell (721 sites, any coord == 15) as the
  outward-φ role that exists only when scaling — the bare 15³ has no
  shell interactions. Roles/directions only; the position→equation
  bridge remains open. Registered as `lattice.phi_pi_position_v1`.

- `AGENTS.md` — governing agent guide for this tree: project law, claims
  discipline, standing invariants, provenance law, retro-dev micro-loop,
  continuity order. Takes precedence over donor-tree agent rules.
- `CLAIMS.md` — human-readable verdict ledger distilled from
  `src/axiom_registry.zig` (node/edge totals are maintained in the ledger).
- `CYBER-PHYSICS.md` — the cyber-physical qbit frontier: computational
  substrate inventory, evidence boundary, measurement-contract gate, and
  open elevation paths.
- `src/axiom_registry.zig` — canonical connected ledger: unique claim
  nodes with status/implementation/verification/provenance, typed edges,
  closed origin→return graph, `validate()`.
- `src/axiom_derivation_audit.zig` — per-axiom emergence-path audit across
  the corpus under loop semantics (`0^0=i` fixed point; i-vector primal).
- `src/generative_chain.zig` — verified generative chain: `0^0=i` →
  E0/E8 bookends → real → complex → vector3 → quaternion → bicomplex →
  Jordan J3(O) → octonion → E8 loopback → anti-octonion → dual bicomplex
  → counts → 15³ lattice qbit → return to origin.
- Ported algebra modules (`src/redox_*.zig`): algebra bridge, vector3,
  bicomplex, Jordan, octonion, anti-octonion, dual bicomplex, E8 roots,
  dimensional ladder, checksum, scaling tiers/audit, Fano spec, e0 unity,
  information vector, claims, temporal models, sonoluminescence, tier
  pipeline.
- `src/precision_ladder.zig` — `i32q16…i512q256` × shell sides 16…512.
- `src/scaled_lattice_probe.zig` — exact mod-8 histograms through inner
  480 without dense materialization.
- `src/lattice_qbit.zig` + `src/quantum/` — 4,096-site Q128 lattice qbit:
  Hamiltonian, Chebyshev evolution, interior preparation, population
  accounting, deterministic readout.
- `src/lattice_measure.zig` — measurement/readout contract v1 for the
  lattice qbit: deterministic u64-selector Born sampling over all
  4,096 sites, interior e-label class sampling, site collapse,
  Lüders label projection with renormalization, non-mutating
  population/digest readouts. Declared software semantics; physical
  apparatus mapping remains gated.
- `src/ivector_readout.zig` — i-vector ↔ amplitude binding contract v1:
  site-sample shot histograms classify into the eight e-label
  components plus an explicit shell channel, and label populations
  quantize to i512 via a declared round-half-up convention. Declared
  software semantics; physical i-vector correspondence open.
- `src/reversible_lattice.zig` — lattice-native reversible transition
  contract v1: octonion-cell (2×2×2 = 8 sites ↔ e0..e7) Margolus-style
  CA on u8 sites over the 16³ torus. Cell primitives (swap, rot,
  add/sub, conditional swap/add/sub) are enforced bijective on
  (Z/256)⁸ via disjointness constraints, so every step and alternating
  partition composition has an exact inverse. Declared candidate rule;
  classical u8 lane distinct from the Q128 lattice state.
- Transit-phase contract v1 (`lattice.CANONICAL_PHASE_CONVENTION`):
  the Module-2 source spec ("3π/4 per transit with closure at 8
  transits") selects `three_quarter_turn_per_transit` (+3 eighth-turns)
  as canonical; `quarter_turn_per_transit` (+1) remains as the
  minimal-generator variant. Executable gauge analysis: the +3 sequence
  is the element-wise ×3 mod 8 image of +1, ×3 is not an octonion
  automorphism (checked via `octonion.multiply`), and both conventions
  share cycle invariants (8-step closure, antipode at transit 4,
  parity alternation). Registry node `lattice.transit_phase_v1` added.
- `.gitignore` — `externals/` excluded for vendored/read-only donor
  trees (Q.ANT toolkit appraisal recorded in `CYBER-PHYSICS.md`).
- `src/qsharp_adapter.zig` — Q#-vocabulary adapter over the bounded
  state-vector module (not a Q# runtime).
- `src/reversible_probe.zig` — classical reversible gates (NOT, CNOT,
  Toffoli, Fredkin, SWAP, Peres), exhaustive bijection tests,
  compute-copy-uncompute.
- `src/lattice_quantum_probe.zig`, `src/lattice_hamiltonian_probe.zig`,
  `src/h21_lattice_probe.zig`, `src/quantum_behavior_probe.zig` —
  scoped dynamics/H21/simulation probes.
- `src/qcomms_lattice.zig` `LABELING_VERSION = 2` — E0-aligned coloring;
  `legacyState`/`legacyDigest` preserve version-1 reproduction.

### Changed

- `src/lattice.zig` — `validate()` now checks origin label, full census
  `[421, 422×7]`, mirror symmetry, and cardinal imaginary-label coverage;
  added `labelAtSigned`, `labelCounts`, canonical-coordinate/label checks.
- QComms default coloring moved from the legacy E5-vantage formula to the
  canonical `basisAt` rule; legacy path retained explicitly.
- `README.md`, `PHASE-QUANTUM-AUDIT.md`, `1.md` — synchronized with the
  4,096-site state-domain decision, QComms alignment, E8 scope, phase
  conventions, reversible collision, and physical-evidence boundary.

## cad6b47 — Add bounded quantum behavior probes

Two-qubit Q32.32 state-vector model (H/CNOT, norm checks, concurrence),
eight-phase two-path interference model, squared-amplitude sampler with
deterministic seeded shots, passive-observer snapshot contract.

## 839db2c — Keep phase and evidence contracts explicit

Selectable modulo-8 transit-phase conventions (increments 1 and 3),
explicit serialization boundary, claim-catalog verdict vocabulary,
frame manifest with digests.

## 9f28555 — Initialize Octonion lattice engine

Integer-first 15³ signed-coordinate lattice, translated Fano tensor,
quantized Quad-Smith sidecar, sparse scaling metadata, deterministic
JSON export, secondary-e0 routing.
