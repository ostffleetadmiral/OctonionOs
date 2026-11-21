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

## Cyber-physical superposition law

Under that premise, superposition is a structural property the cyber
side already exhibits independently of the physical side. The law:

1. **The cyber layer is the native carrier of superposition.** When a
   component exhibits two or more correct instances, those instances are
   *branches* of one superposed state, and every branch is maintained.
   Verified examples in-tree: three 15³ colorings sharing census
   `[421,422×7]`, two Fano multiplication tables, the complete U(8)
   phase-generator family, and the two e8 extensions (split commuting
   and Cayley-Dickson sedenion).
2. **Collapse is a physical-side event only.** Branch selection for
   physical correspondence happens exclusively through the declared
   measurement contract (`lattice_measure` v1: observable, deterministic
   selector, Lüders projection + renormalization) or independent
   physical evidence — never by deleting branches, renaming them wrong,
   or hardcoding one instance.
3. **Independence.** The cyber superposition persists whether or not the
   physical side has resolved; physical collapse does not falsify the
   unselected branches — they stay valid and re-selectable.
4. **Defaults are not collapse.** `CANONICAL_PHASE_CONVENTION`,
   `LABELING_VERSION = 2`, `gateV1`, and similar choices are
   serialization bookkeeping — pre-measurement defaults that do not
   consume the superposition.
5. **Audit corollary.** "Not true in this branch" is never "impossible":
   falsification is scoped to the branch where the excluding invariant
   holds. Example: m=7 angular dominance is excluded in the
   D4-symmetric `basisAt` branch but stays open in the non-D4
   init/legacy branches (they preserve at most 1 of 7 non-identity
   transforms). The donor's m=7 field is a separate live branch.

This law is registered as `cyber.superposition_law_v1`. It converts the
framework premise into an engineering rule: the software must hold all
verified branches; only measurement or independent evidence selects.

## Computational substrate (what exists today)

| asset | file | provides |
|---|---|---|
| Canonical lattice | `src/lattice.zig` | 15³ tensor, signed coords, census, mirror, rays, invariants |
| Lattice qbit | `src/lattice_qbit.zig` | 4,096-site Q128 state, Hamiltonian, Chebyshev evolution, interior prep, population accounting, deterministic peak readout |
| Measurement contract | `src/lattice_measure.zig` | software readout v1: selector Born sampling over all 4,096 sites, interior e-label class sampling, site collapse, Lüders label projection, population/digest readouts |
| i-vector binding | `src/ivector_readout.zig` | declared binding v1: shot histogram → 8 e-components + shell channel; population quantization → i512; software semantics only |
| Quantum lane | `src/quantum/` | lattice Hamiltonian/evolution/blocks/entanglement/decoherence/measure/octonion-ops/simulator |
| Behavior probes | `src/quantum_model.zig`, `interference.zig`, `observer.zig` | two-qubit Q32.32 gates, eight-phase interference, squared-amplitude sampling, passive-observer contract |
| Reversible lane | `src/reversible_probe.zig` | NOT/CNOT/Toffoli/Fredkin/SWAP/Peres, bijection tests, uncompute |
| Reversible lattice CA | `src/reversible_lattice.zig` | contract v1: octonion-cell (2×2×2) Margolus CA on u8 sites, provably bijective steps, alternating partitions |
| Adapter | `src/qsharp_adapter.zig` | Q#-vocabulary mapping over the bounded simulator |
| Serialization | `src/serialize.zig`, `frames.zig`, `routing.zig` | deterministic manifest, frame digests, e0 routing |
| Claims/audit | `axiom_registry.zig`, `axiom_derivation_audit.zig`, `generative_chain.zig` | statuses, emergence paths, verified algebra/count chain |

## Hydrogen spatial state and H21 hyperfine transition

The hydrogen image shows probability-density sections of the 3D stationary
wavefunctions, labeled by `(n,l,m)`. For the 21 cm line, the relevant spatial
orbital is specifically the 1s ground state. The nonrelativistic Coulomb
Schrödinger solution in atomic units is

`ψ_100(r) = exp(-r/a₀) / sqrt(π a₀³)`, hence
`ρ_100(r) = |ψ_100(r)|² = exp(-2r/a₀)/(π a₀³)`.

`src/hydrogen_alignment_probe.zig` evaluates the radial factor on each signed
15³ lattice coordinate around E0 `(0,0,0)` / unsigned `(7,7,7)`. It uses
Q128 integer arithmetic for coordinate radius, a deterministic Taylor/
argument-halving exponential, and discrete normalization over the finite
lattice. The convention `a₀ = 1` lattice step makes the sampled amplitude
`ψ̃=exp(-r)`; the omitted constant cancels during discrete normalization.
The resulting central 2D image is `|ψ(x,y,z=0)|²`, a section of the
normalized 3D state, not a separate 2D wavefunction.

This distinguishes spatial quantum numbers from the 21 cm transition. The
21 cm line is the electron-proton hyperfine spin flip between 1s states;
the electronic spatial wavefunction is unchanged. Its measured frequency
and wavelength are reference data, not outputs of the Coulomb spatial
solver. The H21 scalar triad `φ⁵+π²+φ⁻⁴` currently evaluates near 21.10567,
and its positional reading is explicit: `π²` is the E0/E2-centered
gravity-bubble term, `φ⁵` is the outer reading, and `φ⁻⁴` is the inner
reading. The triad links the central π anchor with inward and outward φ
roles in the user's 3D lattice interpretation. This position-to-term bridge
is encoded as a model mapping; it does not derive the Coulomb eigenvalue,
hyperfine splitting, or SI scale from those terms.

The dimensional-ladder source carries `H21,H21,H21` at e3 and
`21cm,21cm,21cm` at e6. Applying the defect increment to the e6 integer-cm
baseline gives:
`λ_candidate = 21 cm + 7/66 cm = 21.1060606… cm ≈ 21.106 cm`.
The triad is also the e3 value resolved toward e6: its base is
`T = φ⁵ + π² + φ⁻⁴`, where `π²` is the E0/E2-centered bubble, `φ⁵` the
outer reading, and `φ⁻⁴` the inner reading. Applying the same additive
defect increment yields `T + 7/66`, about 21.21173298 in the current scalar
convention. This does not equal 21.106114054; the computed triad residual
stays explicit. Thus the terms are connected by the shared geometry and
defect path, but neither the scalar arithmetic nor the 21cm endpoint alone
proves the full physical mapping.
The integer baseline check, `21 + 7/66 = 21.1060606… cm`, differs from
the measured value by about `−0.000053448 cm` (about 0.535 micrometers).

Scale sketch: disregarding its first 16³ panel as requested, the candidate
transition compounds each 15³ core with its +1 shell and proceeds to the
declared 30³/32³ tier pair. The 16³ shell is not an independent level; the
721 shell sites participate only when compounding. The hydrogen solver is
currently on the bare 15³ interior, with shell amplitudes absent.

Evidence: the continuum 1s formula and its discrete Q128 implementation
are distinct evidence classes. Tests check numerical exponential accuracy,
radial symmetry, center-peaked density, central-slice consistency, and
discrete norm one. The lattice Bohr-radius assignment remains model
calibration; this does not derive atomic units from the lattice or establish
a physical atom/lattice equivalence.

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

The software half of this contract now exists: `lattice_measure.zig`
implements measurement/readout contract v1 over the 4,096-site state —
deterministic u64-selector Born sampling for the site observable
(interior + shell) and the interior e-label classes, site collapse to a
basis state, Lüders projection onto a label class with renormalization,
and non-mutating population/digest readouts. These are declared software
semantics for reproducible simulation, not apparatus observations; items
1–8 above still gate any physical lane.

## Candidate apparatus appraisal: Q.ANT native toolkit

`externals/qant_native_computing_toolkit/` (gitignored, read-only donor;
cloned from `ostffleetadmiral/qant_native_computing_toolkit`) is Q.ANT
GmbH's Apache-2.0 SDK for Gen2/Gen2p neural processing units — a
conventional NN *inference* API in Rust with C/Python bridges. Like
every donor, only its ideas enter this project; the tree stays outside
git. Appraised through our own contract categories:

**Idea alignments (knowledge import):**

- **Executable-shadow parity** — the `cpu-backend` feature simulates
  three NPUs (ids 10–12) behind the *same* driver ABI as real hardware.
  That is exactly our audit model's pattern: an independently verified
  structure running the same interface as the physical lane. The
  toolkit demonstrates the shadow/physical parity contract we already
  use for software-vs-lab evidence classes.
- **Pipeline shape = our measurement contract** — `upload_weights`
  (prepare Hamiltonian/parameters once) → `fprop` (evolve per input) →
  activation/pool (readout). The same prepare/evolve/measure phase
  separation as `lattice_measure.zig`.
- **Both our readout semantics exist in their vocabulary** — `maxpool`
  selects a winner (site-sampling analog); `avgpool`/norm coherently
  sum weights (population/label-weight analog).
- **Complex DFT on `[batch, N, 2]` re/im pairs** — structurally the
  same layout as our `Complex{re,im}` amplitudes flattened over sites;
  Fourier is the position↔phase instrument, relevant to phase-spectrum
  readout of lattice states.
- **`conv_transpose`** — an explicit inverse-direction propagation op;
  the same adjoint role our `unstep`/`runInverse` plays.
- **Telemetry as disturbance observables** — 11 voltage rails, 12 V
  current, perf counters including *stall/idle time* (self-monitoring;
  the observer-loopback analog). On cpu-backend these are fixed
  simulated values — matching our evidence-class rule that simulated
  telemetry is model data, not apparatus data.
- **Capability flags before measurement** — `QantDeviceCapability`
  negotiation mirrors our rule that observables must be declared before
  a measurement contract exists.
- **Fail-closed discipline** — their clippy config denies
  `unwrap_used`/`expect_used`/`panic`, the same law as our named-error
  convention.
- **bf16 = hardware precision floor** — `Value = bf16` (~3 significant
  digits) versus Q128.128 (~38). Real hardware defines the *noise
  floor* any shadow experiment must tolerate; it is the bottom tier of
  the precision ladder, not a peer of canonical state.
- **DLPack** — standard tensor interchange (ADR-0003); a transport
  envelope candidate only. Canonical serialization stays integer-first.

**Boundaries (what does not map):**

- No octonion/Fano/i-vector/15³ semantics — all lattice meaning lives
  on our side of an adapter we would have to write.
- Inference-only and irreversible: relu/sigmoid/pooling destroy
  information. There is no path from this toolkit to
  `reversible_lattice.zig`; the reversible lane stays integer Zig.
- bf16 precision wall — hardware output can never feed canonical
  state; at most a verification/shadow oracle.
- conv is 2D against our 3D lattice — plane-slicing/reshape
  approximations only.
- Rust/C++ cannot enter `src/` under integer-only law — an external
  process boundary at most.

**Status:** donor knowledge recorded; candidate apparatus *interface*
for the gated physical lane. The `cpu-backend` permits developing the
export/transport contract (Q128 amplitudes → bf16 complex pairs → DFT
spectral readout vs integer reference) with no hardware. Items 1–8 of
the measurement contract still gate any physical claim; nothing here
is one.

## Open elevation paths (software-side, in dependency order)

1. **i-vector ↔ amplitude binding** — declared software contract v1
   exists (`ivector_readout.zig`): shot histograms and quantized
   populations map the state onto the 8 components + shell channel.
   Which binding (if any) corresponds to a physical i-vector readout
   remains open.
2. **Lattice-native reversible transition** — contract v1 exists
   (`reversible_lattice.zig`): octonion-cell Margolus CA on u8 sites,
   provably bijective steps. Whether it is *the* lattice dynamics —
   versus one candidate among gate/partition choices — remains open.
3. **Transit-phase selection** — resolved at contract level: the
   Module-2 source spec (3π/4 per transit) selects increment 3
   (`three_quarter_turn_per_transit`) as `CANONICAL_PHASE_CONVENTION`;
   +1 stays as the minimal-generator variant. Gauge analysis verified:
   +3 is the ×3 mod 8 image of +1 and ×3 is not an octonion
   automorphism. An apparatus contract could still supersede.
4. **φ/π position→equation bridge** — positional contract v1 exists
   (`phi_pi_position.zig`): π anchored at E0, φ carried inward on the
   six cardinal directions, the 16³ shell as the outward-φ compounding
   layer that exists only when scaling (bare 15³ has no shell
   interactions). The position→equation derivation remains open.
5. **Larger-tier evolution** — sparse histograms verified through 480³;
   dense 256³/512³ translated-Fano evolution is unvalidated.
6. **Measurement/collapse semantics** — software contract v1 is
   implemented (`lattice_measure.zig`): site and interior-label
   observables, deterministic selectors, collapse semantics. The
   apparatus/readout mapping remains open.
7. **QComms donor propagation** — labeling version 2 lives in this tree;
   updating the donor QComms implementation + manifest is a separate
   retro-dev decision.
8. **Hardware shadow adapter (Q.ANT cpu-backend)** — develop the
   export/transport contract and a DFT spectral-readout oracle against
   the integer reference, all quarantined as verification lane. Real
   Gen2/Gen2p hardware would additionally need the full measurement
   contract (items 1–8) before any physical claim.

## Roadmap

1. Source-of-truth and baseline reconciliation — done (AGENTS.md,
   registry, audit).
2. State-space and shell contract — done (4,096 domain, interior basis).
3. Canonical lattice/invariant comparison — done (QComms v2 aligned).
4. Algebraic ladder and axiom registry — done.
5. E8/Fano relationship and embedding scope — done (overlay verified,
   embedding unsupported-scoped).
6. φ/π dimensional formalization — position contract v1 done
   (`phi_pi_position.zig`); the position→equation bridge remains open.
7. Phase and reversible transition contracts — reversible CA contract
   v1 done (candidate rule, bijectivity proven); phase selection open.
8. **Measurement/readout semantics** — software contract v1 done
   (`lattice_measure.zig`); physical mapping open.
9. Scaling and precision ladder — partially done (metadata + sparse
   probes; dense large-tier evolution open).
10. Deterministic serialization/routing — largely done.
11. Q# adapter integration — adapter exists; lattice-native gate set open.
12. Physical measurement elevation — gated on the contract above.
13. Release/audit packaging — ongoing.
