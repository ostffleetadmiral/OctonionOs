# Octonion-OS — Agent Guide

Canonical agent rules for this tree. This file governs work inside
`/home/admpaul/CascadeProjects/Octonion-OS` only. AGENTS.md files, .windsurf
rules, and global memories belonging to other project trees (hardware,
RedOx, BLUE, LuckyBastard, v0.0.0.x, Euqinom, downbeat, Qstar, donor/vendor
directories) apply only inside those trees. When working here, this file
takes precedence for Octonion-OS decisions; donor rules are provenance, not
law.

## What this project is

A standalone, integer-first Zig 0.13.0 computational engine for the
True-Origin octonion lattice. The organizing axiom is `0^0 = i`, where `i`
is the primal 8-component i-vector `[e0^i..e7^i]` — not ordinary scalar
exponentiation and not the complex imaginary unit. The framework is a
**loop, not a tree**: the i-vector is the distinguished object, `0^0 = i`
is a fixed point on the loop, and every axiom carries an *emergence path*
(read the same path backward for reduction). Multi-axiom sets (EU seven
axioms, EU AXIOM 0, MOUND A1–A8, Qstar, downbeat) are `.register`-status
claimed expansions — doctrine, not verified derivations.

The project's **cyber-physical qbit** is its proposed macroscopic 3D
lattice analogue, distinct from a conventional microscopic quantum bit.
The user's overarching premise is that the universe is inherently quantum
and cyber-realized capabilities are physically realizable within the
framework. That premise is recorded as framework interpretation; it is not
a substitute for per-claim evidence.

All donor knowledge has been distilled into this tree. Donor repositories
are read-only provenance — never modified, never depended on at
compile or runtime. Absolute paths inside `SourceRef` strings are
provenance labels, not filesystem access.

## Verification

```sh
zig build test          # core + sidecar
zig build test-core     # integer core only
zig build test-sidecar  # f64 sidecar only
zig fmt --check src/*.zig
git diff --check
```

Float-token scan (must print PASS): strip `//` comments, `/* */` blocks,
and string literals from `src/**/*.zig`, then grep for `\bf(32|64)\b`.
`build.zig` exposes test steps only; add run/example targets only when a
real consumer exists.

## Layout

- `src/` — integer-only core. `lattice.zig` canonical 15³ tensor;
  `qcomms_lattice.zig` aligned QComms labels; `lattice_qbit.zig` +
  `quantum/` state-vector/qbit lane; `redox_*.zig` ported algebra ladder;
  `axiom_registry.zig` + `axiom_derivation_audit.zig` claims ledger;
  `generative_chain.zig` verified algebra/count chain; `serialize.zig`,
  `frames.zig`, `routing.zig`, `scaling.zig`, `precision_ladder.zig`,
  `scaled_lattice_probe.zig` structure/scale lanes.
- `sidecar/` — the only f64 lane (`quad_smith.zig` Shirley mapping +
  quantized table). Keep it isolated.
- `examples/` — currently empty.
- `README.md` — user-facing architecture and contracts.
- `PHASE-QUANTUM-AUDIT.md` — evidence ledger, donor inventory, physical
  boundary, open questions.
- `1.md` — working notes.

## Code law

- **Integer-only core**: no `f32`/`f64` tokens in executable `src/` code.
  Floating point lives only in `sidecar/` or test oracles.
- **Fail closed**: corrupt/hostile input returns named errors; no panics
  on untrusted data; checked arithmetic on all accumulation.
- **No stubs**: no placeholders, TODO-shaped logic, mocks, or fabricated
  results. Absent capability = honest error or documented open lane.
- **Every capability ships tests** in the same edit; coverage must not
  regress.
- **Zig 0.13.0** idioms; `zig fmt` clean; `git diff --check` clean.

## Epistemic law (claims discipline)

Every claim carries a status; never blur these:

- `verified` — an executable check in this tree passed.
- `verified_with_correction` — holds modulo a named, recorded correction.
- `model_metadata` — declared labels/counts carried verbatim; not
  independently verified physics.
- `register` — doctrine/narrative; no physical verdict either direction.
- `unsupported` / `unresolvable` — scoped to the exact claim tested;
  always names the elevation path. "No artifact" is never "impossible."
- `contradicted` — reserved for a claim failing its own verifier.

Simulator/software results are computational evidence only. Physical
experiments stay parked until a measurement contract exists: state
variable, preparation, readout/collapse semantics, disturbance protocol,
controls, calibration, thresholds, artifact schema, and explicit
authorization. BLUE/JIZO RF/transport/CSI records are separate physical
lanes until mapped to the 15³ state.

## Invariants and standing decisions

Preserve these exactly; changing one requires an explicit user decision:

- 15³ = 3,375 interior basis; 16³ = 4,096-site computational state domain
  (user-approved); 721-cell shell. Interior preparation zeros shell
  amplitudes; shell participation is Hamiltonian-coupling-dependent.
- Label census `[421, 422, 422, 422, 422, 422, 422, 422]`; signed origin
  `(0,0,0)` = index `(7,7,7)` = e0. `prepareUniformInterior` does not
  normalize caller amplitude (norm = `3375·|amp|²`).
- Canonical coloring is `basisAt` in `redox_scaling_tiers.zig`. QComms
  `state()` is `LABELING_VERSION = 2`, aligned to it; `legacyState` /
  `legacyDigest` preserve version-1 reproduction. Never silently
  reinterpret a historical digest.
- The 8 signed-integer i-vector components are metadata, NOT the 4,096
  state amplitudes. No projection between them is established.
- Measurement contract v1 (`src/lattice_measure.zig`): the site
  observable covers all 4,096 sites; the e-label observable covers the
  eight interior classes only — shell sites belong to no label
  eigenspace and are projected out by `collapseToLabel`. Selectors are
  deterministic u64 draws (`maxInt(u64)` rejected); `measureLabel` is a
  Lüders projection plus renormalization. These are declared software
  semantics, not apparatus validation.
- Both transit-phase conventions (increments 1 and 3 eighth-turns) stay
  selectable; eight-step closure does not choose one. They are distinct
  from the interference-phase API.
- E8: the 240-root octavian overlay is verified; the direct adjacency-
  preserving 15³-cell→E8 embedding is `unsupported` (degree ≤6 vs 56,
  scoped to the named graphs). Equal counts (`15×16=240`, `721=3·240+1`)
  are arithmetic, not geometric ownership.
- φ/π are dimensional-position axioms from the ladder; the
  position→equation bridge remains a formalization obligation.
- Reversibility: the rounded side-2 stencil collision is documented;
  basis-norm preservation is not global injectivity. A lattice-native
  reversible transition is open.
- `0^0 = i` roles stay distinct nodes (empty product, e0 density,
  RamseyIdentity vacuum, checksum pivot); the checksum palindrome
  `E=mc² ↔ i ↔ E=mc⁻²` is centered on the i-vector fixed point.

## Provenance law

- Donor trees are read-only. Never edit, build-in-place, or vendor them.
- Record source paths plus SHA-256, or mark explicitly unpinned.
- Nested/vendored copies are lineage, not independent confirmation.
- Ported `redox_*` modules are the knowledge import; prefer extending
  them over re-deriving from donors.

## Retro-dev micro-loop

For every change: establish the passing baseline → change one seam → run
focused tests → propagate registry/docs → run the full suite
(`zig build test` + fmt + diff + float scan). Roll back on regression.
Never silently resolve an open architectural choice — document the
decision point and ask for the source/equation.

## Continuity

- Docs must stay synchronized with code and evidence status in the same
  edit (README.md, PHASE-QUANTUM-AUDIT.md, registry, audit module).
- Worktree carries substantial uncommitted work — preserve it exactly.
  Do not commit or push unless explicitly asked.
- Archive law: never delete passing work or evidence-carrying files.
- When context resets, re-read this file, then `README.md`, then
  `PHASE-QUANTUM-AUDIT.md` §"Cross-project semantic and dynamics
  reconciliation", then the registry — in that order.

## Doc map

| doc/module | covers |
|---|---|
| `README.md` | architecture, contracts, verification |
| `PHASE-QUANTUM-AUDIT.md` | evidence ledger + open questions |
| `src/axiom_registry.zig` | claim nodes/edges/statuses |
| `src/axiom_derivation_audit.zig` | per-axiom emergence paths |
| `src/generative_chain.zig` | verified algebra/count chain |
| `src/lattice.zig` | canonical 15³ tensor + invariants |
| `src/qcomms_lattice.zig` | aligned QComms labels + legacy |
| `src/lattice_qbit.zig`, `src/quantum/` | qbit state/evolution lane |
| `src/qsharp_adapter.zig` | Q#-vocabulary adapter (not a runtime) |
| `src/reversible_probe.zig` | classical reversible gates |
