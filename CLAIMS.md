# Claims Ledger

Human-readable summary of the canonical claim registry
(`src/axiom_registry.zig`, `validate()`-checked).
Statuses follow the epistemic law in `AGENTS.md`. This file is a view, not
the source of truth: when they disagree, the registry wins.

## Status counts

| status | count | meaning |
|---|---:|---|
| `verified` | 21 | executable check in this tree passed |
| `verified_with_correction` | 16 | holds modulo a named correction |
| `model_metadata` | 4 | declared labels/counts, not verified physics |
| `register` | 7 | doctrine/narrative; no physical verdict |
| `unsupported` | 1 | scoped failure of the exact tested claim |

## Fixed point and axioms

- `axiom.0pow0_eq_i` — `0^0 = i`, the True-Origin axiom (`.register`).
  Four role nodes stay distinct: empty product `=1` (verified), e0
  density `421/3375` (verified), RamseyIdentity vacuum
  `0^0=e0=8D^i` (model_metadata), checksum pivot `i=e7=0^0` (register).
- Five `system.*` nodes (EU seven axioms, EU AXIOM 0, MOUND A1–A8,
  Qstar, downbeat) are `.register` `claimed_expansion` edges from the
  seed — doctrinal reductions, not verified derivations.
- `claims.zero_free_parameters` — `.verified_with_correction`: the
  "zero free parameters" scope is structural only; physical constants
  and interpretations remain supplied/external.

## Lattice and coloring

- `lattice.ivector_coloring` — `.verified_with_correction`: canonical
  15³ tensor is the i-vector cell-labeling view; the eight integer
  i-vector components are NOT the 4,096 state amplitudes.
- `qcomms.labeling_v2` — `.verified_with_correction`: QComms default is
  E0-aligned (`LABELING_VERSION = 2`); `legacyState`/`legacyDigest`
  preserve version-1 reproduction (deficit was at e5).
- Canonical census `[421, 422, 422, 422, 422, 422, 422, 422]`; signed
  origin `(0,0,0)` = index `(7,7,7)` = e0. Three valid colorings share
  this census in superposition (basisAt, `Lattice.init`, `legacyState`);
  pairwise divergence 1980/3375/3375 cells — see
  `PHASE-QUANTUM-AUDIT.md` §Convention-superposition audit.
- `pipeline.e2e_continuity_v1` — `.verified_with_correction`: 17 named
  seams (S0–S17) from the axiom to registry closure walk with executable
  checks in `src/e2e_continuity_probe.zig`. Index conventions bridge by
  coordinate, never raw index. Measured branch binding: the qbit's label
  observable, frames, serialize, and routing read the `Lattice.init`
  branch; QComms `state()` reads `basisAt`. Compounding law verified:
  shell−inner = inner/15 per canonical pair. Routing Fano use is
  convention-blind (unordered line membership). Open lane recorded:
  whether serialized manifests need an explicit branch tag — a decision
  point, not normalized.

## Algebra ladder (11 tiers, all `verified`)

E0 bookend → real/timeline → complex → vector3 → quaternion →
bicomplex → Jordan J3(O) → octonion → E8-root bookend → anti-octonion
(`e8²=+e0`) → dual bicomplex (`e9²=0`). Index names are not literal real
dimensions (bicomplex=4, J3(O)=27, octonions=8). Superposition siblings
off the ladder: `ladder.sedenion_16d` (`verified`, Cayley-Dickson
double, `e8²=−e0`, anticommuting, zero divisors — second e8-extension
instance) and the dual Fano tables inside `ladder.octonion_7d`
({3,5,6} vs {3,6,5} orientations).

## Counts

- `counts.shell_721` — `16³−15³=721`, `721=3·240+1` (verified).
- `counts.e8_240` — `15×16=240`, `15²=225` (verified).
- `counts.observer_421` — `421=(3375−7)/8`, `3375−421·8=7` (verified).
- `counts.h21_triad` — `.model_metadata`: `φ⁵+π²+φ⁻⁴≈21.106`, `7/66`
  interpretation is model mapping, not calibrated length.
- `lattice.scale_constant_inventory_v1` — `.verified_with_correction`:
  integer-only scale inventory from scale 0 (15³) through scale 7
  (1024³). The index sequence skips scale 1: 16³ appears only as the
  compounding shell attached to scale 0, and scale 2 starts at 32³. The
  inventory compares 42 scale-local counts/fractions to the 145 donor rows
  without fitting triad signatures; 42 target-underflow comparison slots
  are skipped separately from representable values. It reports 0 exact
  matches, 17 raw comparisons within 1%, 1 within 0.1%, and 0 within 1 ppm.
  The tolerance counts ignore the mixed source units and are not physical
  matches. Scale-0 coloring is enumerated exactly; equal higher-scale
  populations are declared uniform modulo-8 metadata, not dense translated-
  Fano counts. This is arithmetic screening, not physical-constant derivation.
- `lattice.image_claims_audit_v1` — `.verified_with_correction`: the
  supplied diagram set has been reconciled against executable integer
  structures. Exact identities include `15^3=3375`, `16^3-15^3=721`,
  `15*16=240`, `3375-8*421=7`, and `42/21=2`; these do not establish
  consciousness, physical qbit counts, or physical dimensionality. Newly
  executable findings (`src/image_claims_probe.zig`): the Möbius z=0↔z=14
  180° identification is label-compatible at odd inner sides and
  label-invisible (the twist is indistinguishable from the mirror by the
  coloring; even inner sides support neither identification); the panels'
  qubit ladder is the canonical-pair chain `15·2^s`/`16·2^s` with `8^s`
  15³-blocks — a different indexing than the constant audit's power-of-two
  interiors (audit side k = image shell side k−1); each 15³ octant of 30³
  carries the canonical histogram multiset with a shifted defect; the
  Fibonacci cooling bars reproduce in Q128 as `w_z = φ^{-z}/Σφ^{-k}`
  (model metadata). Second batch: the ψ-field Möbius boundary condition
  is the verified-compatible transform (the field itself is donor data);
  the label field is D4-symmetric on every slice so m=7 is excluded in
  the `basisAt` branch — but the init/legacy branches are non-D4
  (≤1 of 7 transforms preserved), so the donor field is a live branch,
  not a falsified claim; the center slice carries exactly 29 e0
  cells (center + Manhattan diamond); radial rings are exact (`4r`/`8r`);
  Axiom-7 discretization verifies (`round(T)=F₀=21`, residuals 0.503%/
  0.0021%); ladder tier coordinates are integer rationals over F₀=21.
  The prediction chart's 1/α, sin²θ_W, and Koide rows are absent from
  the 145-table and its error figures disagree across panels —
  unverifiable. Third batch: e-labels are exactly Manhattan-octahedral
  shells `{k,k+8,k+16}` (not Chebyshev), populations folding into
  `[421,422×7]` with e0=421 via the observer singleton; the "hidden
  spheres" are the nearest integer-radius shells to φ (d²=3, 8 cells)
  and π (d²=10, 24 cells); the Fano+e8 annotations are implemented
  algebra (`e8·e1=e1`, `e8²=+e0`) — though the "all commutativity lost"
  caption is contradicted since e8 commutes universally; ladder bars
  verify completely (0, φ, π constants + F₀ rationals); the projection
  chain is the reduction direction. Fourth batch: the 15 z-slices carry
  exactly 8 distinct patterns (mirrored pairs, cyclic-shift law); the
  Cayley-Dickson chain is an exact palindrome peaking at 42 = 8× its
  ends at the 6D mirror; Lie-table corrections — e3→SO(4) contradicts
  measured so(3), e4→SO(5) is questionable, while e7→G2 and e6→E6/F4
  are real; E8 splits 112+128 (standard) and 16+112+112 (octavian) are
  both exact and held in superposition; "e7→e2 closure" verifies as `e5·e7=+e2`; the L15-touch/
  L16-outward face topology is verified (interface at coord=inner, 3+3
  faces); Smith/Ohm wheel mappings are domain-valid semantics; the
  "1128 bits" figure is unexplained. The central-slice visualization is
  not itself a Fano multiplication proof; no boundary transform on
  dynamics is implemented.
- `hydrogen.lattice_alignment_v1` — `.verified_with_correction`: the
  nonrelativistic 1s Coulomb spatial solution is sampled and discretely
  normalized on the E0-centered 15³ lattice using integer/Q128 arithmetic.
  The choice `a₀ = 1` lattice step is a model scale, not physical
  calibration. The 21 cm line is the separate hyperfine spin-flip
  frequency/wavelength; its electronic spatial wavefunction is unchanged.
  Ladder endpoints `H21,H21,H21` (e3) and `21cm,21cm,21cm` (e6) remain
  distinct triples. The endpoint candidate is `21 cm + 7/66 cm`; the full
  triad candidate `T + 7/66` is tracked separately and its residual remains
  explicit. The connected positional reading assigns π² to the E0/E2
  bubble, φ⁵ outer, and φ⁻⁴ inner; neither mapping derives the SI scale.
- `mound.triad_table_v1` — `.verified_with_correction`: the donor's
  145-constant triad table (`T=φ^a+π^b+φ^c`) recomputes in Q128.128
  integer fixed-point — 144 evaluable rows + 1 target-underflow
  (Planck time below the precision floor), 0 arithmetic failures,
  130/144 within 1%, worst residual 2.71%. Positioning-derived
  correction hypotheses (inward/outward φ split, compounding term,
  implied-base refit, exponent-residue structure) were tested and
  rejected: implied bases cluster at canonical φ/π within 0.01% and
  residuals are signature-fit noise. Arithmetic coverage only — not
  physical validation.

## Scaling

- `scaling.canonical_pairs` — 15/16…480/512 preserve `16/15` (verified).
- `scaling.precision_ladder` — `.model_metadata`: `i32q16…i512q256`
  paired with sides 16…512; 256/512 saturate at i512q256.
- `scaling.redox_tiers` — `.model_metadata`: prototype tier chain;
  declared qbit labels are metadata.
- Defect census: unique 7-defect at 15³; dispersed at 30³; uniform at
  480³ — does not survive that doubling (measured).

## E8

- `e8.octavian_overlay` — `.verified`: Fano-derived octavian units form
  the 240-root system (fingerprint 1/56/56/126, Weyl-closed); algebraic
  overlay via 𝕆, not a cell map.
- `e8.cell_embedding` — `.unsupported`: adjacency-preserving map from
  the 15³ e0-neighbor graph to the E8 minimum-distance graph; degree
  ≤6 vs 56 obstruction, scoped to the stated graphs only.

## Qbit and dynamics

- `qbit.lattice_3d` — `.verified_with_correction`: 4,096-amplitude
  state over 16³; 15³ interior is named basis; i-vector is distinct;
  physical readout mapping open.
- `measurement.lattice_contract` — `.verified_with_correction`:
  software readout contract v1 implemented and tested (site + label
  observables, deterministic selectors, collapse semantics); physical
  apparatus mapping remains open.
- `measurement.ivector_readout` — `.verified_with_correction`:
  declared software binding v1 (shot histogram → 8 e-components +
  shell channel; population quantization → i512); physical
  i-vector correspondence open.
- `dynamics.reversible_lattice` — `.verified_with_correction`: declared
  contract v1, octonion-cell Margolus CA on u8 sites over the 16³
  torus; every primitive bijective under disjointness constraints ⇒
  steps provably invertible. Candidate rule, not unique derived
  dynamics; classical u8 lane distinct from the Q128 state.
- `dynamics.rounded_stencil_collision` — `.verified`: side-2 rounded
  stencil non-injective (explicit collision pair).
- `dynamics.rounded_polynomial_basis_control` —
  `.verified_with_correction`: origin/all-basis norm controls; not a
  global inverse proof.
- `reversible.register_gates` — `.verified`: permutation gates,
  exhaustive 8-bit bijection, Peres inverse, Bennett uncompute.
- `lattice.phi_pi_position_v1` — `.verified_with_correction`: declared
  positional contract — π at E0, φ inward on six cardinal directions,
  16³ compounding shell (721 sites, any coord == 15) as outward-φ role
  existing only when scaling; bare 15³ has no shell interactions.
  Position only; no magnitudes, no equation bridge.
- Transit phase contract v1: the Module-2 source spec (3π/4 per
  transit) selects increment 3 (`three_quarter_turn_per_transit`) as
  `CANONICAL_PHASE_CONVENTION`; the declared family is the complete
  unit group U(8) = {1,3,5,7} (+7/+5 = reversal images of +1/+3; even
  increments are sub-cycles, excluded). +k is the ×k mod 8 image of +1
  and ×k is not an octonion automorphism; distinct from interference
  phase.
- `cyber.superposition_law_v1` — `.verified_with_correction`: the
  governing law for all superposed instances (see `CYBER-PHYSICS.md`
  §Cyber-physical superposition law). The cyber layer carries
  superposition natively; collapse is physical-side only via the
  measurement contract or independent evidence; defaults are not
  collapse; falsification is branch-scoped, never "impossible". The
  quantum premise is framework interpretation, not measured physics.

## What is NOT claimed

- No physical qbit measurement, no physical randomness, no entanglement
  beyond simulator amplitudes, no 256³/512³ dense evolution, no
  i-vector↔amplitude projection, no apparatus-level transit-phase
  derivation beyond the recorded source spec, no φ/π position→equation
  derivation, no MOUND triad signature correction (residuals are fit
  noise; see `mound.triad_table_v1`).
- The hydrogen ground-state 2D slice is computed from the sampled 3D 1s
  density; it is not itself the full state. The 21 cm hyperfine transition
  does not change that spatial state, and the H21 φ/π triad has not been
  derived from hydrogen's Schrödinger or hyperfine Hamiltonian.
