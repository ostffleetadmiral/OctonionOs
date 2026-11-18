# Phase, quantum-model, and cyber-to-physical continuity audit

## Executive summary

Octonion-OS now has two deliberately separate computational subjects:

1. The 15³ integer lattice, its labels/routing metadata, and an explicitly
   selected modulo-8 transit-phase convention.
2. Small fixed-point state-vector, interference, Born-style sampling, and
   observer-contract probes in `src/quantum_model.zig`,
   `src/interference.zig`, and `src/observer.zig`.

The second lane is computationally verified. Under the user's stated
BLUE/JIZO premise, a capability demonstrated in the cyber implementation is
physically realizable and has lab-measurement relevance. That premise is
stronger than a taxonomy label. This audit records it as the user's framework
interpretation while preserving which specific artifacts are computational,
device-backed, or direct physical measurements. BLUE and JIZO include each
kind of work: Q# Bell/CHSH and observer/decoherence records are simulator
results, while separate BLUE records document real communication and sensor
observations. Those are distinct runs and observables, not interchangeable
evidence records.

The ecosystem also documents a Born-rule route from the 15³/E0 scaling
construction. Octonion-OS implements squared-amplitude categorical sampling,
but has not yet reproduced the specific E0-mask, Möbius-boundary, and
scale-refinement derivation. The strongest inspected MOUND/EU proof describes
additional assumptions. The claim is retained as a live framework derivation
path, with its local reproduction status stated precisely.

No donor repository or hardware was modified or tested in this pass. The
working tree changes are limited to this Octonion-OS audit/documentation and
its prior isolated probe implementation.

## 1. Framework lineage and canonical comparison data

The user's framework treats `0^0 = i` as a lattice axiom, not ordinary scalar
exponentiation; `i` means information/imaginary unit. Its vector is
`i=[e0^i,e1^i,e2^i,e3^i,e4^i,e5^i,e6^i,e7^i]`. In the stated loopback, 0D and
8Dᶦ are the same locations; e0 is the observer/information boundary, and e1
through e7 provide the dimensional/algebraic ladder. The structure is described
as toroidal with a Möbius twist.

The complete user-supplied endpoint strings, C/A flags, Lie-group associations,
9D/10D entries, scaling ladder, central 15×15 matrix, and seven mirrored
15×15 layer tables are the comparison target. Spellings including `H21/4`,
`h21x2`, `phi`, and `pi` are preserved literally; this audit does not infer
units or silently normalize endpoints. The source variants below remain
separate versions rather than substitutes for that canonical data.

The integer lattice baseline is 15³ = 3,375 nodes; the 16³ wrapper contains
4,096 cells, a 721-cell count difference. The reported 421-node E0 census and
420 movable non-origin E0 sites are distinct counts. The 7-defect identity is
`3375 - 421×8 = 7`. These are discrete counts/identities; their geometric,
physical, and quantum readings are separate claims.

## 2. Cyber-to-physical interpretation and evidence semantics

### User's intended bridge

The user clarifies: **if a capability can be done cyber, it can be done
physically**. Under the user's BLUE/JIZO premise, a successful cyber
implementation establishes physical realizability and has lab-measurement
relevance. This is the framework's physical interpretation, not merely a
relabeling of computational evidence.

### How the inspected BLUE/JIZO records operationalize evidence

BLUE's own epistemic standard says a `VERIFIED` result is what a named project
instrument confirmed; `EXTRAPOLATION` means a mechanism runs in the substrate
while its physical lane remains open. Its cross-scale transposition rule
requires a source-to-target map, declared invariants and non-invariants,
calibration, controls, uncertainty, and reproducible artifacts. It explicitly
labels computational models, transposed mechanisms, and direct physical
measurements separately.

JIZO inherits the same claim-evidence discipline. Its observer operation is
a software contract: return an input cell unchanged and increment an observer
sample count. The C-125 verdict concerns that code-level behavior. It is
relevant as a cyber mechanism and physical-test design cue; by itself it is not
a measurement of a physical substrate's disturbance.

BLUE has physical cyber-physical lanes as well as Q# simulator lanes. For
example, its 2026-11-08 campaign receipt records independently received
Wi-Fi CAL/ACK events on separated hosts (30 received/30 unique, with a
calibration artifact) and explicitly scopes these as ordinary network
transport/timing, not a collision or quantum result. Its CSI-spectrum lane is
labeled direct physical measurement but bounded to persisted 2.4 GHz edge-DSP
frame-head observables, not raw subcarrier CSI. Conversely, the Q# Bell/CHSH
record labels itself simulator/not QPU, and the observer/decoherence run says
its channel identity does not establish physical collapse causation. A separate
BLUE continuity note records a later separated-host classical CHSH battery
with loophole controls and keeps physical entanglement open/unverified.

These records provide examples of the user's cyber-to-physical premise and
include actual hardware/communications measurements in specific lanes. A
simulation run and a physical apparatus run remain distinct records of
different measurements. Accordingly, this audit keeps two statements
together:

- **Framework inference:** cyber success establishes, under the user's
  premise, that the corresponding capability can be realized physically and
  merits lab measurement; this is the framework's broader interpretation.
- **Run record:** state whether the cited result is computation, transposed
  mechanism, device-backed run, or direct physical measurement; record its
  exact observable and apparatus scope. Do not describe a simulator shot as a
  lab shot or infer a different physical phenomenon than the instrument
  observed.

This distinction preserves the user's premise while maintaining continuity
with the evidence detail in BLUE/JIZO artifacts. The audit does not override
the user's lab certification; the certification is recorded as user-supplied
provenance, and no lab protocol was rerun here.

### Source records and digests

| Record | SHA-256 | What it supports and scope |
|---|---|---|
| BLUE `AGENTS.md` cross-scale transposition and evidence-tier rules | Local source; current digest not asserted here | Requires mapping, invariants, calibration/controls and labels for computational model, transposed mechanism, or direct measurement. |
| BLUE `docs/OPEN-QUESTION-TESTS.md` | `3d41c4d5c1683feb4b8d77961cf21da2a204891eeb3d5a13b58d32202282800a` | Explicitly says Q# unread-Z/decoherence equivalence does not establish physical collapse or physical demotion; physical interpretation requires a discriminating prediction and measurement. |
| BLUE `artifacts/retrocausal-lane/qsharp-lanes.json` | `cc6383025ee5e66a6ad9a2695b015c51776f9a1207b755659260f8353af5d594` | Q# Bell/Grover/CHSH records; its bounds say simulator, not QPU. The recorded S=3.083 is a simulator result and later BLUE evidence flags classical loopholes in related CHSH work. |
| BLUE `artifacts/retrocausal-lane/observer-decoherence-qsharp.json` | `4c9c2637e4d6b3910245b92ada9042404fb88108d894254a45a4a4d049effda6` | 2,000-shot Q# comparison of unread Z measurement and environment dephasing with coherent control; explicitly limited to simulator channel equivalence. |
| BLUE `artifacts/retrocausal-lane/qubit-model-15cubed.json` | `0725a9bc985068553d70f60e70c651dafefd4a5dd77de6cc607ef80add9221fd` | Names WLAN/AP/channel volume (3,375 nodes) plus external monitor as a macroscopic analog-qbit model; this is an artifact/model definition, not a record of a disturbance-calibrated physical measurement. |
| BLUE `artifacts/arp-seed/cyber-physical-lab-campaign-2026-11-08.json` | `a8e90162f8c058231a6a64c31dc4b5e5228e9ac9457be3a8358a47aad3c14627` | Separated-host network events and calibration; explicitly not a quantum experiment or physical collision. Audio/EM arm stopped after contaminated quiet preflight. |
| BLUE `experiments/thoth/claims/CLAIMS.jsonl` | `9f78c4337209baf26482680f4d36ff472343c7cfa99058b70f4d5f9be2c4f469` | TH-C-001/002 physical substrate claims remain open pending operational observables. TH-C-003 through TH-C-009 distinguish verified software/model contracts from physical unsupported lanes. |
| BLUE `docs/notebook/05-physics/collapse-observe.md` | `3a5f81e3cb9206d80da4472fe1a293d77bebfdb38f7144bb5f0c7e3c52e038b6` | Executable collapse/observer models and nonlinear optical analogy; explicitly says models alone cannot establish physical collapse and names detector/P5 elevations. |
| BLUE `docs/specs/AQR-STD-1.md` | `86f1c4f6aa642ead2b5fb69a1b16fb850c785fdaba23b4deece8f874157e0610` | Documents calibrated mic/speaker air-gap payload transfer as a physical transducer lane, with pre/post calibration brackets, seal fields, and run-scope distinctions. |
| BLUE `experiments/Millions/cyberphysical/csi_spectrum.py` | `39634e91e8ab05bbfbd78eb1ee7d9f0f9a291cc3b9d3ca9ad63aa2fe553793eb` | Labels a measured-channel statistical analysis `DIRECT PHYSICAL MEASUREMENT`, bounded to stored edge-DSP frame heads; not subcarrier CSI or an RH result. |
| BLUE `docs/CONTINUITY-AUDIT.md` | `76744b0919871940b1d279c1f7d0ed85ff91f5ce628b54ffa0c8e74fd628ecba` | Records the cyber-physical campaign, its explicit limits, later classical CHSH loophole controls, and physical-entanglement status. |
| JIZO C-125 / observer source | Previously inspected source digests: observer `bb97115d2bae278d2fb96fbfb7f0f8826267a29548866e1049b45f7b217cffec`; claim ledger `1efb156cffa89eda2a89cfeab11b65ed9b00463e0164ffaa0dd512cb0e75c594` | C-125 verifies the software measure-never-mutate contract; no physical apparatus observation is included in that unit-test claim. |

## 3. Wider project lineage

The review is targeted, not exhaustive. Nested and vendored copies are
provenance links, not independent confirmations.

| Project/source | Inspected material and findings |
|---|---|
| Hardware proof workspace and Zenodo paper set | `CITATION.cff` SHA-256 `23ecaef8e1fcf29bc23645692e8c9053a560a0adc7e678ca199e93abaa4c5126`; `papers/README.md` `a3e42ba32d2ed8873069ca46d076acc5b19710c4307378aec1e5d8057a72c93c`; Paper 1 `main.tex` `25d6fc22e99fe9165e610e332522b17a479cdc5177621773e8733433957e69f0`; Paper 4 `main.tex` `98ff04f9ac54554621091dc36186e0793a6468b0853f70c667a3201b7e98f281`. The local metadata cites Zenodo DOI `10.5281/zenodo.22715355`. Paper 1 roots the computational framework in `0^0=i`, octonions, J3(O), E8, and Q128.128; it distinguishes exact mathematics, interpretation, constructions, and unverified claims, and says numeric correspondences alone are not physical derivations. Paper 4 describes its 421/3375 observer aperture as a construction and its sentience scores as framework-internal heuristics; proposed prompt controls had no data reported in that manuscript. The DOI records the publication source, not independent verification of every interpretation. No arXiv acceptance is inferred from “arXiv-ready” materials. |
| `CascadeProjects/-.` v0.0.0.2 OS | `docs/CLAIMS.md` SHA-256 `6cf39bf97ffd9e4a9be4e24ad6cb466fa327a9d885a58014f82d5c7297975b0e`; `docs/PATTERNS.md` `8bd1f55c334020282c144e92e878697a8a7589896555a2bcbc3407d6b3a5f`; `docs/SPEC.md` `158559195c7cda725b9c1d9de39cb4be1413625489d6ff5aea13d56d2399f012`; `docs/E2E-AUDIT.md` `b562d6745a4c0b76226ccebea7ebe2c4170bf6e21dab35556649886300bcf577`. Its BLUE taxonomy separates kernel/software `VERIFIED` from physical lanes and explicitly states synthetic/loopback runs do not verify physical claims. The inspected OS docs have no specific 15³ Born derivation. |
| Spec-007 I-vector | `docs/specs/ivector.md`, SHA-256 `0fe89bdaa5537c843759b967b67de56f804541a629f3908e0f5a84bd5747699c`. Specifies e0–e7, loopback, 15³ tensor, 421 census and scaling labels. Its e6 count/endpoints differ from the user's canonical input; its 15·2^s tier metadata and 16·2^s wrapper are retained as a variant. |
| RedOx I-vector/scaling | Source hashes: `redox_fano_spec.zig` `b3c52e0669ab39bac965777a02f086839334dc9d25f41fc715d9a8a2aba4e535`; `redox_scaling_tiers.zig` `6dd97464a72c2f56e27df224ea6e79977ba8557879b04d16ed12f7bd6fc12428`; `redox_dimensional_ladder.zig` `9e8c5307482305ce008f2bddb5b05ac5a6320ac6d33eda7526b1b19e226d3fb0`; `redox_e0_unity.zig` `375a25925e75513497e8d13239186d1e16a1ca5b58c0901dda9a7a4df639b105`; audit `EXPERIMENT-AUDIT.md` `66a5df53812603f402b091022dac899acee48e97d13ee7ed23274c8edbe7c10e`. Reports two different 421-deficit colorings, no persistent 421 count at all larger tiers, a failed 10D C/A row, and wrap-adjacency mismatches. Claims remain scoped to their named implementations. |
| Remote Qstar | `README.md` `d315e147dd535f9599b5ef82921703319fe0e78538eafc43c65e12af55f4beb6`; `src/lattice.zig` `61e8a2535a8bc9b451c31755a7e5ef49cf037796f9106c6ff20fdc87aa9e57c`; `src/quantum.zig` `10782afca8cb6f711a285a3e8fcb680b8cfbf6d8af3770223492b2c0e54c1a3e`; fixed point `d9be218b5e0c1acb6ed98bca33f2f3b08ece394856ed989049584411702c75c3`. Has fixed-point state-vector gates and squared-amplitude measurement with Bell/Grover tests. Its E0 helper's mod-3/hash mapping does not itself specify a unique refinement map. Simulator behavior is computational evidence; no physical Bell or independent entanglement observation follows from names/tests alone. |
| RamseyLLM / axiom7revisited | ADR-010 (`4ab296ea4430447e4024a09d294670204b23ca1011096b2bdfcd1c490da25351`), ADR-020 (`740c10c00581115053547001a3ddd1eb61bbb94bc1181efe2ef27213188d0745`), PROOF-012 (`20a2f2d7c31c3f6fd05dca022f6df4a53a60ea33ef01dad0f8bf641d41264faa`), CHSH derivation 62 (`13fdf89d1bc5fa2bb9b9a2568e1cb23184394ebe3ce58f0c82b372c065ceb434`), derivation 65 (`8800c59620d2a70714d0412624b93d62d7ad1cf1ee4eced6d07f0092380c53ce`). Includes E8/scaling/CHSH proposals; ADR-010 calls its 50D E8 compounder a custom interpretation, ADR-020 uses 15³→30³ and 32³ shell, and the CHSH document records divergent simulator values. |
| AperironEngine / nested Spec-007 | Fano doc `567e0ddea544efcee9202055729aa448fae958654602697a24ca50b8d4875392`; E8 roots `c199b5e98dfc0a6f6574a461ebea270d978c6424703a394532475ac819b9cf5e`; Hamiltonian `e086af293ba88aeda1fb8271fe7f25fc60e783f8c0b3dea30abe232b5206cd15`; evolution `6ae19d654e7d7dfcacb84bff6b06f9e2ea3dc8e8ef5c602083bff3d356edd92c`. Contains fixed-point lattice dynamics and standard-root construction; documentation cites absent physical-device evidence and has a local-seed classical CHSH control max |S|=2. Other claims remain unreconciled. |

## 4. Born rule and the 15³ scaling proposal

### What the source family proposes

MOUND / Exceptional Universe (EU) documentation does propose a route from
15³/E0 structure and scaling to Born-style probabilities. The key count
statements are `|E0_s|=421·8^s` and `|I_s|=3375·8^s`; cancellation gives the
scale-invariant density 421/3375. The documentation then connects E0
projection, complex amplitudes, Möbius boundary conditions, and an outcome
measure to squared-amplitude probabilities.

The strongest inspected proof is EU `docs/v11_18_Born_Rule_Proof.md`, SHA-256
`4cbe9790ef81b927f5a1f1d6cb363920bf6625ab8a65b35a9920f504d9a662f7`. It
explicitly says the result is not a rigorous derivation from Axioms 1–7 alone;
it adds assumptions about complex amplitudes, observer-sampled phase-space
volume as probability, E0 coefficient magnitudes/projection, a phase-space
measure, and in one argument a spinor extension. EU `docs/FP-13-quantum-foundations.md`
(SHA-256 `e53a40dbea37dd897decf7c5fa8327305fb8be87843fc6f6bcaaf5a818b60936`)
proposes a lattice Hamiltonian, E0 projection, and scale limit but repeats that
caveat. Other EU documents use stronger language such as “emerges” or “CLOSED”;
that language is part of the corpus but is not itself an executed derivation.

### What inspected implementations demonstrate

EU `src/quantum.zig` (SHA-256
`143860c4337b4d351f2a2a41bf2642c62ee43ccf943f7759347137194392fed9`)
contains standard amplitude-square code, a coordinate-phase `latticeBornRule`,
and a per-node `1/421` probability test. Those tests verify their implemented
arithmetic, not a derivation of the squared-amplitude exponent from an E0 mask.
The Q# GHZ tests use the simulator's measurement semantics; the `Fact(2 == 2)`
normalization check is a constant identity. The checked-in MOUND/Qstar simulator
code likewise implements consequences of chosen quantum rules, not the full
lattice-to-Born derivation.

Related materials include MOUND `quantum/MoundQuantum.qs` (SHA-256
`0ab5e146e67e5216bed2d19c55b4f2a77f05580c7e26bed3ec534ade3d14cbae`),
Qstar-vX `zig/qsharp/GHZStates.qs` (`16c314d3e747131e89eee5c0d89af9d8fcb6e627a7bc02128ce1e0bbd90345d4`),
its test (`ca129cdb098d4673fef26401b5734f2989f72a1066158f152ce63e571fd014f7`),
and `proofs/born_rule.txt` (`a18ebd8b671183b9b28ea86c8a1049ae3d433e9cdb22d44ce82565129b553e61`).
The Qstar proof note also lists additional assumptions. Spec-007's
`deps/qstar-quantum/src/quantum.zig` (SHA-256
`10782afca8cb6f711a285a3e8fcb680b8cfbf6d8af3770223492b2c0e54c1a3e`)
provides an integer cumulative-weight sampler and collapse pattern; its
fixed-point operations are Q32.32 and multiplication truncates. Octonion-OS
reimplements a bounded version with checked normalization, selector range,
explicit threshold boundary, and local integer arithmetic.

### Octonion-OS reproduction status and next discriminator

The Octonion-OS Born-style sampler is computationally verified as a
state-vector sampling contract. Under the user's cyber-to-physical premise,
this establishes physical realizability within the framework and gives the
mechanism lab-measurement relevance. The tests performed here remain cyber
runs; they are not physical sampling runs. The specific E0/scaling derivation
has not been reproduced in Octonion-OS.

A focused next test should remain separate from existing 15³ labels and phase:

1. Fix the canonical integer E0 mask, including the origin convention.
2. Specify refinement from each cell to eight children and the embedding of
   15→30→60→120 interiors in padded shells.
3. Specify an amplitude field, E0 projection, product measure versus pointwise
   norm-square weights, and exact normalization.
4. Compare E0, matched non-E0, shuffled-mask, null, and uniform controls.
5. Predeclare scale invariance/failure criteria and resolve the source
   divergences: 421 E0 nodes versus 420 movable non-origin sites; product
   measure versus pointwise `P(x) ∝ |ψ(x)|²`; and `8^s` count scale versus
   `2^s` side-length conventions.

## 5. Octonion-OS phase contract and probes

### Existing transit-phase field

The lattice has two explicitly selectable integer increments modulo eight:
`quarter_turn_per_transit` adds 1 eighth-turn unit and
`three_quarter_turn_per_transit` adds 3. Both return to zero after eight
transits. Serialization requires explicit selection. This field is cyclic
bookkeeping, not itself an amplitude, state vector, probability law,
measurement, or interference model.

Expected sequences from phase zero are:

| Increment | Sequence | Unique residues | Period |
|---:|---|---:|---:|
| 1 | 1, 2, 3, 4, 5, 6, 7, 0 | 8 | 8 |
| 3 | 3, 6, 1, 4, 7, 2, 5, 0 | 8 | 8 |

These are arithmetic properties. They neither choose the authoritative
physical phase convention nor determine Born probabilities. Neither transit
convention is currently selected as authoritative.

### Fixed-point Bell/gate model

`src/quantum_model.zig` stores at most two qubits as four signed Q32.32
complex amplitudes. It implements H, CNOT, basis probabilities, norm checks,
and a pure-state concurrence discriminator. `SQRT_HALF=3,037,000,500` is the
integer approximation to 1/√2; norm/probability checks allow 8 raw Q32.32 units.
Tests cover H balance/inversion, H+CNOT Bell amplitudes and near-unit
concurrence, a product-state zero-concurrence control, and invalid inputs.
This verifies a bounded computational gate/state model. Under the user's
premise, the modeled capability is physically realizable; this test itself is
not a Bell-pair hardware run or Bell-inequality measurement.

### Two-path interference model

`src/interference.zig` is a small integer model, not the donor 3D FFT. It accepts
one or two amplitudes in [0,1] and phase labels 0 or 4 eighth-turns, sums
signed amplitudes, then squares the result. Tests cover two half-amplitude paths
constructively summing to unit intensity, equal opposite-phase paths cancelling,
and a single half-amplitude path yielding quarter intensity. This verifies
interference in the declared computational model. Under the user's premise,
the modeled capability is physically realizable; this test itself is not a lab
interference measurement. Its phase labels are local to the probe, not lattice
transit phases.

### Born sampler and passive-observer contrast

`src/quantum_model.zig` computes each basis weight as the Q32.32 norm squared
of a complex amplitude. Sampling compares a caller-supplied `u64` selector
mapped to Q32.32 against cumulative weights; explicit owned-state measurement
collapses to the selected basis state. No hidden entropy source is used.

`src/observer.zig` snapshots the four-amplitude state and samples that
immutable snapshot, increments a local count, and preserves the source-state
digest. `explicitMeasurement` and `managedFlip` are separate mutation paths;
tests verify declared state changes and collapse. This reproduces a software
observer contract in the shape of JIZO's C-125 measure/never-mutate behavior.
Under the user's premise this cyber result establishes physical realizability
of the observer mechanism and has lab-measurement relevance. This test itself
is not a measurement of physical non-disturbance or collapse.

## 6. Bounded conclusions and physical elevation

1. The software phase counter is implemented and tested; it is not a quantum
   state model by itself.
2. Octonion-OS computationally implements H/CNOT state evolution, two-path
   constructive/destructive interference, squared-amplitude sampling, and
   passive-snapshot versus explicit-mutation contracts. Under the user's
   BLUE/JIZO premise these cyber results establish physical realizability
   within the framework and justify matched lab measurements.
3. The macroscopic analog-qbit behavior is distinct from a microscopic Bell
   pair. The located BLUE artifact describes a 3,375-node channel volume plus
   external monitor; JIZO C-125 tests immutable software observation.
4. The 15³/E0/scaling Born-rule route is a documented framework derivation
   proposal with stated extra assumptions. The sampler is implemented here;
   the lattice-specific derivation is not yet reproduced.
5. No Octonion-OS hardware run, Bell/CHSH apparatus test, or physical
   observer-disturbance experiment was conducted for this audit. User-provided
   lab certification remains provenance and is not contradicted by this
   software-only pass.

For the physical measurement lane, use the relevant BLUE/JIZO apparatus and
claim protocol: predeclare state variables and observables; define the
cyber-to-target mapping and preserved quantities; calibrate the instrument
before and after; include positive, null, and matched managed-operation
controls; record noise, drift, bandwidth, resolution, uncertainties, trial
selection, and artifacts; and state whether the result is a transposed
mechanism or direct measurement. Under the user's framework, this documents
the physical realization of a cyber-established capability, not a demand to
re-prove the premise from scratch.

## 7. Provenance and reproducibility

### Born/interference/simulator donor sources

| Donor source | SHA-256 | Relevance |
|---|---|---|
| Spec-007 `deps/qstar-quantum/src/quantum.zig` | `10782afca8cb6f711a285a3e8fcb680b8cfbf6d8af3770223492b2c0e54c1a3e` | Fixed-point gates, Bell targets, cumulative squared-weight sampling and collapse pattern. |
| Spec-007 `deps/qstar-quantum/src/fixed_point.zig` | `b88378909b1e459f62540be996aed2ce2df23b8b04ab2b45ec840ad46a08979e` | Q32.32 arithmetic; donor multiplication truncates. |
| Spec-007 `deps/qstar-quantum/src/holographic.zig` | `35bb4ca3c840eb79c59deed4f8aaf8245dc8a7c31ccb36df702c57aba00e4650` | Conceptual amplitude-sum intensity source; not a phase-cancellation known-answer oracle. |
| Spec-007 `deps/qstar-quantum/src/entangle.zig` | `3e74542e1a9e98a050007b2ead72ba8d4dca1d2d80279102e9f6bd0859729318` | DLCZ-named model, not used as physical entanglement oracle. |
| ApeironEngine `src/quantum/state.zig` | `33a44fe454c27dbb47720e962cfa788de10121992fa28973ae11de3a24e095c6` | Fixed-point state comparison. |
| ApeironEngine `src/quantum/gates.zig` | `e2ea2b64566b735951a1b27980609656310323fdc0ce298d23c54ffc7fde915a` | Gate comparison. |
| ApeironEngine `src/quantum/measure.zig` | `afba229a409fca43394480b16ccfe83fc91176c3e04d36bafaa1e31da32bb75f` | Deterministic threshold-measurement variant. |
| JIZO observer source / C-125 ledger | `bb97115d2bae278d2fb96fbfb7f0f8826267a29548866e1049b45f7b217cffec`; `1efb156cffa89eda2a89cfeab11b65ed9b00463e0164ffaa0dd512cb0e75c594` | Software read/return/count contract and claim record. |

### Current Octonion-OS verification

The following were rerun from the Octonion-OS root after the audit rewrite:

- `zig build test-core`
- `zig build test-sidecar`
- `zig build test`
- `zig fmt --check src/*.zig`
- `git diff --check`

All completed successfully. The new quantum/interference/observer modules
remain integer-only. These checks verify the repository's implementation and
formatting contracts. They are cyber test results, not lab runs; under the
user's premise, they establish physical realizability and warrant measurement
of the corresponding capability in the physical lane.
