# Octonion-OS Lattice Engine

Standalone Zig 0.13.0 project for an integer-first 15³ signed-coordinate lattice, a translated Fano label tensor, a quantized Quad-Smith table, sparse scaling metadata, and deterministic JSON export.

## Verification

```sh
zig build test
zig build test-core
zig build test-sidecar
```

The core uses integer data only. `sidecar/quad_smith.zig` performs f64 Shirley square-to-disk mapping and normalized impedance conversion, then quantizes the 225 central-slice entries at scale `1_000_000_000`.

## Sparse scaling tiers

The core lattice remains 15³ (3,375 nodes). In each axis, its signed local coordinate `[-7,+7]` is translated into core indices `[0,14]`; the 16³ container adds exactly one coordinate plane, either index `15` for positive padding or index `0` for negative padding. The signed True-Origin is preserved at index `7` or `8` per axis. The wrapper records `16³ - 15³ = 721` added cells without allocating a dense 4,096-cell volume. The three selected outer faces contain 3×16² cells, with their intersections shared; they are not the 721-cell volume difference. The remaining wrapper boundary is represented sparsely. “Insulation,” “communication,” and “quantum foam” are descriptive model terms only.

| qbits | dimensions | universes | base side | padded side |
|---:|---:|---:|---:|---:|
| 1 | 8 | 1 | 15 | 16 |
| 2 | 16 | 8 | 30 | 32 |
| 4 | 32 | 64 | 60 | 64 |
| 8 | 64 | 512 | 120 | 128 |

The qbit, dimension, and universe values are supplied symbolic metadata; the code checks exact 15-wide base-side multiples and power-of-two padding arithmetic only. The 30/60/120 base spans are not 16-stride tilings. Seam contacts do not derive entanglement or physical state transfer. Placement records are caller-supplied integer container origins in the global `[0,padded_side-1]³` frame, with independent per-axis padding direction. Full container bounds must not overlap. Face-adjacent and shared-cell contacts are represented distinctly; face side references and complementary shell direction are checked only on the contact axis, leaving tangential orientations independent. No canonical placement layout is assumed.

## Secondary E0 routing

There are exactly 420 eligible non-origin `e0` label sites; the geometric primary origin is immutable and excluded. The router keeps stable token IDs, occupied-slot reservations, and transient source/destination locks. A candidate must be a one-step axis transition between eligible sites. The tensor supplies node labels but no separate edge graph; the current tensor has zero axis-adjacent eligible `e0` pairs, so the router reports unsupported paths instead of inventing connectivity. Batch contenders for a destination are compared by Manhattan distance, lexicographic source `(x,y,z)`, then token ID. Valid competing requests report `.arbitration_lost`; invalid moves are reported separately and leave state unchanged. Reservations persist until a successful move; source/destination locks exist only during a committed transition. Core logic is integer-only; no impedance-derived collision behavior is implemented.

The JSON writer and SHA-256 manifest helper are in `src/serialize.zig`; serialization covers tier metadata, sparse shell data, caller placements/seams, tokens, and reservations. The lattice, Fano labels, Smith mapping, and tier registry are computational constructions; passing tests does not prove physical or quantum interpretations.

## Isolated quantum-behavior software probes

`src/quantum_model.zig`, `src/interference.zig`, and `src/observer.zig` form an isolated integer fixed-point validation lane. It tests a two-qubit Bell state using Q32.32 amplitudes, squared-amplitude outcome probabilities with caller-supplied selectors and explicit collapse, a minimal two-path same/opposite-phase intensity calculation, and passive immutable snapshot reads. It is separate from the 15³ lattice and its modulo-8 transit-phase options. The tests validate software contracts only: no physical quantum behavior, physical non-disturbing measurement, or lab certification is inferred. Details and donor provenance are recorded in `PHASE-QUANTUM-AUDIT.md`.

The project family traces its I-vector and downstream lattice work to the lattice axiom `0^0 = i` (`i` as information/imaginary unit); this is not being replaced by ordinary scalar exponentiation. Related sources include the full endpoint ladder, E0 observer mask, Möbius rule, scaling, E8, fine-structure, and Born-rule branches. Octonion-OS currently implements selected lattice arithmetic and simulator rules, not every family derivation. The audit records source variants—including conflicting coloring and scaling results in RedOx—and the remaining project-wide inventory.

## I-vector claim catalog and frame manifest

`src/ladder.zig` stores the supplied dimensional ladder from 0D/8Dᶦ through 10D, plus e0–e7 label metadata and a claim catalog. The audit treats the supplied full endpoint table and 15×15 slices as the comparison target and tracks donor variants separately. Each claim has a stable ID, verdict, probe, basis, and elevation path. Statuses distinguish verified executable behavior, corrected results, model metadata, REGISTER doctrine, unresolved/unresolvable questions, unsupported claims, and contradictions. `UNSUPPORTED` means no supporting artifact for that exact claim; it does not establish its negation. `CONTRADICTED` is reserved for a claim that fails its stated internal verifier. External source claims include inspected source/artifact hashes and narrow evidence limits. The field-bound source strings are retained verbatim; their units and endpoint semantics are unresolved. Observer status, qbit/universe counts, quantum-foam behavior, and physical compounding are not established by the software.

The donor inventory is broader than BLUE/JIZO and MOUND/EU: it includes Spec-007 and nested Qstar, RedOx, Rations, Sigma/vSuper, zig-k3-port/LuckyBastard, Digit, vGPU, and remote GVFS roots. Nested or vendored copies are provenance lineage, not independent confirmations. The review has also found source-version divergences: RedOx distinguishes two 421-deficit colorings, reports that the deficit does not persist across all larger tiers, and measures breaks under a numeric reading of some H21 endpoint transitions. These results stay attached to their exact implementation and interpretation; they do not replace the supplied lattice axiom or silently redefine 0D/8Dᶦ location identity. See `PHASE-QUANTUM-AUDIT.md` for details and the still-open source-by-source inventory.

The observer-shift permutation and `(direction XOR observer) mod 3` axis function are tested as discrete arithmetic. The claim catalog does not elevate their broader physical interpretations. The candidate E8 coordinate projection is recorded as `VERIFIED-WITH-CORRECTION` for the narrow result that this specific mapping fails its stated checks; this is not a claim that every possible E8 mapping is impossible. The adjacency comparison is scoped to the named graph relation. The 721 = 3×240 + 1 identity is arithmetic only and does not verify a geometric shell partition.

`src/frames.zig` extracts exactly 15 integer z-frames of 225 labels each and validates exact reassembly. Frame digests include layer index, signed z, pivot, mirror index, central flag, and all labels. The manifest serializes complete frames and reassembly validation.

### Transit phase contract

No transit phase convention is authoritative or implicit. Both candidates are implemented as modulo-8 integer eighth-turn increments:

| Convention | Increment | Residues after transits 1–8 |
|---|---:|---|
| `quarter_turn_per_transit` | 1 | 1, 2, 3, 4, 5, 6, 7, 0 |
| `three_quarter_turn_per_transit` | 3 | 3, 6, 1, 4, 7, 2, 5, 0 |

Each sequence returns to zero after eight transits. That arithmetic closure does not adjudicate which physical or architectural interpretation is authoritative. Callers must select a convention for serialization; `null` is rejected. The manifest records the chosen ID, increment, and cycle length. Layer pivot metadata is not transit phase.

### Manifest contract

The `octonion-os-wall-v2` manifest is a deterministic software artifact, not a physical validation result or hardware gate. It is generated only for validated state and an explicitly chosen phase. Its JSON is syntactically parsed in tests; string values are escaped; invalid router state and over-capacity placement inputs are rejected. Placements, seams, tokens, and graph edges are canonically sorted. The SHA-256 digest binds the declared lattice labels, Smith entries, phase selection, scaling/shell metadata, placements, seams, routing policy/tokens/occupancy/edges, frame digests, and claim/provenance/source text. It is an integrity checksum for this declared model state, not proof that the claims are physically true.

Routing retains conservative one-step axial mode (which has no eligible e0-to-e0 edges in this tensor) and supports a caller-supplied canonical undirected graph over eligible sites. The graph is explicit serialized input, not inferred from labels. BLUE's defect-line rule has a reproduced coordinate example but is not adopted for secondary-e0 movement because some candidate steps leave the eligible set.
