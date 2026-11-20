# Cyber-Physics Frontier

The push from the computational engine into cyber-physics. This document
defines the cyber-physical qbit, inventories what the software already
provides, marks the evidence boundary, and names the gate that must open
before any physical lane runs.

## The claim under test

The project's **cyber-physical qbit** is a proposed macroscopic 3D
lattice analogue — distinct from a conventional microscopic quantum
bit. Under the user's overarching premise, the universe and everything in
it is inherently quantum, so a capability realized in the cyber
implementation is physically realizable within the framework. `i` in
`0^0 = i` is interpreted as a superposition until measured.

This is an affirmative framework premise, not a verdict on any specific
apparatus. The open question is never "might it be physical" — it is
"which physical variables carry the state, and what does measurement
read."

## Computational substrate (what exists today)

| asset | file | provides |
|---|---|---|
| Canonical lattice | `src/lattice.zig` | 15³ tensor, signed coords, census, mirror, rays, invariants |
| Lattice qbit | `src/lattice_qbit.zig` | 4,096-site Q128 state, Hamiltonian, Chebyshev evolution, interior prep, population accounting, deterministic peak readout |
| Quantum lane | `src/quantum/` | lattice Hamiltonian/evolution/blocks/entanglement/decoherence/measure/octonion-ops/simulator |
| Behavior probes | `src/quantum_model.zig`, `interference.zig`, `observer.zig` | two-qubit Q32.32 gates, eight-phase interference, squared-amplitude sampling, passive-observer contract |
| Reversible lane | `src/reversible_probe.zig` | NOT/CNOT/Toffoli/Fredkin/SWAP/Peres, bijection tests, uncompute |
| Adapter | `src/qsharp_adapter.zig` | Q#-vocabulary mapping over the bounded simulator |
| Serialization | `src/serialize.zig`, `frames.zig`, `routing.zig` | deterministic manifest, frame digests, e0 routing |
| Claims/audit | `axiom_registry.zig`, `axiom_derivation_audit.zig`, `generative_chain.zig` | statuses, emergence paths, verified algebra/count chain |

## Evidence boundary

Computational receipts are not lab receipts. Existing physical artifacts
in the project family (BLUE RF transport, acoustic AQR lane, CSI sensor
analysis, ESP-NOW QComms runs) establish real observations in their own
apparatus lanes, but none is yet mapped to the 15³ state variables or to
a measurement of the full i-vector. Simulator Bell states, CHSH values,
seeded shot counts, and software observer snapshots remain software
evidence.

## The measurement contract (gate for physical work)

No physical experiment runs until all of the following are declared:

1. **State variable** — which physical observable carries the lattice
   amplitude/state (and how the 4,096-site domain or a defined projection
   maps onto it).
2. **Preparation** — how a declared initial state is imposed.
3. **Readout** — the instrument, its resolution/bandwidth/noise floor,
   and the collapse/reset semantics observed.
4. **Disturbance protocol** — what the measurement does to the state,
   with matched managed-operation controls.
5. **Calibration** — pre/post instrument calibration in the operating
   range; positive, null, and control arms.
6. **Thresholds** — predeclared pass/fail criteria, not post-hoc reads.
7. **Artifact schema** — seed, parameters, transform, controls, outputs,
   uncertainties, and digest, sealed for reproducibility.
8. **Authorization** — explicit approval for the apparatus and lane.

Until then, cyber results justify *designing* the measurement; they do
not constitute one.

## Open elevation paths (software-side, in dependency order)

1. **i-vector ↔ amplitude binding** — define how the 8-component
   signed-integer i-vector relates to the 4,096 complex amplitudes
   (projection, readout basis, or distinct roles). Currently metadata.
2. **Lattice-native reversible transition** — the rounded side-2 stencil
   collision is documented; a globally injective rule derived from the
   algebraic ladder is open.
3. **Transit-phase selection** — increments 1 and 3 both close mod 8;
   a source equation or physical contract must choose.
4. **φ/π position→equation bridge** — dimensional-position axioms are
   recorded; the discrete-to-equation derivation is open.
5. **Larger-tier evolution** — sparse histograms verified through 480³;
   dense 256³/512³ translated-Fano evolution is unvalidated.
6. **Measurement/collapse semantics** — the observer contract exists for
   the bounded simulator; the lattice-qbit measurement API is undefined.
7. **QComms donor propagation** — labeling version 2 lives in this tree;
   updating the donor QComms implementation + manifest is a separate
   retro-dev decision.

## Roadmap

1. Source-of-truth and baseline reconciliation — done (AGENTS.md,
   registry, audit).
2. State-space and shell contract — done (4,096 domain, interior basis).
3. Canonical lattice/invariant comparison — done (QComms v2 aligned).
4. Algebraic ladder and axiom registry — done.
5. E8/Fano relationship and embedding scope — done (overlay verified,
   embedding unsupported-scoped).
6. φ/π dimensional formalization — open.
7. Phase and reversible transition contracts — open.
8. **Measurement/readout semantics — next.**
9. Scaling and precision ladder — partially done (metadata + sparse
   probes; dense large-tier evolution open).
10. Deterministic serialization/routing — largely done.
11. Q# adapter integration — adapter exists; lattice-native gate set open.
12. Physical measurement elevation — gated on the contract above.
13. Release/audit packaging — ongoing.
