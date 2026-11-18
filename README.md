# Octonion-OS Lattice Engine

Standalone Zig 0.13.0 project for an integer-first 15³ signed-coordinate lattice, a translated Fano label tensor, a quantized Quad-Smith table, and deterministic JSON export.

## Verification

```sh
zig build test
zig build test-core
zig build test-sidecar
```

The core uses integer data only. `sidecar/quad_smith.zig` performs f64 Shirley square-to-disk mapping and normalized impedance conversion, then quantizes the 225 central-slice entries at scale `1_000_000_000`.

The JSON writer and SHA-256 digest helper are available from `src/serialize.zig`. The core tests exercise serialization determinism; the returned JSON contains the digest of the ordered raw lattice-label and integer lookup data. The lattice, Fano labels, and Smith mapping are computational constructions; passing tests does not prove physical or quantum interpretations.
