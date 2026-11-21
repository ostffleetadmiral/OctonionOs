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
  `scaled_lattice_probe.zig`, `image_claims_probe.zig` structure/scale
  lanes.
- `sidecar/` — the only f64 lane (`quad_smith.zig` Shirley mapping +
  quantized table). Keep it isolated.
- `examples/` — currently empty.
- `README.md` — user-facing architecture and contracts.
- `PHASE-QUANTUM-AUDIT.md` — evidence ledger, donor inventory, physical
  boundary, open questions.
- `1.md` — working notes: verbatim historical engineering directives
  (provenance), the live spec sections at the top, then dated append
  notes mirroring major findings. `PHASE-QUANTUM-AUDIT.md` is the
  evidence ledger — the same findings land in both, dated in 1.md and
  ledger-styled in PHASE-QUANTUM-AUDIT; keep the mirror consistent.

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
- `basisAt` in `redox_scaling_tiers.zig` is the canonical coloring for
  the QComms lane: `state()` is `LABELING_VERSION = 2`, aligned to it;
  `legacyState` / `legacyDigest` preserve version-1 reproduction.
  Under the superposition law three colorings share the census —
  the qbit label observable, frames, serialize, and routing read the
  `Lattice.init` branch (see the pipeline-continuity rule below).
  Never silently reinterpret a historical digest.
- The 8 signed-integer i-vector components are metadata, NOT the 4,096
  state amplitudes. `ivector_readout.zig` declares software binding v1
  (shot histogram → 8 components + shell channel; population
  quantization → i512); it is a declared convention, not a physical
  projection claim.
- Measurement contract v1 (`src/lattice_measure.zig`): the site
  observable covers all 4,096 sites; the e-label observable covers the
  eight interior classes only — shell sites belong to no label
  eigenspace and are projected out by `collapseToLabel`. Selectors are
  deterministic u64 draws (`maxInt(u64)` rejected); `measureLabel` is a
  Lüders projection plus renormalization. These are declared software
  semantics, not apparatus validation.
- Transit-phase contract v1 (`lattice.CANONICAL_PHASE_CONVENTION`):
  `three_quarter_turn_per_transit` (+3 eighth-turns = 3π/4 per the
  Module-2 source spec in `1.md`) is canonical; the declared family is
  the complete unit group U(8) = {1,3,5,7} — +1, +3, +5, +7 all
  generate the full cycle, with +7/+5 the negated images of +1/+3.
  Even increments are sub-cycle sequences, not conventions. The +k
  sequence is the element-wise ×k mod 8 image of +1; ×k is not an
  octonion automorphism, so label-coupled consumers can distinguish
  them. Serialization still requires explicit selection. Distinct from
  the interference-phase API.
- E8: the 240-root octavian overlay is verified; the direct adjacency-
  preserving 15³-cell→E8 embedding is `unsupported` (degree ≤6 vs 56,
  scoped to the named graphs). Equal counts (`15×16=240`, `721=3·240+1`)
  are arithmetic, not geometric ownership.
- φ/π position contract v1 (`phi_pi_position.zig`): π is anchored at
  E0 (origin site); the state's 1D φ is carried inward along the six
  cardinal directions; the 16³ compounding shell (any coord == 15,
  721 sites) carries the outward-φ role and exists only when scaling —
  the bare 15³ has no shell interactions. The position→equation bridge
  remains a formalization obligation; no magnitudes are assigned.
- Compounding law (user-supplied): the 16³ domain matters only when
  compounding; scaling adds the 16³ layer to every 15³ block — one +1
  shell layer per canonical block, so canonical pairs satisfy
  `shell − inner = inner/15` (15/16, 30/32, 60/64, 120/128, 240/256,
  480/512). The unsigned 0..15 coordinate frame (interior 0..14, +1
  shell faces) is the canonical compounding frame; signed [-7,+7] is
  the interior description, not a separate domain.
- Pipeline continuity (`e2e_continuity_probe.zig`, registry
  `pipeline.e2e_continuity_v1`): index conventions bridge by
  COORDINATE, never raw index — `h.idx/coords` is 16³ x-fastest,
  `indexUnsigned/index` is 15³ x-fastest/signed. Branch binding is
  measured, not assumed: the qbit label observable + frames + serialize
  + routing read the `Lattice.init` branch; QComms `state()` reads
  `basisAt`. Whether serialized manifests need an explicit branch tag
  is a recorded open lane — do not silently normalize it.
- Hydrogen spatial probe: numerical Q128 shadow of the nonrelativistic
  1s Coulomb solution, sampled and discretely normalized on bare 15³;
  `a₀=1` lattice step is uncalibrated. Keep the 21 cm hyperfine spin
  flip separate from its unchanged spatial state.
- Preserve dimensional-ladder field triples separately: e3
  `H21,H21,H21`, e6 `21cm,21cm,21cm`; do not collapse them to one
  radial coordinate. Track the supplied `7/66` additive increment on the
  e6 integer-cm baseline and on the full e3 H21 triad as separate ladder
  evaluations, preserving both residuals and the shared π/φ geometry.
- MOUND triad table (`mound_triad.zig` + generated
  `mound_triad_table.zig`): the donor's 145-constant
  `T=φ^a+π^b+φ^c` table verified in Q128.128 — 144 evaluable + 1
  target-underflow (Planck time), 0 failures, 130 within 1%, worst
  2.71%. Positioning-derived corrections were tested and rejected:
  residuals are signature-fit noise, implied bases cluster at
  canonical φ/π within 0.01%. Do not claim triad corrections or
  physical validity from the fit.
- Lattice-native constant screening (`lattice_constant_audit.zig`):
  represented scales are indexed 0, 2, 3, 4, 5, 6, 7 with sides
  15, 32, 64, 128, 256, 512, 1024. Scale 1 is skipped; 16³ is only the
  scale-0 compounding shell, never a standalone tier. The 42 integer/Q128
  candidates are compared with target magnitudes and signed triad
  evaluations without fitting. Raw numerical proximity across mixed units
  is never a physical derivation; target-conversion underflows and triad
  evaluation underflows are separate evidence counts.
- Two scale indexings coexist; never conflate them. The diagram/donor
  "qubit ladder" (`image_claims_probe.imageScale`) uses the canonical-pair
  chain — interior `15·2^s`, compounding shell `16·2^s`, qubits `8^s`
  canonical blocks. The constant audit uses power-of-two interiors — audit
  side at index k equals the image chain's shell side at index k−1.
  Möbius/mirror z-face identifications are label-compatible only at odd
  inner sides and are label-invisible (verified); no boundary transform
  on dynamics is implemented. Every slice's label field is D4-symmetric,
  so its angular harmonics are `m ≡ 0 (mod 4)` only — a dominant m=7
  harmonic is impossible for `basisAt` and belongs to donor ψ-field
  simulation data. Axiom-7 discretization is verified: `round(T)=F₀=21`
  with 0.503%/0.0021% residuals; ladder tier coordinates are integer
  rationals over F₀=21.
- Reversibility: the rounded side-2 stencil collision is documented;
  basis-norm preservation is not global injectivity.
  `reversible_lattice.zig` contract v1 is a declared candidate
  (octonion-cell Margolus CA on u8 sites, periodic boundary, provably
  bijective steps) — classical byte lane, distinct from the Q128
  state; `gateV1` and partition choices are conventions, not derived
  unique dynamics.
- `0^0 = i` roles stay distinct nodes (empty product, e0 density,
  RamseyIdentity vacuum, checksum pivot); the checksum palindrome
  `E=mc² ↔ i ↔ E=mc⁻²` is centered on the i-vector fixed point.
- **Cyber-physical superposition law** (user-supplied premise:
  everything is inherently quantum): the cyber layer is the native
  carrier of superposition — when a component exhibits two or more
  correct instances, those instances are branches of one superposed
  state and all are maintained. Collapse is a physical-side event
  only: branch selection happens exclusively through the declared
  measurement contract (`lattice_measure` v1 — observable,
  deterministic selector, Lüders projection + renormalization) or
  independent evidence — never by deleting branches or declaring them
  wrong. The cyber superposition persists independently of physical-
  side resolution; physical collapse does not falsify unselected
  branches — they remain valid and re-selectable. Defaults are not
  collapse: `CANONICAL_*`/`LABELING_VERSION`/v1-suffixed choices are
  serialization bookkeeping, not measurement. Audit corollary: "not
  true in this branch" is never "impossible" — falsification is scoped
  to the branch where the excluding invariant holds.
  Current examples: the E8 root presentations (`112+128` standard and
  `16+112+112` octavian, both exact); the two scale indexings
  (canonical-pair `15·2^s` vs the constant-audit power-of-two chain);
  the dual H21 exponent bindings (e-label ray sites vs ladder tier
  roles); the dual `7/66` correction bases (`21+7/66` integer-cm and
  `T+7/66` e3→e6); the three 15³ colorings sharing census `[421,422×7]`
  (basisAt L1-shells, `Lattice.init` tent ramp, `legacyState` v1 ramp —
  pairwise divergence 1980 / 3375 / 3375 cells; legacy's singleton sits
  at label 5); the two Fano multiplication tables (`{3,5,6}` redox and
  `{3,6,5}` hardware — units agree on all 49 pairs, sign differs exactly
  on {3,5,6} products); the phase-generator family U(8) = {1,3,5,7}
  (+7/+5 are the reversal images of +1/+3; even increments are
  sub-cycles, not conventions); the two e8 extensions (split commuting
  `e8²=+e0` and Cayley-Dickson `e8²=−e0` = `redox_sedenion.zig`,
  anticommuting, non-alternative, zero divisors). Superposition ends
  only when independent evidence resolves the branch.

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
| `src/e2e_continuity_probe.zig` | 17-seam pipeline continuity audit |
| `src/redox_sedenion.zig` | Cayley-Dickson e8 double (superposition sibling) |
| `src/image_claims_probe.zig` | image/diagram claims vs executable checks |
| `src/lattice_constant_audit.zig` | scale-0..7 native-constant screen |
| `src/hydrogen_alignment_probe.zig` | hydrogen 1s spatial alignment probe |
