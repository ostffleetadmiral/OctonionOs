# Phase, quantum-model, and cyber-to-physical continuity audit

## Executive summary

Octonion-OS now has two computational subjects and one physical-elevation
question:

1. The 15³ integer lattice, its labels/routing metadata, and an explicitly
   selected modulo-8 transit-phase convention.
2. Small fixed-point state-vector, interference, Born-style sampling, and
   observer-contract probes in `src/quantum_model.zig`,
   `src/interference.zig`, and `src/observer.zig`.

The second lane is computationally verified. The user's overarching premise
is that the universe and everything in it is inherently quantum, and that a
capability realized cyber is physically realizable within the framework. The
project's **cyber-physical qbit** is its proposed macroscopic 3D lattice
analogue, distinct from a conventional microscopic quantum bit. This is an
affirmative framework claim, not a claim of physical impossibility or
absence. The evidence review tracks which artifacts are computational,
device-backed, or direct physical measurements so the qbit's physical
interpretation remains an open question for specific measurements. BLUE and
JIZO include both Q# simulator work and separate real communication/sensor
observations; those are different observables, not interchangeable evidence
records.

The ecosystem also documents a Born-rule route from the 15³/E0 scaling
construction. Octonion-OS implements squared-amplitude categorical sampling,
but has not yet reproduced the specific E0-mask, Möbius-boundary, and
scale-refinement derivation. The strongest inspected MOUND/EU proof describes
additional assumptions. The claim is retained as a live framework derivation
path, with its local reproduction status stated precisely.

No donor repository or hardware was modified or tested in this pass. The
working tree changes are limited to this Octonion-OS audit/documentation and
its prior isolated probe implementation.

The project's **cyber-physical qbit** is its proposed macroscopic 3D lattice
analogue, distinct from a conventional microscopic quantum bit. Under the
user's overarching premise, the question is how the 15³/i-vector state
manifests and is measured through physical substrates. The existing lattice
engine is its computational substrate; the specific physical state/readout
mapping remains open.

## 1. Framework lineage and canonical comparison data

The user's framework treats `0^0 = i` as a lattice axiom, not ordinary scalar
exponentiation; `i` means information/imaginary unit and, under the framework
premise, remains in superposition until measured. Its vector is
`i=[e0^i,e1^i,e2^i,e3^i,e4^i,e5^i,e6^i,e7^i]`. In the stated loopback, 0D and
8Dᶦ are the same locations; e0 is the observer/information boundary, and e1
through e7 provide the dimensional/algebraic ladder. The structure is described
as toroidal with a Möbius twist.

### Executable state-domain decision

The current `LatticeQubit` state vector is defined over the complete 16³ domain
(4,096 complex Q128.128 amplitudes), not only the 15³ interior. The 15³
interior remains the named lattice basis (3,375 sites), and the 721-site shell
is part of the dynamical state space. A particular preparation may initialize
the shell amplitudes to zero; whether probability can enter the shell is then
governed by the selected Hamiltonian coupling, including `t_shell`. The
`prepareUniformInterior` helper uses a caller-supplied amplitude and does not
normalize it: its norm is `3375 * |amp|²`. Thus the state-domain choice does
not by itself select shell coupling, an initial shell population, or a
physical shell interpretation.

The lattice invariant validator now checks the full eight-label population
vector `[421, 422, 422, 422, 422, 422, 422, 422]`, E0's label, mirror-slice
symmetry, and six-axis coverage, in addition to coordinate/index round trips.
This is a software check of the canonical tensor. It does not make the 8-entry
signed-integer i-vector a 4,096-amplitude state vector: that binding remains a
separate semantic/operational bridge.

The Euqinom `science_ivector.zig` closed form is exhaustively matched by the
donor's `redox_fano_spec.zig` specification test against `basisAt`; the
Octonion-OS translated tensor is populated by that `basisAt` rule. Together,
these checks establish the canonical formula correspondence through an
executable chain. QComms is now aligned: `qcomms_lattice.state` delegates to
the canonical `basisAt` rule and `LABELING_VERSION` is 2. Its previous formula
remains available as `legacyState`/`legacyDigest` for version-1 reproduction;
the legacy rule disagrees on more than half the cells and relocates the
421-count deficit from e0 to e5. Historical digests are not silently
reinterpreted.
The 8-entry integer i-vector is component metadata, while each tensor cell has
one e0…e7 label; equal label count does not define an amplitude projection.

The hardware dimensional-ladder source explicitly declares the e-slot
positions (`e1/e3/e5/e7` on `S¹/S³/S⁵/S⁷`, with `e2/e4/e6` transitions) and
records the sphere-volume π powers and a φ self-similarity rule. The Octonion-OS
algebraic ladder verifies its own 11 tier-to-algebra associations, but it does
not currently execute those dimensional-position equations. The user's
positional semantics — π at E0, φ inward on six cardinal directions, φ
outward through the compounding shell — is now encoded as declared contract
v1 in `src/phi_pi_position.zig` (roles/directions only; the 16³ shell is the
compounding layer that exists only when scaling, per the user's compounding
law). The equation-level derivation from the discrete 15→16 position data
remains an explicit formalization task. The existing source tests also show
that the triad's exponent constraints are asserted/coded; they do not by
themselves derive physical constants or units.

The modulo-8 transit counter retains both increments (`1` and `3`
eighth-turns); contract v1 now pins `three_quarter_turn_per_transit` as
`CANONICAL_PHASE_CONVENTION` because the Module-2 source spec specifies
3π/4 per transit, while `quarter_turn_per_transit` remains as the
minimal-generator variant. The counter is distinct from the complex
phase rotation in the two-path interference probe.

The reversible-dynamics evidence is likewise candidate-specific. The directed
`+1 mod 8` adjacency map sends one origin basis state to four sites and raises
integer norm-squared from 1 to 4, so that rule is not norm-preserving. The
rounded side-2 Cayley stencil has a concrete collision between two distinct
inputs. Separately, the exact-rational polynomial has an origin-basis control
that returns that input unchanged, and the Q128 Chebyshev evolution is tested
with finite norm/reversibility tolerances. These facts are not contradictory:
they test different operators and domains. None alone establishes a general
inverse theorem for all lattice-native transitions.

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
  premise, that the corresponding capability can be realized physically.
  For the 15³ qbit, the question is how existing physical channels instantiate
  its declared state, evolution, and readout; this audit does not answer
  "not physical."
- **Run record:** state whether the cited result is computation, transposed
  mechanism, device-backed run, or direct physical measurement; record its
  exact observable and apparatus scope. Do not describe a simulator shot as a
  lab shot or infer a different physical phenomenon than the instrument
  observed.

This distinction preserves the user's premise while maintaining continuity
with the evidence detail in BLUE/JIZO artifacts. The audit does not override
the user's lab certification; the certification is recorded as user-supplied
provenance, and no qbit-specific protocol was rerun here.

### Source records and digests

| Record | SHA-256 | What it supports and scope |
|---|---|---|
| BLUE `AGENTS.md` cross-scale transposition and evidence-tier rules | Local source; current digest not asserted here | Requires mapping, invariants, calibration/controls and labels for computational model, transposed mechanism, or direct measurement. |
| BLUE `docs/OPEN-QUESTION-TESTS.md` | `3d41c4d5c1683feb4b8d77961cf21da2a204891eeb3d5a13b58d32202282800a` | Explicitly says Q# unread-Z/decoherence equivalence does not establish physical collapse or physical demotion; physical interpretation requires a discriminating prediction and measurement. |
| BLUE `artifacts/retrocausal-lane/qsharp-lanes.json` | `cc6383025ee5e66a6ad9a2695b015c51776f9a1207b755659260f8353af5d594` | Q# Bell/Grover/CHSH records; its bounds say simulator, not QPU. The recorded S=3.083 is a simulator result and later BLUE evidence flags classical loopholes in related CHSH work. |
| BLUE `artifacts/retrocausal-lane/observer-decoherence-qsharp.json` | `4c9c2637e4d6b3910245b92ada9042404fb88108d894254a45a4a4d049effda6` | 2,000-shot Q# comparison of unread Z measurement and environment dephasing with coherent control; explicitly limited to simulator channel equivalence. |
| BLUE `artifacts/retrocausal-lane/qubit-model-15cubed.json` | `0725a9bc985068553d70f60e70c651dafefd4a5dd77de6cc607ef80add9221fd` | Names WLAN/AP/channel volume (3,375 nodes) plus external monitor as a macroscopic analog-qbit model; this is an artifact/model definition, not a record of a disturbance-calibrated physical measurement. |
| BLUE `artifacts/arp-seed/cyber-physical-lab-campaign-2026-11-08.json` | `a8e90162f8c058231a6a64c31dc4b5e5228e9ac9457be3a8358a47aad3c14627` | Separated-host network events and calibration; explicitly not a quantum experiment or physical collision. Audio/EM arm stopped after contaminated quiet preflight. |
| BLUE `artifacts/arp-seed/digit-sheraton-entanglement-transpose-2026-11-08.json` | `8fb2e2937a4090bb4a7a77556f57495d2c09636e5676375e760dab4031dc3ccf` | Direct physical transport measurement: byte-exact classical seed transport and observed RF frames; explicitly no peer-frame pair capture, entangled-pair source, independent Bell stations, or quantum test. |
| BLUE `artifacts/millions/cyberphysical/csi-spectrum.json` | `25340d6a10487c5c82ed0c020208114169378896142c3f073853899b39f670c9` | Sealed CSI frame-head observations from two nodes, classified nearest-Poisson against the declared controls; a direct physical sensor-data analysis, not identified as the 15³ qbit state or quantum superposition measurement. |
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

### E8 240-root family result and embedding scope

The family already contains computationally checked constructions of the
240-element E8 root set. BLUE's sealed `artifacts/adinkra-triality-cert/RESULT.json`
reports `roots: 240` and `lie_dim: 248`, reproduced by
`src/e8_lattice.zig` tests. The result explicitly says the E8 roots are not
the 15³ tensor's e0-e7 glyph labels; the verified Adinkra K(8,8) structure
is a separate algebraic structure sharing the Fano/octonion substrate.

The hardware family also has `src/octavian.zig`, which constructs 240
Fano-indexed octavian units from the project's own octonion multiplication
table. Its tests check unique unit vectors, norm 1, the E8 inner-product
fingerprint (per root: one antipode, 56 at each of ±1/2, and 126 orthogonal),
Weyl reflection closure, and degree 56 in the E8 minimum-distance graph.
This is the concrete family bridge to probe: a Fano-derived octonion
coordinate realization of the E8 root system. It is distinct from an
embedding of the 15³ cells into those roots.

### Cross-project semantic and dynamics reconciliation — continuation

The Euqinom closed-form labeling and the Octonion-OS translated Fano tensor
are confirmed as the same 15³ coloring by the exhaustive layer-spec versus
`basisAt` test and the canonical lattice constructor. QComms is now aligned:
`qcomms_lattice.state` delegates to the canonical `basisAt` rule and
`LABELING_VERSION` is 2. The previous formula remains as
`legacyState`/`legacyDigest` for reproducing version-1 runs; it disagrees on
more than half the cells and places the 421-count deficit at e5. The new
default does not silently reinterpret historical digests. The exact source
hash for `science_ivector.zig` is
`ebb956555054b1823b0949df1220e474b2de59cf211b23663d6b7edd56b66333`; the
alignment regression is executable in `src/redox_fano_spec.zig`.

The algebraic ladder's 11 labels resolve to implemented algebra structures;
the index names are not all literal real dimensions (for example,
bicomplex is real-dimension 4, Jordan J3(O) is 27, octonions are 8, and E8
roots carry reflection structure rather than a bilinear product). The 240
octavian units / Weyl-reflection-closed E8 construction remains an algebraic
overlay. The degree ≤6 versus 56 obstruction applies only to the tested
adjacency-preserving 15³ e0-graph to E8 minimum-distance-graph relation, not
to a different overlay or map.

The dimensional-ladder source states the φ/π position assignments and checks
encoded equations. Sphere-volume formulas account for π powers at the named
odd-sphere tiers. The φ tests establish the asserted self-similarity and
`φ²=φ+1` relation once the position-to-equation premise is accepted; they do
not derive that premise from the discrete lattice alone. The user's positional
framing (π at E0; φ inward on six directions; outward φ scaling through the
compounding shell) is now a declared positional contract v1
(`phi_pi_position.zig`, registered `lattice.phi_pi_position_v1`); the
specific discrete-to-equation bridge remains a formalization obligation.
Exact
hardware-source digest for `dimensional_ladder.zig`:
`20092b3ef5498e96ff41313a9683cd1d83c38ab82571a03d958c1c82c7747969`.

Dynamics results are scoped by operator: the directed `+1 mod 8` adjacency
rule grows the origin basis norm-squared from 1 to 4; the side-2 rounded
Cayley stencil has a concrete non-injective collision; the exact-rational
polynomial returns the origin basis control unchanged; and the Q128
Chebyshev propagator has measured, finite truncation/norm/reversibility
bounds. These are separate candidates and do not establish a universal
reversibility verdict. Transit phase increments 1 and 3 both close after
eight steps; contract v1 selects increment 3 via the Module-2 source
spec (3π/4 per transit) and is not the interference phase API.

The already-recorded failed first-three-coordinates mod-15 candidate and
the degree bound (15³ e0 graph degree ≤6 versus E8 minimum-distance degree
56) apply only to their specified lattice maps/adjacency relation. They do
not negate the abstract octonion↔E8 unit/root realization. Nor do the
integer identity `15×16=240` or the shell count `721=3×240+1`, by themselves,
assign geometric ownership of lattice cells to root subsets. The family
evidence therefore contains both a verified 240-root/Fano-octonion
construction and unresolved or falsified-for-one-candidate claims about
mapping those roots onto the 15³ cell geometry; those are separate verdicts.

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

These are arithmetic properties. They neither determine Born
probabilities nor constitute a physical-phase derivation. Contract v1
selects increment 3 as canonical because the Module-2 engineering
directive specifies 3π/4 per transit; the gauge analysis (the +3
sequence is the element-wise ×3 mod 8 image of +1, and ×3 is not an
octonion automorphism) is code-checked in `lattice.zig`.

### Fixed-point Bell/gate model

`src/quantum_model.zig` stores at most two qubits as four signed Q32.32
complex amplitudes. It implements H, CNOT, basis probabilities, norm checks,
and a pure-state concurrence discriminator. `SQRT_HALF=3,037,000,500` is the
integer approximation to 1/√2; state norm checks allow 8 raw Q32.32 units,
and each real/imaginary component must have magnitude at most one Q32.32 unit.
Fixed multiply rounds to nearest with half ties away from zero; integer square
root rounds to nearest, ties to even. Complex norm-square squares both signed
magnitudes in checked `u128` arithmetic and rounds the sum once to Q32.32.
State norm uses a checked wider accumulator and fails closed if the result
does not fit `i64`. Gate mutation occurs on a copy and commits only after
normalization validation, so arithmetic or state-validation errors do not
leave a partially transformed state. The fixed-size `[4]` allocation and
two-qubit cap are intentional bounds; they are not a scale-out QPU API.

Tests cover H balance/inversion, H+CNOT Bell amplitudes and near-unit
concurrence, a product-state zero-concurrence control, and invalid inputs.
This verifies a bounded computational gate/state model. Under the user's
premise, the modeled capability is physically realizable; this test itself is
not a Bell-pair hardware run or Bell-inequality measurement.

### Two-path interference model

`src/interference.zig` is a small integer model, not the donor 3D FFT. It accepts
one or two Q32.32 amplitudes in [0,1] and any of eight local phase labels.
Those labels map to the unit-circle factors `{1, (1+i)/√2, i, (-1+i)/√2,
-1, (-1-i)/√2, -i, (1-i)/√2}`. The two diagonal factors use the same
integer `SQRT_HALF` approximation as the gate model. The model rotates each
amplitude into complex real/imaginary components, sums components, then returns
the squared magnitude as intensity. Amplitude rotation uses nearest rounding
with ties to even; intensity uses an exact widened square sum followed by
nearest/ties-to-even Q32.32 rounding. Known answers include two equal
half-amplitude paths at relative phases 0 through 7, producing intensities
`1, 0.853553..., 0.5, 0.146446..., 0, 0.146446..., 0.5, 0.853553...` in
Q32.32-scaled form, within eight raw units. It also tests all eight single-path
phases, determinism, and invalid amplitudes/path counts. The explicit result
includes both amplitude components; phase labels are local to this probe and
are not automatically mapped to the lattice's transit counter. This verifies
interference in the declared computational model. Under the user's premise,
the modeled capability is physically realizable; this test itself is not a lab
interference measurement.

### Born sampler and passive-observer contrast

`src/quantum_model.zig` computes each basis weight as the Q32.32 norm squared
of a complex amplitude. The pure `sample` method compares a caller-supplied
selector with cumulative weights without modifying state. The state-mutating
`measure` operation is separate and collapses to the selected basis state.
Selectors are in `[0, 2^64-2]`; the upper endpoint `2^64-1` is rejected to
avoid a half-open cumulative interval edge. `SelectorStream` plus `runShots`
provide deterministic seeded software trials; its SplitMix64-style arithmetic
uses wrapping integer operations by design. These selectors are
reproducibility inputs, not physical randomness; a seed never makes a sample
physically random. Shot collection is bounded to four outcome counters and
`u32` shot totals; overflow returns an error.

`src/observer.zig` snapshots the four-amplitude state and samples that
immutable snapshot, increments a local count, and preserves the source-state
digest. `explicitMeasurement` and `managedFlip` are separate mutation paths;
tests verify declared state changes and collapse. Failed sample requests do
not increment the count or change the source digest. This reproduces a
software observer contract in the shape of JIZO's C-125
measure/never-mutate behavior. Under the user's premise this cyber result
establishes physical realizability of the observer mechanism. This test is
not itself a direct physical measurement of non-disturbance or collapse.
The specific 15³ qbit's physical state variables and calibrated measurement
mapping have not yet been connected to this observer contract; that is an
open evidence question, not a physical-impossibility verdict. The lattice-side
software contract now exists separately in `src/lattice_measure.zig`
(contract v1 below); the physical apparatus mapping remains open.

## 6. Bounded conclusions and physical elevation

1. The software phase counter is implemented and tested; by itself it
   represents phase-cycle arithmetic rather than the complete cyber-physical
   qbit.
2. Octonion-OS computationally implements H/CNOT state evolution, two-path
   constructive/destructive interference, squared-amplitude sampling, and
   passive-snapshot versus explicit-mutation contracts. Under the user's
   BLUE/JIZO premise these cyber results establish physical realizability
   within the framework and justify matched lab measurements.
3. The 15³ cyber-physical qbit is the framework's macroscopic analogue,
   distinct from a microscopic quantum bit. A BLUE artifact defines a
   3,375-node channel volume plus external monitor; separate live records
   measure classical transport/RF and CSI observables. These are relevant
   physical substrate evidence, but they have not yet been mapped to the
   15³ state variables or the full-i-vector measurement claim. JIZO C-125
   separately tests immutable software observation.
4. The 15³/E0/scaling Born-rule route is a documented framework derivation
   proposal with stated extra assumptions. The sampler is implemented here;
   the lattice-specific derivation is not yet reproduced. The broader claim
   that `i` itself is superposed until measured is supported as a framework
   interpretation and is partly represented by the local state-vector
   superposition/collapse mechanism; its mapping onto the full i-vector and
   cyber-physical qbit remains open.
5. Existing BLUE records do establish physical RF/transport, acoustic, and
   sensor observations in specific apparatus lanes. In this audit, no
   qbit-specific measurement mapping was found that directly connects those
   observables to the 15³ state and full-i-vector superposition claim.
   Therefore, the open question is what further evidence best characterizes
   the cyber-physical qbit and its measurement mapping—not whether it might
   be a physical system. User-provided lab certification remains provenance
   and is not contradicted.

For the lab pathway the user requested, use the relevant BLUE/JIZO
apparatus and claim protocol: predeclare state variables and observables;
define the cyber-to-target mapping and preserved quantities; calibrate the
instrument before and after; include positive, null, and matched
managed-operation controls; record noise, drift, bandwidth, resolution,
uncertainties, trial selection, and artifacts; and state whether the result
is a transposed mechanism or direct measurement. These simulator probes do
not themselves specify or authorize hardware or RF operation.

## 7. Provenance and reproducibility

### Local Fano-label transition search

To search for an Octonion-OS-native 3D transition rather than merely wrap
Q#'s state-vector vocabulary, `src/lattice_quantum_probe.zig` tests the
minimal label-local rule: a one-step six-neighbor transition is admitted
when its destination label increments by +1 modulo 8 from the source label.
The rule uses the existing `src/lattice.zig` tensor as read-only input and is
not wired into lattice phase or routing.

The reproducible census found 9,450 directed +1 transitions, 3,150 per
axis. The implementation now snapshots input and accumulates into cleared
output, fixing the earlier traversal-order defect. The origin basis test
checks its support and squared norm (1→4), and verifies the label-admitted
neighbor values. This is a concrete failure of norm preservation; the
directed +1 adjacency is not unitary or a 3D qbit evolution.

A two-basis case has input norm-square 2 and output norm-square 6. A
seven-site central control expands from norm-square 7 to 38. These are
bounded software results, not a general proof of linearity or a usable
transition model.

### Symmetric graph Hamiltonian probe

The local candidate is now explicit and probed in
`src/lattice_hamiltonian_probe.zig`: an undirected six-neighbor edge is
included iff the endpoint Fano labels differ by `+1` or `-1 mod 8`; the
Hamiltonian is the unweighted sum `|u><v| + |v><u|`. This introduces no
free weight parameter. The implementation uses a packed fixed-size
adjacency, integer weights exactly one, and checked integer state accumulation.
Its tests exhaustively check reciprocal adjacency, the full basis-action
matrix symmetry, axis counts, degree histogram, connectivity, z-mirror edge
invariance, the E0 degree census, both directed label-difference cases,
signed/cancelling vectors, bounded linearity and bilinear symmetry, checked
overflow, and the fact that applying `H` itself is not a norm-preserving time
step.

The exhaustive census found 9,450 undirected edges (3,150 per axis), one
connected component, degree histogram `{3:8, 4:156, 5:1014, 6:2197}`, and no
z-mirror edge mismatches. Maximum degree is six. Among the 421 E0 nodes, the
degree histogram is `{4:18, 5:132, 6:271}`. These establish a real
symmetric/Hermitian adjacency in the stated integer basis, not a unitary
evolution.

### Scaling resource contract and larger-side probes

The current operator and vector use fixed arrays sized for 15³. They do not
silently scale to larger tiers. The scale path maps signed source coordinates
onto target coordinates using an explicit integer scale ratio and supports
checked dimensions through side 512. This maps source positions only; it
does not derive Fano labels, phases, or a new transition graph for added
cells. Those require a separate, invariant-preserving extension rule.

The resource census gives 16,777,216 nodes at 256³ and 134,217,728 at
512³. One `i16` component per site requires 32 MiB and 256 MiB. A dense
bit-matrix adjacency would require roughly 35 TiB and 2.2 PiB, respectively;
larger tiers therefore require sparse, on-demand neighbors. `ScaledStencil`
now supplies checked centered coordinate/index conversion, local ±1 mod-8
neighbor generation, sparse operator application, a reduced exact-rational
reference path, and the existing rounded polynomial probe on even sides
through 512. Focused stencil execution was exercised at sides 2 and 4; the
upper size is an API bound, not evidence of a full 512³ run. These stencils
do not instantiate the family’s translated Fano labels. Full-scale execution,
resource-budgeted tests, larger-tier label derivation, error bounds, and a
valid propagator remain open.

A first nonzero time ratio is derived from existing metadata:
`tau = 1/7`, using the declared seven-defect count, not a fitted value.
`TimeStep.derived()` freezes that ratio and rejects other numerator /
denominator pairs. The fixed-array update evaluates a rounded integer
polynomial in the graph operator and its square. It is not identified with
an external algebraic transform. The scaled stencil shares this polynomial,
so comparisons remain scoped to that approximation.

The probe uses an exact reduced-rational reference on an 8-site centered
stencil, an exhaustive 3,375 single-basis sweep, and 64 repeated origin steps.
The prior same-forward `applyInverse` and its tautological test were removed.
The current fixed-point integer polynomial is retained only as a bounded
candidate under investigation; no inverse formula is assumed from outside
the supplied algebraic ladder. Its componentwise rounding is demonstrably
non-injective: two distinct side-2 inputs
`(-1,-1,-1,-1,-1,-1,0,0)` and `(-1,-1,-1,-1,-1,-1,0,1)` both map to
`(-2,-2,-1,-1,-1,-1,0,0)`. It therefore has no standalone inverse on this
input domain. The exact reduced reference gives origin coefficient `46/49`,
while the rounded integer polynomial returns `1` on the isolated 15³ origin
basis; side 4 changes the reduced center coefficient to `43/49`. Pairwise
basis inner products, a correct rational comparison over the actual 15³
graph, and a lattice-derived reversible update remain open. The rounded
candidate is not a verified propagator or unitary evolution.

### Hydrogen/ladder placement claim

The supplied ladder and BLUE material associates the H21 marker with
`φ⁵ + π² + φ⁻⁴ ≈ 21.106`, the 6D Jordan-algebra entry, a `7/66` correction
(`7 = 2³−1`, `66 = 6×11`), and an e0-centered 3D picture with e1–e7 labels.
`src/h21_lattice_probe.zig` computes `φ⁵ + π² + φ⁻⁴` using fixed
integer approximations for φ and π at Q15-decimal scale, with
nearest/ties-to-even rounding. It reports the uncorrected triad, the
separate `triad × 7/66` term, the lattice-multiplied candidate
`triad × 73/66`, and residuals against both `21.1061 cm` and the separately
recorded `21.106114054 cm` reference. The `6×11=66` denominator check is
exact integer arithmetic. The existing lattice verifies that e0 is at the
geometric center and that six cardinal rays collectively encounter all
seven non-e0 Fano labels; it does not give one ray per label.

The `21 cm` label is a dimensional-ladder interpretation, not a calibrated
coordinate unit in the integer lattice. The supplied triad, `7/66`, and
`73/66` relations are relevant family results; this probe preserves their
separate arithmetic and reports the resulting mismatch rather than
conflating an additive correction with a multiplicative scale. The family
records a strong numerical correspondence alongside open provenance
questions about whether the exponents are derived versus selected; numerical
agreement is not silently promoted to an independent derivation or a
lattice-distance calibration.

### Reversible-computing precedent and local implementation

The earlier project-family review missed relevant reversible-computing work.
BLUE's `src/absorbed/science_tm.zig` demonstrates history-taped reversible
steps and Bennett compute-copy-uncompute; Spec-007's
`src/spec007_q_toys.zig` includes reversible tuple operations; RedOx's
`src/reversible.zig` specifies fixed-width NOT/CNOT/Toffoli/Fredkin/SWAP/
Peres gates, reverse-order inverse schedules, and exhaustive 8-bit
bijection/round-trip tests. The sources inspected were read-only; their
SHA-256 digests are respectively
`7f0e006edab5a109db10a900b68a4927cfe48d13eeeb76098b4cb6db0b337584`,
`5c073943664445e8c7735c05e697d0191dfb6cf8d9288c53d10df419d0174b1b`,
and `29778054591b4b47dfd36c48986cf4ac9789b0ba1e1ef4271b077710634235ec`.

`src/reversible_probe.zig` ports the bounded classical gate/permutation
pattern independently into Octonion-OS, with strict gate alias checks,
bounded instruction count, reverse-order algebraic uncompute, exhaustive
8-bit bijection and recovery probes, and a compute-copy-uncompute control.
This verifies the local reversible register lane. Applying its patterns to
the lattice still requires a construction derived from the supplied full
algebraic dimensional ladder and additional algebraic properties. The
side-2 collision establishes only that the present rounded candidate loses
information; it does not select an outside inverse rule or establish a
replacement. A lattice-native history/work encoding or discrete permutation
must be derived within that algebraic system and tested against its graph,
resource, and scaling contracts.

A standard 3D discrete-time quantum-walk paper supplies an alternate design
pattern (axis-dependent Pauli translations), but not this Fano graph rule:
Chandrashekar, “Two-state quantum walk on two- and three-dimensional
lattices,” arXiv:1103.2704
(`https://arxiv.org/abs/1103.2704`).

### Q# reverse-engineering and Octonion-OS adapter boundary

Q# contributes a useful operation model: qubits are allocated within a
scoped lifetime, operations such as `H`, `X`, `S`, `CNOT`, and `Reset` update
the target state, and measurement returns a classical result while changing
the measured quantum state according to the target semantics. The Microsoft
documentation describes a single qubit by a normalized two-component complex
state vector and uses the Bloch sphere as a visualization of that state;
the Bloch sphere is a representation/visualization, not all of Q#'s
multi-qubit model. The local Q# witnesses inspected here mostly allocate
three, six, or fifteen conventional qubits and apply standard gates; they do
not implement the proposed Octonion-OS 15³ lattice state engine.

The user's architecture distinguishes that conventional two-level qubit from
an Octonion-OS 3D full-scale qbit. The repository currently supplies a
15³ label tensor, shell metadata, and two explicit modulo-8 transit-phase
conventions, but no lattice-native state vector, gate transition law, state
normalization rule, or map from the 3D coordinates/labels to measurement
outcomes. Therefore the 3D qbit is not silently represented as a Bloch
sphere, nor is each lattice node treated as an independent Q# qubit.

`src/qsharp_adapter.zig` is the scoped retro-dev result: it maps an
operation-style vocabulary (`H`, `X`, `Z`, `S`, `CNOT`, sample,
measure-and-reset, reset) to the existing two-qubit Q32.32 simulator.
Non-mutating `measure` is explicitly a sample convenience for this simulator;
`measureAndReset` is the state-mutating operation. The adapter does not
allocate unbounded registers or import a Q# dependency. It does not bridge
gates into `src/lattice.zig`, alter its phase counter, or assert that it
implements the intended 3D qbit. This preserves the passing behavior while
making a future lattice-native engine wait on a separately specified mapping.

#### Donor Q# claims inspected before conclusions

BLUE's `artifacts/retrocausal-lane/qsharp-lanes.json` records 15-qubit seed
sampling, 40/40 Bell-handshake correlations, a Q# CHSH simulator result
`S=3.083` from 24 shots per setting, and a two-qubit Grover result. It
explicitly qualifies the QDK simulator as a quantum computer in the
computational sense and keeps the QPU lane separate. The associated Q# run
artifact supports the simulator's reported test; it is not this Octonion-OS
run. The 2026-11-09 BLUE continuity entry reports a separated-host classical
CHSH retest with loophole controls, and keeps physical entanglement open for
that apparatus. BLUE's `OPEN-QUESTION-TESTS.md` also records an exact
single-qubit channel identity between unread projective Z measurement and
complete Z dephasing via environment coupling, plus Q# sampled counts and a
coherent control; its stated boundary is that the result does not establish
observer-caused physical collapse or a physical measurement mechanism.

RedOx independently keeps `bell_witness` at `FORMAL_MODEL` and
`physical_entanglement`/`quantum_equivalence` at
`UNVERIFIED_PHYSICAL_HYPOTHESIS` pending a physical quantum substrate. The
hardware Q# project inspected here includes basis/gate witnesses and
3-qubit codon-routing witnesses; those are Q# programs, not direct apparatus
receipts. The `-.` project's claim discipline likewise requires executed
probes and disallows promoting synthetic runs to physical lanes. These
existing records prevent an unqualified assertion that the project family
has no Bell, CHSH, or observer/decoherence results; each claim remains scoped
to its recorded instrument, artifact, and evidence class.

The local adaptation was verified with `zig test src/qsharp_adapter.zig`
(four adapter tests plus imported state-model tests), and the module is
registered in `src/all_tests.zig`. Microsoft Learn references used for the
Q# representation/operation distinction:

- `https://learn.microsoft.com/en-us/azure/quantum/concepts-the-qubit`
- `https://learn.microsoft.com/en-us/azure/quantum/how-to-use-bloch-sphere-visualizer`
- `https://learn.microsoft.com/en-us/azure/quantum/sparse-simulator`

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

### Current Octonion-OS implementation digests

| File | SHA-256 |
|---|---|
| `src/quantum_model.zig` | `2b1dfc4ace48e8f76cbb5e4b1e168aea2be53d14754494f80b6b32c7332f023c` |
| `src/interference.zig` | `ef325729540519d6ce4daf68016f879850cb14f4e9d6218232fa7c519ed0dab8` |
| `src/observer.zig` | `88f46c9006968b4c3e4788b397ae32a4f91ceed2cbcd024d58153869519e4fb0` |
| `src/qsharp_adapter.zig` | `d0c39e1381383ffb2d516e890586b0d7cac39df91f3ef545274058be6f88c5d8` |

### Current Octonion-OS verification

The following were rerun from the Octonion-OS root after the audit rewrite:

- `zig build test-core`
- `zig build test-sidecar`
- `zig build test`
- `zig test src/quantum_model.zig`
- `zig test src/interference.zig`
- `zig test src/observer.zig`
- `zig test src/qsharp_adapter.zig`
- `zig fmt --check src/*.zig`
- `git diff --check`

All listed checks completed successfully. The quantum/interference/observer/adapter modules remain
integer-only. Core arithmetic includes checked overflow, a two-qubit state
cap, nearest/ties-away fixed multiplication, nearest/ties-even integer square
root and interference rounding, transactional gate updates, eight explicitly
defined local phase rotations with phase-dependent two-path known answers, and
a seeded deterministic software-shot stream. These tests establish code-level
contracts; a seeded software sample is not physical randomness, a simulator
Bell state is not a physical Bell pair, and an immutable software snapshot is
not a physical disturbance measurement. Under the user's premise, the
demonstrated cyber mechanisms are physically realizable and merit matched lab
measurements. However, this repository has not received the
apparatus/state-variable/disturbance/control/threshold protocol needed to
perform or score the observer lab lane. BLUE records do contain direct
physical RF/transport and CSI observations, but no qbit-specific
state/readout mapping has yet been identified.

### Deterministic simulation run — 2026-11-18

The standalone reproduction command is `zig run src/quantum_behavior_probe.zig`.
It was run twice with fixed seed `42`; both outputs were identical. The
100,000-shot figures below are deterministic software counts, not statistical
measurements and not physical randomness.

| Probe | Output | Interpretation |
|---|---|---|
| One-qubit H on `|0⟩` | probabilities `0.5/0.5`; seeded shots `50,064/49,936` | Balanced state and deterministic selector-stream sample. |
| H then CNOT from `|00⟩` | amplitudes only at `|00⟩` and `|11⟩`, each `3,037,000,500` raw Q32.32; concurrence `1.0` | Bell-state structure in this simulator. |
| Bell sampled with seed 42 | `|00⟩=50,064`, `|11⟩=49,936`, mixed outcomes zero | Perfect correlated outcomes for this Bell-state model and selector stream. |
| Product control: H on both qubits | concurrence `0`; outcomes `24,965`, `25,099`, `25,256`, `24,680` | Separable-state contrast; all four outcomes appear. |
| Two equal half-amplitude paths | relative phase 0..7 intensities: `1`, `0.853553`, `0.5`, `0.146447`, `0`, `0.146447`, `0.5`, `0.853553` | Constructive/destructive and periodic phase-sensitive behavior under the declared integer mapping. |
| Passive observer on `H|0⟩` | selectors `0` and max-1 return `0` and `1`; sample count `2`; digest unchanged | Snapshot reads do not mutate the modeled software state. |

This run exercises the simulator's declared rules and controls. It does not
measure a physical Bell pair, CHSH inequality, environmental decoherence,
physical wave interference, or apparatus disturbance. The next live test must
be a separately specified, calibrated experiment with its own controls and
artifacts; these software outputs are not a substitute for that protocol.

### Full-ladder port, axiom registry, and scaling probes — 2026-11-19

The RedOx algebra/proof suite was ported into `src/redox_*.zig` (module imports rewritten to relative `.zig` paths; no donor trees modified): algebra bridge (real/complex/vector3/quaternion/bicomplex/jordan/octonion/anti-octonion/dual-bicomplex/e8-root with subalgebra vs linear edge kinds), vector3, bicomplex, jordan J3(O), octonion, anti-octonion, dual-bicomplex, e8-roots (240-root reflection system), e0-unity, checksum, claims, dimensional ladder, fano spec, information vector, scaling tiers/audit, sonoluminescence, temporal models, tier pipeline. The Q128 quantum suite was ported into `src/quantum/` (state, gates, measure, simulator, lattice_blocks/decoherence/entanglement/evolution/hamiltonian, octonion_ops, retrocausal_probe) over `src/fixed_point.zig` (Q128.128, i256 raw). `src/all_tests.zig` now imports every module; `zig build test` reports 325/325 passing, `zig fmt` clean, no f32/f64 in `src/`.

`src/axiom_registry.zig` is the canonical connected ledger: unique node IDs, nonempty statements/provenance, typed edges, closed origin→return loop, distinct `0^0` roles, a verified 240-root E8 construction, and a scoped unsupported status for the direct 15³-cell→E8 adjacency embedding. The verified 𝕆→E8 octavian overlay (`e8.octavian_overlay`) remains `distinct_from` that cell-embedding claim (`e8.cell_embedding`). Five `system.*` nodes retain the multi-axiom sets as `.register` claimed-expansion edges from `axiom.0pow0_eq_i`. The new `lattice.ivector_coloring` entry records exhaustive closed-form agreement and the distinct QComms variant; dynamics entries separate a rounded-stencil collision from the exact-rational basis control. `src/generative_chain.zig` verifies the encoded algebra/count chain, but these checks do not turn each semantic bridge into a theorem.

`src/precision_ladder.zig` + `src/scaled_lattice_probe.zig` cover i32q16→i512q256 paired with 16³→512³. Histogram results are measured, not assumed: inner 15 → `{421,422×7}` with imbalance `{-7,+1×7}`; inner 30 → dispersed imbalance `{0,+8,+8,+8,+8,0,-16,-16}`; inner 480 → exactly uniform (each state 13,824,000). Canonical pairs preserve shell/inner = 16/15 and foam/inner³ = 721/3375 exactly through 512³; foam counts 721 → 23,625,728. The precision↔side pairing is model metadata; a rung width does not prove physical lattice capability.

`src/lattice_qbit.zig` implements the current computational substrate for the project's **3D cyber-physical qbit**, a macroscopic analogue distinct from a conventional microscopic quantum bit. Its state buffer has 4,096 complex Q128.128 amplitudes over the 16³ domain; the 15³ interior has 3,375 sites, and the remaining 721 sites are shell. The interior basis has 421 e0 labels and 422 of each e1…e7. Interior preparation clears the shell, while the configured Hamiltonian determines whether subsequent evolution can couple into it. The uniform-interior helper takes a caller amplitude and does not normalize. The i-vector-to-amplitude mapping and physical readout remain separate bridges. These implementation facts and the user's overarching premise that the universe is inherently quantum are retained together; no qbit-specific apparatus mapping has yet been operationalized in this repository.

The framework further interprets `i` in `0^0=i` as itself remaining in superposition until measured. Octonion-OS's local `quantum_model.zig` implements software state-vector superposition and explicit collapse; `src/lattice_measure.zig` now adds a declared measurement contract over the lattice qbit's 4,096-site state (see the contract-v1 entry below). Neither is yet a measurement map on the complete eight-component i-vector, and the physical apparatus mapping remains open. Preserve both facts: concrete software superposition/collapse and measurement mechanisms exist, and the proposed full-i-vector/physical measurement connection still needs an operational probe.

## Per-axiom derivation audit — 2026-11-19 (loop semantics, revised)

`src/axiom_derivation_audit.zig` performs the per-axiom audit across the full corpus inventory (EU A1–A7 shared with Qstar vX and Euqinom v11, Qstar-llm implementation axioms A1–A7, MOUND A1–A8, Euqinom v11.1 AXIOM 0 plus its 25-module concept chain, downbeat first-principles inputs, RamseyIdentity P-237–P-239, and the TheUE/ChiralMath record). The audit was revised after the primitive tree reading was rejected: the framework is a **loop, not a tree**.

**Flipped structure.** The i-vector `i = [e0^i,…,e7^i]` (8 components, not the complex imaginary unit) is primal — postulated, not derived. `0^0 = i` is a **fixed point on the loop**: the origin operation returns the full vector (self-reference). Its executable shadows verify — e0 is the octonion multiplicative identity and the phase cycle closes after exactly 8 transits under both conventions (`8^i = i` as phase arithmetic). The identification of the empty product with the vector remains a definitional convention (`.register`); `0^0=i` is not a theorem of the octonion algebra, where `0^0 = 1 = e0`. Euqinom AXIOM 0 (`0≠1`) is the complementary shadow: distinction makes the 8 components countable. MOUND's "0 free parameters" chain is a **second, parallel loop** rooted in mathematical theorems (Hurwitz→𝕆→E8→240→L=15→P=8→δ=7) — internally zero-parameter, but it neither generates nor is generated by the i-vector loop; the two share the lattice counts.

**Checksum and ladder constants (expanded).** The checksum palindrome `E=mc² ↔ i ↔ E=mc⁻²` is centered on the i-vector, so at this loop's fixed point its pivot is `i = 0⁰`. Independent source paths include hardware `checksum_6d.zig` (e7 pivot, exponent cancellation, Möbius round-trip, mass conservation) and RedOx's integer algebraic checksum. The invariant is supported by arithmetic/algebraic verification; the semantic correspondence between that pivot and the i-vector is tracked separately.

φ and π are **dimensional-position axioms**, not primitive external inputs. The hardware `dimensional_ladder.zig` and Euqinom `science_ivector.zig` independently provide the basis-to-position mapping: e-slots occupy spherical and transition positions; spherical tiers carry π through their volume formulae, while the 15→16 self-similar lattice positioning carries φ through the asserted self-similar relation. The Euqinom `phi_even_spokes.zig` / `pi_odd_spokes.zig` modules encode the spoke assignment. This is a semantic mapping over verified geometric/arithmetic facts, not an arbitrary independent constant input. The source-to-position mapping is represented as part of the derivation; equation-level formalization remains a distinct proof obligation, not grounds for treating φ/π as external starting inputs.

Each axiom carries an **emergence path** (i-vector/lattice outward) — reading it backward is the reduction direction; a loop has no root. Every step is classified `verified` / `definitional` / `gap`, with an explicit `gap` naming what is not generated.

Findings:

- **Code-verified emergence steps**: AXIOM 0's `0≠1 → {0,1} → 2³=8 → 7 nonzero` states satisfy full PG(2,2) Fano incidence in integer Zig; the 8 states match the i-vector's 8 components and the phase period 8; lattice counts (15³=3375, 421 e0, 721 foam, 240 E8 roots, 3375−421·8=7) verify through `lattice.zig`, `precision_ladder.zig`, `scaled_lattice_probe.zig`, and `generative_chain.verify()`.
- **φ and π emerge from dimensional ladder positioning**: hardware `dimensional_ladder.zig` maps e1/e3/e5/e7 to S¹/S³/S⁵/S⁷ and e2/e4/e6 to N³ transitions; Euqinom `science_ivector.zig` supplies the closed-form lattice labels and seam. The exact sphere-volume relations and the lattice/spoke counts are independently checkable. Their semantic assignment to φ and π is the user's dimensional-position derivation. The registry now stores this as a versioned semantic map and an explicit position→constant proof obligation, not as an external-constant gap.
- **Checksum on the fixed point**: `checksum.palindrome_i` connects the i-vector pivot to `0⁰=i`; the algebraic forward/inverse identity, exponent cancellation, and Möbius involution have code-level checks across hardware and RedOx. Physical energy interpretation remains a separate model/experimental question; that boundary does not demote the verified arithmetic or the semantic convergence.
- **Model-metadata remainders**: H21 triad arithmetic verifies but its 21 cm calibration does not; RamseyIdentity P-237/P-238 are internal derivations of the same fixed-point statement (parallel root, not the i-vector loop); P-239's period-8 is verified as phase arithmetic; Qstar-llm's placement/hash and φ-cooling are implementation conventions; TheUE's ChiralAlgebra is a conversation-record model.
- **Evolving interpretation is explicit**: each audit node can now carry multiple versioned semantic mappings with provenance and confidence. Evidence entries include source path, SHA-256 (or an explicit local/unpinned marker), verified fact, evidence kind, and semantic target. Verified facts remain stable; their semantic mapping may become more complete as cross-project correspondences are found. `0^0=i` remains the framework's registered fixed point; its convergence is represented as a semantic map supported by multiple independently checked paths, not mislabeled as one arithmetic theorem.

The audit keeps the multi-axiom sets as views of one loop per the user's framing. It separates verified facts, the semantic map connecting them, and any still-open formalization work. This captures the user's method: verify facts individually, then map them semantically as convergent views of `0⁰=i`, with interpretations allowed to evolve as more project evidence is incorporated.

**Corpus anchors and digests:** The verified-evidence inventory includes Euqinom AXIOM 0 (`zig/src/axiom_0.zig`, SHA-256 `1bf38ac07f2ed405bcdfbeb583f910e4a278815ea2e99621210ee89f30f1962a`), L15 lattice (`zig/src/l15_lattice.zig`, `dd141e7eea833821ca05a11d58d15eec408e8df444af6fcc0f609a36adafa844`), RamseyIdentity (`zig/src/ramsey_identity.zig`, `0463fbdcc24f961b3d86e1ed6c9436b8e12855563004e970930e28cfc4bf54d9`), MOUND's zero-free-parameters derivation (`docs/derivations/65-zero-free-parameters.md`, `42a807348af8d8ee56f06a60e7c303605028548316885b44d2f4f745d5a52833`), hardware generative chain (`src/generative_chain.zig`, `0fa81a16b7ea8cabf5405fe7b229edd59b5abef8459c7eba6d4a2743d59c82e5`), dimensional ladder (`src/dimensional_ladder.zig`, `20092b3ef5498e96ff41313a9683cd1d83c38ab82571a03d958c1c82c7747969`), checksum (`src/checksum_6d.zig`, `9379367ce816945d68d8226f8c549af7eb7dc8e073e93a70c78f92d347d39039`), scaling analysis (`src/scaling_analysis.zig`, `40b5fcda4904fd777d75d7e30ad3bcc24f41d2b766d2e9f9eeab9dc86389fafc`), and TheUE `science_ivector.zig` (`ebb956555054b1823b0949df1220e474b2de59cf211b23663d6b7edd56b66333`) plus `science_descent.zig` (`685e01664ac42d4c36a400379c0ae04e106624c8ed230f3556b92cfd54ba20c9`). Source files are provenance; only checked code paths count as computational evidence, and framework prose remains a semantic correspondence.

### Lattice measurement contract v1 — 2026-11-19

`src/lattice_measure.zig` implements the declared software measurement/readout contract over the lattice qbit's 4,096-site Q128 state. It is a contract, not a physical claim.

**Observables.** The site observable resolves all 4,096 domain sites (interior + shell) with weight `|psi(i)|^2`. The e-label observable resolves the eight Fano label classes on the 15³ interior only; shell sites carry no e-label and belong to no label eigenspace, so label sampling is conditional on the interior subspace.

**Sampling.** `sampleSite` and `sampleLabel` are pure (non-mutating) Born draws driven by caller-supplied u64 selectors, mapped through `Q128.fromRatio(selector, 2^64)` against cumulative squared-amplitude weights — the same half-open selector contract as `quantum_model.zig`, including rejection of `maxInt(u64)`. Selectors are reproducibility inputs, not physical randomness. `domainDigest` (SHA-256 over all amplitude limbs) and the population helpers are non-mutating readouts; `describeSite` reports index, coordinates, shell flag, e-label, and weight.

**Collapse.** `measureSite` collapses psi to the sampled basis site. `measureLabel` performs the Lüders projection onto the sampled label's interior subspace and renormalizes to unit norm; shell amplitude is projected out because shell sites belong to no label eigenspace. `collapseToLabel` is two-pass: an empty class fails before psi is touched. A repeated label draw on the collapsed state returns the same class (absorbing outcome, tested).

**Boundaries.** This defines software measurement semantics only. It does not map lattice amplitudes to the eight-component i-vector, does not bind any physical apparatus observable, and does not make seeded selectors physical randomness. The physical measurement gate in `CYBER-PHYSICS.md` (state variable, apparatus, calibration, controls, thresholds, artifact schema, authorization) remains closed.

### i-vector ↔ amplitude binding contract v1 — 2026-11-19

`src/ivector_readout.zig` declares the software binding between the framework's 8-component signed-integer i-vector and the lattice state's 4,096 complex amplitudes, closing the "currently metadata" gap at the contract level (physical correspondence remains open).

**Shot readout.** `runIVectorShots` classifies each pure `sampleSite` draw via `describeSite`: interior hits increment the matching e-label component of `redox_information_vector.Vector` (8×i512), shell hits increment `shell_events`. Contract v1 keeps the i-vector at exactly eight components — shell/foam events are auxiliary metadata, never folded into e0..e7. Sampling is non-mutating and deterministic under `SelectorStream` seeds; `readoutDigest` seals the record. Projective repeated measurement on one state is not simulated (a collapsed state re-samples its own outcome — absorbing, per contract v1 of `lattice_measure.zig`).

**Population quantization.** `populationsToIVector` converts the eight Q128 label weights to i512 by `round_half_up(weight × denom)` for caller-chosen `denom > 0` — a declared rounding convention, exact for populations on the `1/denom` grid, selector-free.

**Boundaries.** Both bindings are declared software semantics: they define what the computational state *says* about the i-vector, not that a physical i-vector is read out. The eight components remain metadata distinct from the amplitudes; no physical correspondence is claimed.

### Lattice-native reversible transition contract v1 — 2026-11-19

`src/reversible_lattice.zig` implements a declared candidate rule for the open "globally injective lattice transition" item, motivated by the documented `dynamics.rounded_stencil_collision` (the rounded side-2 stencil is non-injective on free integer states).

**Construction.** State is `[4096]u8` on the 16³ domain with declared periodic boundary — a classical byte lane, distinct from the Q128 amplitude state. The domain partitions into 512 cells of 2×2×2 = 8 sites, matching the octonion component count; cell-local site index maps to offsets `(s&1, (s>>1)&1, (s>>2)&1)` as the declared e0..e7 ordering. Two staggered partitions (`even` origins, `odd` origins mod 16) both tile the torus; alternating them is the Margolus construction, so information crosses cell boundaries while each step stays a product of disjoint cell maps.

**Bijectivity.** `CellGate` is a bounded primitive sequence. `emit` enforces the disjointness constraints that make every primitive a bijection on (Z/256)⁸: `swap`/`add`/`sub` need distinct sites; `cswap` requires ctrl outside {a,b}; `cadd`/`csub` require ctrl != dst (ctrl == src is legal — src is read-only). Violations (e.g. cadd with ctrl == dst, which collides: +src can carry a nonzero dst to 0 while a zero dst stays 0) are rejected as `InvalidPrim`. Under the constraints, `add`↔`sub`, `cadd`↔`csub`, `rot`↔`unrot`, and swaps are inverse pairs, so `gate.inverse()` exists, every cell map is bijective, every step is bijective, and `runInverse` restores any `run` exactly.

**Tests.** Partition census (every site exactly once per partition, both partitions), exhaustive 256² primitive inverse-pair round-trips plus 2×256² conditional-primitive round-trips, gate/inverse round-trips on structured and seeded cell states, full-domain 16-step alternating run/runInverse restoration, single-excitation transport across cell boundaries, controlled-transfer duplication inside a cell, empty-gate identity, and `cellOf`/`cellSite` round-trip membership.

**Boundaries.** This is ONE declared candidate rule — the gate sequence `gateV1` and the u8/periodic-boundary choices are conventions, not a derived unique physical dynamics. It does not evolve the Q128 lattice state, does not resolve the transit-phase or stencil-collision questions for the quantum lane, and makes no physical claim.

### Transit-phase contract v1 and Q.ANT apparatus appraisal — 2026-11-20

**Transit-phase selection.** The open "increments 1 vs 3" question resolved
at contract level: the Module-2 engineering directive recorded in `1.md`
specifies "geometric phase accumulation of 3π/4 per transit with closure
at 8 transits." 3π/4 is exactly three eighth-turns, so
`three_quarter_turn_per_transit` is the spec-conformant convention and is
pinned as `lattice.CANONICAL_PHASE_CONVENTION`; `quarter_turn_per_transit`
(+1, the minimal Z/8 generator) remains selectable. Executable gauge
analysis added to `lattice.zig`: the +3 sequence is the element-wise ×3
mod 8 image of the +1 sequence; ×3 is *not* an octonion automorphism
(verified via `octonion.multiply` — σ(e1·e2)=e1 but σe1·σe2=e5), so
label-coupled consumers can distinguish the conventions; both share
8-step closure, the antipode at transit 4, and parity alternation. The
selection is contract metadata following the recorded source spec, not a
physical claim; serialization still requires explicit selection.
Registry node `lattice.transit_phase_v1` added.

**Q.ANT native toolkit appraisal.** `externals/qant_native_computing_toolkit`
(gitignored read-only donor; Q.ANT GmbH's Apache-2.0 Gen2/Gen2p NPU
inference SDK, Rust + C/Python bridges) was appraised through our contract
categories — full analysis in `CYBER-PHYSICS.md`. Alignments recorded:
cpu-backend simulated drivers mirror our executable-shadow pattern;
upload→fprop→activate mirrors prepare→evolve→measure; maxpool/avgpool
cover our site-sampling and population readout semantics; complex DFT on
re/im pairs is a candidate amplitude-spectral readout; conv_transpose is
an adjoint-direction analog; telemetry rails/current/stall-counters are
disturbance-protocol observables; capability flags mirror observable
declaration; clippy-denied unwrap/panic mirrors fail-closed law; bf16 is
the hardware precision floor. Boundaries: no octonion/Fano/i-vector/15³
semantics, inference-only irreversibility (no path to
`reversible_lattice.zig`), bf16-vs-Q128 precision wall, 2D conv vs 3D
lattice, Rust/C++ cannot enter `src/`. Status: candidate apparatus
*interface* for the gated physical lane; cpu-backend permits shadow-adapter
development without hardware. No physical claim.
