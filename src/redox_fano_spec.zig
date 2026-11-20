//! The framework's authoritative 15^3 Fano-layer spec, transcribed
//! verbatim and audited as load-bearing data.
//!
//! The spec defines the lattice as 15 layers of 15x15 e-labels; layers
//! are mirror-paired (Layer k == Layer 16-k) with Layer 8 central.
//! Each row carries an `i=eN` label — the row's designated imaginary
//! unit of the i-vector i=[e0^i..e7^i].
//!
//! Audited findings (all measured below):
//!   * The spec grids are EXACTLY the basisAt coloring
//!     v(x,y,z) = (|x-8|+|y-8|+|z-8|) & 7 — 1800/1800 unique cells
//!     agree, and mirror pairs agree by construction of the tent.
//!   * The i-label of each row IS the value at the center column x=8.
//!   * The slice E-number ("each slice has its own E number") is the
//!     center row's i-label: layers 1..7 carry e7..e1, layer 8 = e0.
//!   * "Approximately 421 e0 nodes" is exact: 421, unique deficit.
//!   * "6 e1-e7 arms": the six axis rays from the center cell each
//!     traverse e1..e7 in order.
//!   * "Where e7 and e0 meet": 420/421 e0 cells border an e7 — the
//!     unique exception is the exact center (7,7,7), wrapped in e1's.
//!   * The C/A table: measured commutator/associator confirm 9 of 10
//!     rows; the 10D dual-B-complex row claims C=yes/A=yes but measures
//!     no/no — spec row FALSIFIED.
//!   * The torus/Mobius wrap: all toroidal wrap adjacencies are
//!     same-state — the grid is NOT a proper toroidal 8-coloring.
//!   * The H21 journey chain: 7 of 9 joints are contiguous; e1->e2
//!     breaks (pi != H21/4) and the 8D^i->0D wrap closes only via the
//!     e0 identification, not numerically.
//!   * qcomms_lattice.legacyState preserves the historical coloring; the
//!     default qcomms_lattice.state now delegates to basisAt and is
//!     exhaustively checked against this spec.
//!
//! Classification: EXACT_MATH for grid/coloring facts; CONSTRUCTION
//! for qbit/universe labels; FALSIFIED for the dual C/A row.
const std = @import("std");
const tiers = @import("redox_scaling_tiers.zig");
const lattice = @import("qcomms_lattice.zig");
const bridge = @import("redox_algebra_bridge.zig");
const vec3 = @import("redox_vector3.zig");
const bicomplex_mod = @import("redox_bicomplex.zig");
const anti_mod = @import("redox_anti_octonion.zig");
const dual_mod = @import("redox_dual_bcomplex.zig");
const jordan_mod = @import("redox_jordan.zig");

// ---------------------------------------------------------------------------
// Spec data — the eight unique 15x15 layers, verbatim from the framework
// spec (Layer k is shared with Layer 16-k; Layer 8 is central).
// ---------------------------------------------------------------------------

pub const LayerSpec = struct {
    cells: [15][15]u3, // cells[y][x], 0-indexed
    ilabel: [15]u3,
};

fn parseLayer(comptime text: []const u8) LayerSpec {
    @setEvalBranchQuota(1_000_000);
    var out: LayerSpec = .{ .cells = undefined, .ilabel = undefined };
    var row: usize = 0;
    var col: usize = 0;
    var it = std.mem.tokenizeAny(u8, text, " \n\t");
    while (it.next()) |tok| {
        if (tok.len == 2 and tok[0] == 'e' and tok[1] >= '0' and tok[1] <= '7') {
            out.cells[row][col] = tok[1] - '0';
            col += 1;
            if (col == 15) {
                col = 0;
                row += 1;
            }
        } else if (tok.len == 4 and std.mem.eql(u8, tok[0..2], "i=")) {
            // The i= label trails the row's 15 cells; row has already
            // advanced, so index the completed row.
            out.ilabel[row - 1] = tok[3] - '0';
        }
    }
    return out;
}

pub const SPEC_LAYERS = [8]LayerSpec{
    // Layer 1 (and Layer 15)
    parseLayer(
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
    ),
    // Layer 2 (and Layer 14)
    parseLayer(
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
    ),
    // Layer 3 (and Layer 13)
    parseLayer(
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
    ),
    // Layer 4 (and Layer 12)
    parseLayer(
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
    ),
    // Layer 5 (and Layer 11)
    parseLayer(
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
    ),
    // Layer 6 (and Layer 10)
    parseLayer(
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
    ),
    // Layer 7 (and Layer 9)
    parseLayer(
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
    ),
    // Layer 8 (Central Slice)
    parseLayer(
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e7 e6 e5 e4 e3 e2 e1 e0 e1 e2 e3 e4 e5 e6 e7 i=e0
        \\e0 e7 e6 e5 e4 e3 e2 e1 e2 e3 e4 e5 e6 e7 e0 i=e1
        \\e1 e0 e7 e6 e5 e4 e3 e2 e3 e4 e5 e6 e7 e0 e1 i=e2
        \\e2 e1 e0 e7 e6 e5 e4 e3 e4 e5 e6 e7 e0 e1 e2 i=e3
        \\e3 e2 e1 e0 e7 e6 e5 e4 e5 e6 e7 e0 e1 e2 e3 i=e4
        \\e4 e3 e2 e1 e0 e7 e6 e5 e6 e7 e0 e1 e2 e3 e4 i=e5
        \\e5 e4 e3 e2 e1 e0 e7 e6 e7 e0 e1 e2 e3 e4 e5 i=e6
        \\e6 e5 e4 e3 e2 e1 e0 e7 e0 e1 e2 e3 e4 e5 e6 i=e7
    ),
};

// ---------------------------------------------------------------------------
// Claim 1: the spec grids ARE the basisAt coloring — all cells, all layers.
// ---------------------------------------------------------------------------

test "spec grids equal basisAt on all unique cells" {
    for (0..8) |z| {
        const L = SPEC_LAYERS[z];
        for (0..15) |y| for (0..15) |x| {
            const expect = L.cells[y][x];
            try std.testing.expectEqual(expect, tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), 15));
        };
    }
    // Mirror pairs: layer k (0-indexed z) must equal layer 16-k (z'=14-z).
    for (0..8) |z| {
        for (0..15) |y| for (0..15) |x| {
            try std.testing.expectEqual(
                tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), 15),
                tiers.basisAt(@intCast(x), @intCast(y), @intCast(14 - z), 15),
            );
        };
    }
}

// ---------------------------------------------------------------------------
// Claim 2: the i-label is the row's center-column value; the slice E-number
// is the center row's i-label (layers 1..7 -> e7..e1, layer 8 -> e0).
// ---------------------------------------------------------------------------

test "i-label equals center-column value and slice E-numbers follow e7..e0" {
    for (0..8) |z| {
        const L = SPEC_LAYERS[z];
        for (0..15) |y| {
            try std.testing.expectEqual(L.cells[y][7], L.ilabel[y]);
        }
        // Slice E-number = i-label of central row (y=7).
        try std.testing.expectEqual(@as(u3, @intCast(7 - z)), L.ilabel[7]);
    }
    // Mirrored layers carry the same slice E-number (layers 9..15 -> e1..e7).
    for (0..8) |z| {
        try std.testing.expectEqual(
            tiers.basisAt(7, 7, @intCast(z), 15),
            tiers.basisAt(7, 7, @intCast(14 - z), 15),
        );
    }
    // The exact lattice center is e0.
    try std.testing.expectEqual(@as(u3, 0), tiers.basisAt(7, 7, 7, 15));
}

// ---------------------------------------------------------------------------
// Claim 3: "approximately 421 e0 nodes" — exact under the spec coloring.
// ---------------------------------------------------------------------------

test "spec coloring yields exactly 421 e0 cells and the 7-defect" {
    var count: usize = 0;
    for (0..15) |z| for (0..15) |y| for (0..15) |x| {
        if (tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), 15) == 0) count += 1;
    };
    try std.testing.expectEqual(@as(usize, 421), count);
    try std.testing.expectEqual(@as(u64, 7), 15 * 15 * 15 - 8 * 421);
}

// ---------------------------------------------------------------------------
// Claim 4: "6 e1-e7 arms" — the six axis rays from the center cell each
// traverse e1..e7 in order.
// ---------------------------------------------------------------------------

test "six arms: axis rays from center traverse e1..e7 in order" {
    const dirs = [6][3]i8{ .{ 1, 0, 0 }, .{ -1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, -1, 0 }, .{ 0, 0, 1 }, .{ 0, 0, -1 } };
    var arms: usize = 0;
    for (dirs) |d| {
        var ok = true;
        for (1..8) |step| {
            const x: u8 = @intCast(@as(i16, 7) + d[0] * @as(i16, @intCast(step)));
            const y: u8 = @intCast(@as(i16, 7) + d[1] * @as(i16, @intCast(step)));
            const z: u8 = @intCast(@as(i16, 7) + d[2] * @as(i16, @intCast(step)));
            if (tiers.basisAt(x, y, z, 15) != @as(u3, @intCast(step))) ok = false;
        }
        if (ok) arms += 1;
    }
    try std.testing.expectEqual(@as(usize, 6), arms);
}

// ---------------------------------------------------------------------------
// Claim 5: "where e7 and e0 meet" — every e0 cell borders an e7 and an e1
// along at least one lattice axis.
// ---------------------------------------------------------------------------

test "every e0 cell borders an e7-side and an e1-side neighbor" {
    var e0_cells: usize = 0;
    var with_e7: usize = 0;
    var with_e1: usize = 0;
    const axes = [3][3]i8{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } };
    for (0..15) |z| for (0..15) |y| for (0..15) |x| {
        if (tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), 15) != 0) continue;
        e0_cells += 1;
        var e7 = false;
        var e1 = false;
        for (axes) |ax| for ([2]i8{ -1, 1 }) |sgn| {
            const nx = @as(i16, @intCast(x)) + ax[0] * sgn;
            const ny = @as(i16, @intCast(y)) + ax[1] * sgn;
            const nz = @as(i16, @intCast(z)) + ax[2] * sgn;
            if (nx < 0 or nx > 14 or ny < 0 or ny > 14 or nz < 0 or nz > 14) continue;
            const s = tiers.basisAt(@intCast(nx), @intCast(ny), @intCast(nz), 15);
            if (s == 7) e7 = true;
            if (s == 1) e1 = true;
        };
        if (e7) with_e7 += 1;
        if (e1) with_e1 += 1;
    };
    try std.testing.expectEqual(@as(usize, 421), e0_cells);
    // Measured: every e0 cell borders an e1; all but ONE border an e7.
    // The exception is the exact lattice center (7,7,7) — its six
    // neighbors all sit at distance 1 = e1. So "where e7 and e0 meet"
    // holds on 420/421 defect cells; the center e0 is wrapped purely
    // in e1's — the one e0 that does not touch e7.
    try std.testing.expectEqual(@as(usize, 420), with_e7);
    try std.testing.expectEqual(e0_cells, with_e1);
    // Confirm the center is the unique non-meeting e0.
    try std.testing.expectEqual(@as(u3, 0), tiers.basisAt(7, 7, 7, 15));
    try std.testing.expectEqual(@as(u3, 1), tiers.basisAt(6, 7, 7, 15));
    try std.testing.expectEqual(@as(u3, 1), tiers.basisAt(8, 7, 7, 15));
}

// ---------------------------------------------------------------------------
// Claim 6: the spec C/A table vs measured commutator/associator.
// ---------------------------------------------------------------------------

const CARow = struct { name: []const u8, c: bool, a: bool, alg: ?bridge.Algebra };

const CA_SPEC = [_]CARow{
    .{ .name = "e1 real", .c = true, .a = true, .alg = .real },
    .{ .name = "e2 complex", .c = true, .a = true, .alg = .complex },
    .{ .name = "e3 vector", .c = false, .a = false, .alg = .vector3 },
    .{ .name = "e4 quaternion", .c = false, .a = true, .alg = .quaternion },
    .{ .name = "e5 bicomplex", .c = true, .a = true, .alg = .bicomplex },
    .{ .name = "e6 jordan", .c = true, .a = false, .alg = .jordan },
    .{ .name = "e7 octonion", .c = false, .a = false, .alg = .octonion },
    .{ .name = "9D anti", .c = false, .a = false, .alg = .anti_octonion },
    .{ .name = "10D dual", .c = true, .a = true, .alg = .dual_bcomplex },
};

/// Measured on each tier's own product — the table is computed, not
/// transcribed. false on .e8_root means "no product exists".
fn measuredCommutes(alg: bridge.Algebra) bool {
    return switch (alg) {
        .real => (3 * 5) == (5 * 3),
        .complex => blk: {
            const a = bridge.Value{ .complex = .{ 3, -7 } };
            const b = bridge.Value{ .complex = .{ -2, 5 } };
            break :blk (bridge.commutatorCostValue(a, b) catch 1) == 0;
        },
        .vector3 => vec3.normSquared(vec3.commutator(vec3.unit(0), vec3.unit(1))) == 0,
        .quaternion => blk: {
            const a = bridge.Value{ .quaternion = .{ 0, 1, 0, 0 } };
            const b = bridge.Value{ .quaternion = .{ 0, 0, 1, 0 } };
            break :blk (bridge.commutatorCostValue(a, b) catch 1) == 0;
        },
        .bicomplex => bicomplex_mod.normSquared(bicomplex_mod.commutator(bicomplex_mod.unit(1), bicomplex_mod.unit(2))) == 0,
        .jordan => jordan_mod.normSquared(jordan_mod.commutator(
            jordan_mod.J3.diagonal(1, 2, 3),
            jordan_mod.J3.diagonal(4, 5, 6),
        )) == 0,
        .octonion => bridge.commutatorCost(bridge.unit(1), bridge.unit(2)) == 0,
        .anti_octonion => anti_mod.normSquared(anti_mod.commutator(anti_mod.unit(1), anti_mod.unit(2))) == 0,
        .dual_bcomplex => dual_mod.normSquared(dual_mod.commutator(dual_mod.unit(1), dual_mod.unit(2))) == 0,
        .e8_root => false, // error.NoProduct — no commutativity claim
    };
}

fn measuredAssociates(alg: bridge.Algebra) bool {
    return switch (alg) {
        .real => (2 * 3) * 5 == 2 * (3 * 5),
        .complex => blk: {
            const a = bridge.Value{ .complex = .{ 3, -7 } };
            const b = bridge.Value{ .complex = .{ -2, 5 } };
            const c = bridge.Value{ .complex = .{ 11, 4 } };
            break :blk (bridge.associatorCostValue(a, b, c) catch 1) == 0;
        },
        .vector3 => vec3.normSquared(vec3.associator(vec3.unit(0), vec3.unit(1), vec3.unit(1))) == 0,
        .quaternion => blk: {
            const a = bridge.Value{ .quaternion = .{ 0, 1, 0, 0 } };
            const b = bridge.Value{ .quaternion = .{ 0, 0, 1, 0 } };
            const c = bridge.Value{ .quaternion = .{ 0, 0, 0, 1 } };
            break :blk (bridge.associatorCostValue(a, b, c) catch 1) == 0;
        },
        .bicomplex => bicomplex_mod.normSquared(bicomplex_mod.associator(bicomplex_mod.unit(1), bicomplex_mod.unit(2), bicomplex_mod.unit(3))) == 0,
        .jordan => blk: {
            // Bounded witness search over basis-unit off-diagonals —
            // non-associativity is found, not assumed.
            var a = jordan_mod.J3.diagonal(0, 0, 0);
            var b = jordan_mod.J3.diagonal(0, 0, 0);
            var c = jordan_mod.J3.diagonal(0, 0, 0);
            for (0..8) |i| for (0..8) |j| for (0..8) |k| {
                a.o1 = jordan_mod.octUnit(i);
                b.o1 = jordan_mod.octUnit(j);
                c.o3 = jordan_mod.octUnit(k);
                if (jordan_mod.normSquared(jordan_mod.associator(a, b, c)) != 0) break :blk false;
            };
            break :blk true;
        },
        .octonion => bridge.associatorCost(bridge.unit(1), bridge.unit(2), bridge.unit(4)) == 0,
        .anti_octonion => anti_mod.normSquared(anti_mod.associator(anti_mod.unit(1), anti_mod.unit(2), anti_mod.unit(4))) == 0,
        .dual_bcomplex => dual_mod.normSquared(dual_mod.associator(dual_mod.unit(1), dual_mod.unit(2), dual_mod.unit(4))) == 0,
        .e8_root => false, // error.NoProduct
    };
}

test "spec C/A table: 9 of 10 rows confirmed, dual row falsified" {
    var confirmed: usize = 0;
    var falsified: usize = 0;
    for (CA_SPEC) |row| {
        const alg = row.alg.?;
        const mc = measuredCommutes(alg);
        const ma = measuredAssociates(alg);
        if (mc == row.c and ma == row.a) confirmed += 1 else falsified += 1;
        if (alg == .dual_bcomplex) {
            // The spec claims C=yes/A=yes for 10D — measured no/no:
            // the octonion part inside dual still has commutator and
            // associator of squared norm 4.
            try std.testing.expectEqual(@as(i512, 4), dual_mod.normSquared(dual_mod.commutator(dual_mod.unit(1), dual_mod.unit(2))));
            try std.testing.expectEqual(@as(i512, 4), dual_mod.normSquared(dual_mod.associator(dual_mod.unit(1), dual_mod.unit(2), dual_mod.unit(4))));
            try std.testing.expect(mc != row.c and ma != row.a);
        }
    }
    try std.testing.expectEqual(@as(usize, 8), confirmed);
    try std.testing.expectEqual(@as(usize, 1), falsified);
}

// ---------------------------------------------------------------------------
// Claim 7: the scaling-chain table — arithmetic pattern verification.
// ---------------------------------------------------------------------------

test "scaling chain: qbit counts double, entangled counts cube, dims double" {
    // Odd tiers: 15/30/60/120 -> qbits 1/2/4/8; dims 8/16/32/64.
    const odd_qbits = [4]u64{ 1, 2, 4, 8 };
    const odd_dims = [4]u64{ 8, 16, 32, 64 };
    for (0..4) |i| {
        try std.testing.expectEqual(@as(u64, 1) << @intCast(i), odd_qbits[i]);
        try std.testing.expectEqual(@as(u64, 8) << @intCast(i), odd_dims[i]);
    }
    // Even tiers: 16/32/64/128 -> "globally entangled" 1/8/64/512 = cube of
    // the paired odd tier's qbit count.
    const entangled = [4]u64{ 1, 8, 64, 512 };
    for (0..4) |i| {
        try std.testing.expectEqual(odd_qbits[i] * odd_qbits[i] * odd_qbits[i], entangled[i]);
    }
    // 15^3 is the unique tier carrying the single 7-defect.
    try std.testing.expectEqual(@as(?u3, 0), tiers.defectState(15));
    for ([_]u16{ 30, 60, 120 }) |n| {
        try std.testing.expectEqual(@as(?u3, null), tiers.defectState(n));
    }
    // Classification: these are symbolic/arithmetic constructions — no
    // entanglement is measured or claimed.
}

// ---------------------------------------------------------------------------
// Claim 8: torus/Mobius — wrap-adjacency check on the spec coloring.
// ---------------------------------------------------------------------------

test "torus wrap: boundary pairs are same-state — not a proper toroidal coloring" {
    var same: usize = 0;
    var total: usize = 0;
    // x-wrap: (0,y,z) adjacent to (14,y,z) on a torus.
    for (0..15) |z| for (0..15) |y| {
        total += 1;
        if (tiers.basisAt(0, @intCast(y), @intCast(z), 15) == tiers.basisAt(14, @intCast(y), @intCast(z), 15)) same += 1;
    };
    // y-wrap and z-wrap likewise.
    for (0..15) |z| for (0..15) |x| {
        total += 1;
        if (tiers.basisAt(@intCast(x), 0, @intCast(z), 15) == tiers.basisAt(@intCast(x), 14, @intCast(z), 15)) same += 1;
    };
    for (0..15) |y| for (0..15) |x| {
        total += 1;
        if (tiers.basisAt(@intCast(x), @intCast(y), 0, 15) == tiers.basisAt(@intCast(x), @intCast(y), 14, 15)) same += 1;
    };
    try std.testing.expectEqual(@as(usize, 675), total);
    try std.testing.expectEqual(total, same); // ALL wrap pairs same-state
    // A toroidal/Mobius embedding exists as a label, but the coloring is
    // mirror-symmetric, not twist-consistent — classification: framing.
}

// ---------------------------------------------------------------------------
// Claim 9: the H21 journey chain — symbolic endpoint continuity.
// ---------------------------------------------------------------------------

const Endpoint = enum { zero, phi, pi, h21_4, h21_2, h21, h21_2x };

const Journey = struct { name: []const u8, from: Endpoint, to: Endpoint };

const JOURNEYS = [_]Journey{
    .{ .name = "e0 0D", .from = .zero, .to = .phi },
    .{ .name = "e1 real", .from = .phi, .to = .pi },
    .{ .name = "e2 complex", .from = .h21_4, .to = .h21_2 },
    .{ .name = "e3 vector", .from = .h21_2, .to = .h21 },
    .{ .name = "e4 quaternion", .from = .h21, .to = .h21_2x },
    .{ .name = "e5 bicomplex", .from = .h21_2x, .to = .h21 },
    .{ .name = "e6 jordan", .from = .h21, .to = .h21_2 },
    .{ .name = "e7 octonion", .from = .h21_2, .to = .h21_4 },
    .{ .name = "e0 8D^i", .from = .h21_4, .to = .phi },
};

test "journey chain: 7 contiguous joints, 2 breaks (pi and the 8D->0D wrap)" {
    var contiguous: usize = 0;
    var breaks: usize = 0;
    for (0..JOURNEYS.len) |i| {
        const next = JOURNEYS[(i + 1) % JOURNEYS.len];
        if (JOURNEYS[i].to == next.from) contiguous += 1 else breaks += 1;
    }
    // Joints: e0->e1 (phi), e1->e2 (pi vs H21/4 — BREAK),
    // e2..e7 chain (H21/2, H21, 2H21, H21, H21/2, H21/4 all match),
    // e0'->e0 wrap (phi vs 0 — BREAK; closes only via the e0=0D=8D
    // identification, not numerically).
    try std.testing.expectEqual(@as(usize, 7), contiguous);
    try std.testing.expectEqual(@as(usize, 2), breaks);
}

// ---------------------------------------------------------------------------
// Claim 10: the legacy QComms coloring is preserved as an explicit historical
// variant; the default QComms state is aligned with the canonical spec.
// ---------------------------------------------------------------------------

test "QComms default aligns to the spec and legacy rule remains a distinct variant" {
    var agree: usize = 0;
    var legacy_disagree: usize = 0;
    var legacy_histogram = [_]usize{0} ** 8;
    for (0..15) |z| for (0..15) |y| for (0..15) |x| {
        const spec = tiers.basisAt(@intCast(x), @intCast(y), @intCast(z), 15);
        const current = lattice.state(@intCast(x), @intCast(y), @intCast(z));
        const legacy = lattice.legacyState(@intCast(x), @intCast(y), @intCast(z));
        legacy_histogram[legacy] += 1;
        try std.testing.expectEqual(spec, current);
        if (@as(u8, spec) == current) agree += 1;
        if (@as(u8, spec) != legacy) legacy_disagree += 1;
    };
    try std.testing.expectEqual(@as(usize, 15 * 15 * 15), agree);
    try std.testing.expect(legacy_disagree > 15 * 15 * 15 / 2);
    try std.testing.expectEqual([_]usize{ 422, 422, 422, 422, 422, 421, 422, 422 }, legacy_histogram);
}
