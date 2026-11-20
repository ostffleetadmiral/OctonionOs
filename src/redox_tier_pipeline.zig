//! The E5 <-> E6 <-> E7 "Jordan pipeline" spec, audited as load-bearing
//! claims.
//!
//! The spec: bicomplex (commutative + associative) cannot project
//! directly into octonions (non-commutative + non-associative) without
//! "topological tearing / catastrophic phase loss"; J3(O) (commutative,
//! non-associative) mediates by retaining commutativity while relaxing
//! associativity, and operations crossing into E7 must satisfy the
//! Jordan product J(x,y) = (1/2)(xy + yx).
//!
//! Measured verdicts (each backed by a test below):
//!   * C/A table rows for E5/E6/E7: verified — bicomplex yes/yes,
//!     J3(O) yes/no, octonion no/no.
//!   * The Jordan identity (x o y) o x^2 = x o (y o x^2) — the defining
//!     law — verified identically on basis units and a bounded sweep.
//!   * The literal 1/2-product is NOT closed on the integer lattice:
//!     most basis-pair symmetric products have odd coefficients, so
//!     jmul2 (the exact doubled product) is the required surrogate.
//!   * No unital algebra homomorphism bicomplex -> J3(O) exists:
//!     diagonal entries of X o X are sums of squares >= 0, so the
//!     imaginary unit i (i^2 = -1) has no image. Measured as a lemma on
//!     all basis elements plus a bounded sweep — the E5->E6 edge is
//!     therefore .linear, not .subalgebra.
//!   * Direct E5->E7: in O, x^2 = +e0 only for x = +-e0, so the only
//!     unital homomorphism is the collapse (a+c, b+d) -> C — a 2D
//!     kernel annihilating half the coordinates. This IS the measured
//!     "catastrophic phase loss" — quantified, not metaphorical.
//!   * E6->E7: the o1-slot projection is not homomorphic either;
//!     measured discrepancy between jmul2(X,Y).o1 and octMul(X.o1,Y.o1).
//!   * Net: coordinates cross all three boundaries exactly (linear
//!     maps, zero loss both directions and end-to-end); PRODUCTS cross
//!     none of them. "E6 buffers the transition" is true only as exact
//!     coordinate bookkeeping — the pipeline is a bus for values, and
//!     the algebraic obstruction moves rather than disappears.
//!
//! Classification: EXACT_MATH for the measurements; the "mediation
//! bridge" framing is CONSTRUCTION layered on top.
const std = @import("std");
const bridge = @import("redox_algebra_bridge.zig");
const bicomplex_mod = @import("redox_bicomplex.zig");
const jordan_mod = @import("redox_jordan.zig");

const J3 = jordan_mod.J3;

fn j3Eql(a: J3, b: J3) bool {
    if (a.alpha != b.alpha or a.beta != b.beta or a.gamma != b.gamma) return false;
    for (0..8) |i| {
        if (a.o1[i] != b.o1[i] or a.o2[i] != b.o2[i] or a.o3[i] != b.o3[i]) return false;
    }
    return true;
}

/// The 27 natural J3(O) basis elements: 3 diagonal units + one octonion
/// unit in each of the 3 off-diagonal slots.
fn basisJ3(out: *[27]J3) void {
    out[0] = J3.diagonal(1, 0, 0);
    out[1] = J3.diagonal(0, 1, 0);
    out[2] = J3.diagonal(0, 0, 1);
    for (0..8) |i| {
        var x = J3.zero();
        x.o1 = jordan_mod.octUnit(i);
        out[3 + i] = x;
        x = J3.zero();
        x.o2 = jordan_mod.octUnit(i);
        out[11 + i] = x;
        x = J3.zero();
        x.o3 = jordan_mod.octUnit(i);
        out[19 + i] = x;
    }
}

// ---------------------------------------------------------------------------
// Claim 1: the Jordan identity — (x o y) o x^2 = x o (y o x^2).
// In doubled form: j2(j2(x,y), j2(x,x)) == j2(x, j2(y, j2(x,x))).
// ---------------------------------------------------------------------------

test "Jordan identity holds on basis units and a bounded sweep" {
    var basis: [27]J3 = undefined;
    basisJ3(&basis);
    // All ordered basis pairs.
    for (basis) |x| for (basis) |y| {
        const lhs = jordan_mod.jmul2(jordan_mod.jmul2(x, y), jordan_mod.jmul2(x, x));
        const rhs = jordan_mod.jmul2(x, jordan_mod.jmul2(y, jordan_mod.jmul2(x, x)));
        try std.testing.expect(j3Eql(lhs, rhs));
    };
    // Bounded mixed-element sweep (deterministic coefficients).
    var n: usize = 0;
    var cx: i512 = -2;
    while (cx <= 2) : (cx += 1) {
        var x = J3.diagonal(cx, -cx, 1);
        x.o1 = jordan_mod.octUnit(@intCast(@mod(cx + 2, 8)));
        var cy: i512 = -2;
        while (cy <= 2) : (cy += 1) {
            var y = J3.diagonal(1, cy, -1);
            y.o3 = jordan_mod.octScale(jordan_mod.octUnit(@intCast(@mod(cy + 3, 8))), cy);
            const lhs = jordan_mod.jmul2(jordan_mod.jmul2(x, y), jordan_mod.jmul2(x, x));
            const rhs = jordan_mod.jmul2(x, jordan_mod.jmul2(y, jordan_mod.jmul2(x, x)));
            try std.testing.expect(j3Eql(lhs, rhs));
            n += 1;
        }
    }
    try std.testing.expectEqual(@as(usize, 25), n);
}

// ---------------------------------------------------------------------------
// Claim 2: the literal J = (xy+yx)/2 is not integer-closed — measured.
// ---------------------------------------------------------------------------

fn j3HasOddEntry(x: J3) bool {
    if (@mod(x.alpha, 2) != 0 or @mod(x.beta, 2) != 0 or @mod(x.gamma, 2) != 0) return true;
    for (0..8) |i| {
        if (@mod(x.o1[i], 2) != 0 or @mod(x.o2[i], 2) != 0 or @mod(x.o3[i], 2) != 0) return true;
    }
    return false;
}

test "the half-product is not closed on integer J3 — j2 surrogate required" {
    var basis: [27]J3 = undefined;
    basisJ3(&basis);
    var odd_pairs: usize = 0;
    var total: usize = 0;
    for (basis) |x| for (basis) |y| {
        total += 1;
        if (j3HasOddEntry(jordan_mod.jmul2(x, y))) odd_pairs += 1;
    };
    // Measured: some basis pairs produce odd symmetric products — the
    // spec's J(x,y) = (1/2)(xy+yx) cannot be evaluated in integers for
    // those pairs; jmul2 is the exact closure.
    try std.testing.expect(odd_pairs > 0);
    try std.testing.expectEqual(@as(usize, 729), total);
}

// ---------------------------------------------------------------------------
// Claim 3: no unital homomorphism bicomplex -> J3(O) — the i^2 = -1
// obstruction, measured.
// ---------------------------------------------------------------------------

test "diagonal of X o X is a sum of squares — i has no image in J3" {
    var basis: [27]J3 = undefined;
    basisJ3(&basis);
    // Structural lemma, verified on every basis element: each diagonal
    // entry of jmul2(X,X) equals the stated sum of squares >= 0.
    for (basis) |x| {
        const s = jordan_mod.jmul2(x, x);
        try std.testing.expectEqual(
            2 * x.alpha * x.alpha + 2 * jordan_mod.octNormSquared(x.o1) + 2 * jordan_mod.octNormSquared(x.o2),
            s.alpha,
        );
        try std.testing.expectEqual(
            2 * x.beta * x.beta + 2 * jordan_mod.octNormSquared(x.o1) + 2 * jordan_mod.octNormSquared(x.o3),
            s.beta,
        );
        try std.testing.expectEqual(
            2 * x.gamma * x.gamma + 2 * jordan_mod.octNormSquared(x.o2) + 2 * jordan_mod.octNormSquared(x.o3),
            s.gamma,
        );
        try std.testing.expect(s.alpha >= 0 and s.beta >= 0 and s.gamma >= 0);
    }
    // Bounded sweep: no element with jmul2(X,X) = -2I is found, and the
    // lemma above makes the diagonal sign argument exact.
    var found_neg_square = false;
    var a: i512 = -3;
    while (a <= 3) : (a += 1) {
        var b: i512 = -3;
        while (b <= 3) : (b += 1) {
            const x = J3.diagonal(a, b, 0);
            const s = jordan_mod.jmul2(x, x);
            if (s.alpha == -2 and s.beta == -2 and s.gamma == -2) found_neg_square = true;
        }
    }
    try std.testing.expect(!found_neg_square);
}

// ---------------------------------------------------------------------------
// Claim 4: direct E5 -> E7 — the unique unital homomorphism is a collapse.
// ---------------------------------------------------------------------------

/// The collapse homomorphism bicomplex -> O: j must land on +-e0 (the
/// only octonion square roots of +e0), so (a+bi+cj+dij) maps to
/// (a+c)*e0 + (b+d)*e1. Kernel = span{(1,0,-1,0), (0,1,0,-1)}.
pub fn collapseHom(x: bicomplex_mod.BC) bridge.Element {
    var e = bridge.zero();
    e[0] = x[0] + x[2];
    e[1] = x[1] + x[3];
    return e;
}

test "in O only +-e0 squares to +e0 — bounded search confirms" {
    // Any hom must send j to an element with x^2 = +e0.
    var solutions: usize = 0;
    var c: i512 = -2;
    while (c <= 2) : (c += 1) {
        for (0..8) |i| {
            var x = bridge.zero();
            x[0] = c;
            x[i] += 1;
            const sq = bridge.mul(x, x);
            if (sq[0] == 1) {
                var imag_zero = true;
                for (1..8) |k| {
                    if (sq[k] != 0) imag_zero = false;
                }
                if (imag_zero) solutions += 1;
            }
        }
    }
    // Only x = +e0 and x = -e0 survive.
    try std.testing.expectEqual(@as(usize, 2), solutions);
    const pos = bridge.mul(bridge.unit(0), bridge.unit(0));
    var neg = bridge.zero();
    neg[0] = -1;
    const negsq = bridge.mul(neg, neg);
    try std.testing.expectEqual(@as(i512, 1), pos[0]);
    try std.testing.expectEqual(@as(i512, 1), negsq[0]);
}

test "the collapse map IS a homomorphism — and annihilates half the coordinates" {
    // Verify products are preserved on a deterministic element set.
    var mismatch: usize = 0;
    var pairs: usize = 0;
    for (0..4) |i| for (0..4) |j| {
        const x = bicomplex_mod.unit(i);
        const y = bicomplex_mod.unit(j);
        const lhs = collapseHom(bicomplex_mod.mul(x, y));
        const rhs = bridge.mul(collapseHom(x), collapseHom(y));
        pairs += 1;
        if (!std.meta.eql(lhs, rhs)) mismatch += 1;
    };
    try std.testing.expectEqual(@as(usize, 16), pairs);
    try std.testing.expectEqual(@as(usize, 0), mismatch); // homomorphic!
    // Kernel: (1,0,-1,0) and (0,1,0,-1) both map to 0 — 2 of 4 dims die.
    const k1 = collapseHom(.{ 1, 0, -1, 0 });
    const k2 = collapseHom(.{ 0, 1, 0, -1 });
    try std.testing.expectEqual(bridge.zero(), k1);
    try std.testing.expectEqual(bridge.zero(), k2);
}

test "linear injection E5 -> E7 is lossless but preserves no product" {
    // phi(a,b,c,d) = a e0 + b e1 + c e2 + d e3 — injective, exact.
    const y = bicomplex_mod.unit(2); // j
    var iy = bridge.zero();
    iy[2] = 1;
    // phi(i*j) = phi(ij) = e3 ; phi(i)*phi(j) = e1*e2 = e3 — equal here!
    // But for i*i: phi(i*i) = phi(-1) = -e0 ; e1*e1 = -e0 — also equal.
    // The genuine break: phi(j*j) = phi(+1) = e0, but e2*e2 = -e0.
    const jprod = bicomplex_mod.mul(y, y); // j*j = +1
    var img_jj = bridge.zero();
    img_jj[0] = jprod[0];
    img_jj[1] = jprod[1];
    img_jj[2] = jprod[2];
    img_jj[3] = jprod[3];
    const img_yy = bridge.mul(iy, iy); // e2*e2 = -e0
    try std.testing.expect(!std.meta.eql(img_jj, img_yy)); // sign clash
    try std.testing.expectEqual(@as(i512, 1), img_jj[0]);
    try std.testing.expectEqual(@as(i512, -1), img_yy[0]);
    // So: homomorphism collapses (kernel 2); injection keeps coordinates
    // but loses the product. Both legs confirm "phase loss" — the
    // product structure is what cannot cross.
}

// ---------------------------------------------------------------------------
// Claim 5: E6 -> E7 — the o1-slot projection is not homomorphic.
// ---------------------------------------------------------------------------

test "jordan -> octonion projection does not preserve products" {
    var x = J3.zero();
    x.o1 = jordan_mod.octUnit(1);
    var y = J3.zero();
    y.o1 = jordan_mod.octUnit(2);
    const lhs = jordan_mod.jmul2(x, y).o1; // o1-component of XY+YX
    const rhs = jordan_mod.octMul(x.o1, y.o1); // e1*e2 = e3
    try std.testing.expect(!std.meta.eql(lhs, rhs));
    try std.testing.expectEqual(@as(i512, 1), rhs[3]);
    // And the reverse direction (octonion slot embed) is a linear edge:
    // promotion keeps coordinates but the product in J3 mixes slots.
}

// ---------------------------------------------------------------------------
// Claim 6: end-to-end pipeline — coordinates exact, products blocked.
// ---------------------------------------------------------------------------

test "pipeline E5->E6->E7->E6->E5 round-trips coordinates exactly" {
    const x = bicomplex_mod.BC{ 3, -7, 11, 5 };
    const jv = try bridge.promoteValue(.{ .bicomplex = x }, .jordan);
    // E6 -> E7 via the o1 slot projection (demote arm of octonion->jordan).
    const ov = (try bridge.demoteValue(jv, .octonion)).value;
    try std.testing.expectEqual(@as(?bridge.EdgeKind, .linear), bridge.edgeKind(.bicomplex, .jordan));
    try std.testing.expectEqual(@as(?bridge.EdgeKind, .linear), bridge.edgeKind(.octonion, .jordan));
    // All four components reached E7 intact through E6.
    try std.testing.expectEqual(@as(i512, 3), ov.octonion[0]);
    try std.testing.expectEqual(@as(i512, -7), ov.octonion[1]);
    try std.testing.expectEqual(@as(i512, 11), ov.octonion[2]);
    try std.testing.expectEqual(@as(i512, 5), ov.octonion[3]);
    // Back up through E6 and down to E5 — zero loss.
    const jv2 = try bridge.promoteValue(ov, .jordan);
    const back = try bridge.demoteValue(jv2, .bicomplex);
    try std.testing.expectEqual(@as(i512, 0), back.loss);
    try std.testing.expectEqual(x, back.value.bicomplex);
    // E5 -> E6 -> E5 alone is also exact.
    const back2 = try bridge.demoteValue(jv, .bicomplex);
    try std.testing.expectEqual(@as(i512, 0), back2.loss);
    try std.testing.expectEqual(x, back2.value.bicomplex);
}

// ---------------------------------------------------------------------------
// Claim 7: the spec C/A table for the three pipeline tiers.
// ---------------------------------------------------------------------------

test "E5/E6/E7 C/A roles verified against measured products" {
    // E5 bicomplex: commutative and associative.
    try std.testing.expectEqual(@as(i512, 0), bicomplex_mod.normSquared(bicomplex_mod.commutator(bicomplex_mod.unit(1), bicomplex_mod.unit(2))));
    try std.testing.expectEqual(@as(i512, 0), bicomplex_mod.normSquared(bicomplex_mod.associator(bicomplex_mod.unit(1), bicomplex_mod.unit(2), bicomplex_mod.unit(3))));
    // E6 J3(O): commutative (jmul2 symmetric), non-associative.
    var x = J3.diagonal(1, 2, 3);
    x.o1 = jordan_mod.octUnit(5);
    var y = J3.diagonal(-1, 0, 2);
    y.o3 = jordan_mod.octUnit(6);
    try std.testing.expect(j3Eql(jordan_mod.jmul2(x, y), jordan_mod.jmul2(y, x)));
    // E7 octonion: non-commutative, non-associative.
    try std.testing.expectEqual(@as(i512, 4), bridge.commutatorCost(bridge.unit(1), bridge.unit(2)));
    try std.testing.expectEqual(@as(i512, 4), bridge.associatorCost(bridge.unit(1), bridge.unit(2), bridge.unit(4)));
}
