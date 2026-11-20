# Changelog

All notable changes to the Octonion-OS lattice engine. The canonical
claim/evidence ledger is `src/axiom_registry.zig`; this file records what
changed in the engine and documentation, not verdict promotions.

## Unreleased — standalone transition and QComms alignment

### Added

- `AGENTS.md` — governing agent guide for this tree: project law, claims
  discipline, standing invariants, provenance law, retro-dev micro-loop,
  continuity order. Takes precedence over donor-tree agent rules.
- `CLAIMS.md` — human-readable verdict ledger distilled from
  `src/axiom_registry.zig` (37 nodes, 39 typed edges).
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
