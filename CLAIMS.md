# Claims Ledger

Human-readable summary of the canonical claim registry
(`src/axiom_registry.zig` — 37 nodes, 39 typed edges, `validate()`-checked).
Statuses follow the epistemic law in `AGENTS.md`. This file is a view, not
the source of truth: when they disagree, the registry wins.

## Status counts

| status | count | meaning |
|---|---:|---|
| `verified` | 20 | executable check in this tree passed |
| `verified_with_correction` | 5 | holds modulo a named correction |
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
  origin `(0,0,0)` = index `(7,7,7)` = e0.

## Algebra ladder (11 tiers, all `verified`)

E0 bookend → real/timeline → complex → vector3 → quaternion →
bicomplex → Jordan J3(O) → octonion → E8-root bookend → anti-octonion
(`e8²=+e0`) → dual bicomplex (`e9²=0`). Index names are not literal real
dimensions (bicomplex=4, J3(O)=27, octonions=8).

## Counts

- `counts.shell_721` — `16³−15³=721`, `721=3·240+1` (verified).
- `counts.e8_240` — `15×16=240`, `15²=225` (verified).
- `counts.observer_421` — `421=(3375−7)/8`, `3375−421·8=7` (verified).
- `counts.h21_triad` — `.model_metadata`: `φ⁵+π²+φ⁻⁴≈21.106`, `7/66`
  interpretation is model mapping, not calibrated length.

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
- `dynamics.rounded_stencil_collision` — `.verified`: side-2 rounded
  stencil non-injective (explicit collision pair).
- `dynamics.rounded_polynomial_basis_control` —
  `.verified_with_correction`: origin/all-basis norm controls; not a
  global inverse proof.
- `reversible.register_gates` — `.verified`: permutation gates,
  exhaustive 8-bit bijection, Peres inverse, Bennett uncompute.
- Transit phase: increments 1 and 3 both close mod 8 after eight
  transits; neither selected; distinct from interference phase.

## What is NOT claimed

- No physical qbit measurement, no physical randomness, no entanglement
  beyond simulator amplitudes, no 256³/512³ dense evolution, no
  i-vector↔amplitude projection, no lattice-native global inverse, no
  selected transit-phase convention, no φ/π position→equation derivation.
