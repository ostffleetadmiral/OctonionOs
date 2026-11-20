// retrocausal_probe.zig — the two-boundary (TSVF/ABL) probe.
//
// The claim under test (drawer discussion, retrocausal "architectural
// exemption" proposal): does imposing a FUTURE boundary condition change
// interior statistics — i.e., does retrocausality have operational meaning
// inside the lattice model, or is it decoration on identical dynamics?
//
// The honest operationalization is the two-state vector formalism
// (Aharonov–Bergmann–Lebowitz): pre-select |i> at t=0, post-select |f> at
// t=T, and the interior distribution at intermediate time t is
//
//   P_ABL(k)  ∝  |<k|U(t)|i>|^2 * |<k|U+(T-t)|f>|^2
//            =  |phi_fwd[k]|^2 * |phi_bwd[k]|^2 ,  normalized by Z.
//
// The backward vector phi_bwd = U(-(T-t))|f> exists because the propagator
// is reversible — U(-t) = U(t)^dagger is already proven in
// lattice_evolution.zig ("reversibility" test). This harness computes it
// and measures what the second boundary actually does.
//
// Four filed measurements + one control:
//   T1  backward propagation is real: phi_bwd != |f> — the future state
//       genuinely rewinds through the lattice (computed, not asserted).
//   T2  ABL interior != forward interior: total-variation distance > 0 —
//       post-selection biases interior statistics. Real selection effect.
//   T3  the "null boundary" still biases: post-selecting |f> = U(T)|i>
//       (the state forward evolution produces anyway) gives phi_bwd ==
//       phi_fwd (round-trip consistency) yet P_ABL = |phi|^4/Z != |phi|^2
//       — NO future boundary leaves the interior untouched.
//   T4  exclusion/enrichment counts: sites where forward amplitude ~0 but
//       the two-boundary distribution places weight, and vice versa —
//       "allowed by the future, forbidden by the past" is measurable.
//   T5  reversibility on the actual run: U(T-t) phi_bwd recovers |f>.
//
// What this does NOT claim: that the future CAUSES the past. The backward
// vector is U^dagger applied — it exists because the dynamics are
// unitary (reversible computing), which is the mechanism the corpus
// means by "reversible computing". ABL statistics are conditioning on
// both boundaries — mathematically real, physically a selection effect.
// The distinction "final boundary selects" vs "future sends information
// backward" is NOT separable in this harness — filed exactly as that:
//   OPERATIONAL: post-selection bias is real and measured.
//   INTERPRETATION: causal-arrow direction is not distinguishable here.

const std = @import("std");
const evo = @import("lattice_evolution.zig");
const ham = @import("lattice_hamiltonian.zig");
const st = @import("state.zig");
const fixed = @import("../fixed_point.zig");

const Q128 = fixed.Q128;
const Cx = st.Complex;

// Instrument lattice: 8^3 = 512 sites (16^3 canonical fabric is documented
// scope — this probe measures the two-boundary effect, not the fabric
// scale; the Hamiltonian is the same structure, smaller instrument).
const DIM = 8;
const N = DIM * DIM * DIM;

const EPS: fixed.Raw = @divTrunc(fixed.Scale, 1 << 40);

fn basisState(h: ham.Hamiltonian, x: usize, y: usize, z: usize, psi: *[N]Cx) void {
    const k = h.idx(x, y, z);
    for (0..N) |i| psi[i] = if (i == k) Cx.one else Cx.zero;
}

fn probs(h: ham.Hamiltonian, psi: []const Cx, p: *[N]Q128) void {
    _ = h;
    for (0..N) |i| p[i] = psi[i].normSquared();
}

/// ABL weight: w_k = pf[k] * pb[k]; normalized copy out -> w.
fn ablWeights(pf: []const Q128, pb: []const Q128, w: *[N]Q128) Q128 {
    var z = Q128.zero;
    for (0..N) |k| {
        w[k] = pf[k].mul(pb[k]);
        z = z.add(w[k]);
    }
    return z;
}

fn tvDistance(a: []const Q128, b: []const Q128) Q128 {
    var acc = Q128.zero;
    for (0..N) |k| acc = acc.add(a[k].sub(b[k]).abs());
    return acc.div(Q128.fromInteger(2)) catch unreachable;
}

fn runLeg(h: ham.Hamiltonian, psi: []const Cx, out: []Cx, tau: Q128, scratch: []Cx) void {
    const order = evo.neededOrder(h, tau.abs(), EPS);
    evo.propagate(h, psi, out, tau, order, scratch);
}

const Run = struct {
    h: ham.Hamiltonian,
    fwd: [N]Cx,
    bwd: [N]Cx,
    natural_final: [N]Cx,
    pA: [N]Q128,
    pB: [N]Q128,
    pB_null: [N]Q128,
    scratch: [4 * N]Cx,
};

fn execute(r: *Run) void {
    r.h = ham.Hamiltonian.init(DIM, DIM, DIM, Q128.fromInteger(1), Q128.zero, Q128.fromInteger(10), Q128.zero);
    const tau = Q128.fromInteger(1); // interior leg (T/2 of a two-leg span)

    var psi_i: [N]Cx = undefined;
    var psi_f: [N]Cx = undefined;
    basisState(r.h, 2, 3, 3, &psi_i); // interior seed
    basisState(r.h, 5, 4, 4, &psi_f); // different site — nontrivial boundary

    // forward vector at t = T/2
    runLeg(r.h, psi_i[0..], r.fwd[0..], tau, r.scratch[0..]);
    // backward vector at t = T/2: U(-(T-t))|f>
    runLeg(r.h, psi_f[0..], r.bwd[0..], tau.neg(), r.scratch[0..]);
    // natural forward endpoint: |f_null> = U(T)|i>
    var mid: [N]Cx = undefined;
    runLeg(r.h, r.fwd[0..], mid[0..], tau, r.scratch[0..]);
    @memcpy(r.natural_final[0..], mid[0..]);

    probs(r.h, r.fwd[0..], &r.pA);
    var pb: [N]Q128 = undefined;
    probs(r.h, r.bwd[0..], &pb);

    var w: [N]Q128 = undefined;
    const z = ablWeights(r.pA[0..], pb[0..], &w);
    for (0..N) |k| r.pB[k] = w[k].div(z) catch unreachable;

    // null boundary: backward-evolve the NATURAL final state -> phi_fwd
    var bwd_null: [N]Cx = undefined;
    runLeg(r.h, mid[0..], bwd_null[0..], tau.neg(), r.scratch[0..]);
    var pb_null: [N]Q128 = undefined;
    probs(r.h, bwd_null[0..], &pb_null);
    const z2 = ablWeights(r.pA[0..], pb_null[0..], &w);
    for (0..N) |k| r.pB_null[k] = w[k].div(z2) catch unreachable;
}

test "T1: backward propagation is real — rewound final state differs from the boundary state" {
    var r: Run = undefined;
    execute(&r);
    // phi_bwd is a spread wavefunction, |f> is a delta — they must differ
    var distinct: usize = 0;
    for (0..N) |k| {
        if (r.bwd[k].normSquared().raw > EPS) distinct += 1;
    }
    try std.testing.expect(distinct > 1); // rewound across many sites
}

test "T2: ABL interior differs from forward-only interior — post-selection bias is measured" {
    var r: Run = undefined;
    execute(&r);
    const tv = tvDistance(r.pA[0..], r.pB[0..]);
    // nonzero bias — and bounded below 1 (distributions overlap)
    try std.testing.expect(tv.raw > EPS);
    try std.testing.expect(tv.raw < Q128.one.raw);
}

test "T3: null boundary still biases — consistent future does not leave interior untouched" {
    var r: Run = undefined;
    execute(&r);
    // backward-evolving the natural endpoint recovers the forward vector
    // (round-trip consistency): then P_B_null = |phi|^4/Z — a sharpening,
    // not a pass-through.
    const tv = tvDistance(r.pA[0..], r.pB_null[0..]);
    try std.testing.expect(tv.raw > EPS); // strictly sharpened, not identical
}

test "T4: future-allowed/past-forbidden sites are countable — selection has a signature" {
    var r: Run = undefined;
    execute(&r);
    var enriched: usize = 0; // P_B > 4*P_A
    var suppressed: usize = 0; // P_B < P_A/4 and P_A > EPS
    const four = Q128.fromInteger(4);
    for (0..N) |k| {
        if (r.pB[k].raw > r.pA[k].mul(four).raw) enriched += 1;
        if (r.pA[k].raw > EPS and r.pB[k].mul(four).raw < r.pA[k].raw) suppressed += 1;
    }
    // both directions of selection must occur for the bias to be real
    try std.testing.expect(enriched > 0 and suppressed > 0);
}

test "T5: reversibility on the actual run — U(T-t) applied to phi_bwd recovers |f>" {
    var r: Run = undefined;
    execute(&r);
    var psi_f: [N]Cx = undefined;
    basisState(r.h, 5, 4, 4, &psi_f);
    var back: [N]Cx = undefined;
    const tau = Q128.fromInteger(1);
    runLeg(r.h, r.bwd[0..], back[0..], tau, r.scratch[0..]);
    const fid = r.h.inner(psi_f[0..], back[0..]).normSquared();
    const tol: fixed.Raw = @divTrunc(fixed.Scale, 1 << 30);
    try std.testing.expect(fid.raw > fixed.Scale - tol);
}

test "filed verdict: two-boundary bias is real; causal arrow is not separable" {
    var r: Run = undefined;
    execute(&r);
    // the measured quantities — all must hold simultaneously:
    //   (a) forward distribution normalized
    const nA = r.h.normSq(r.fwd[0..]);
    const tol: fixed.Raw = @divTrunc(fixed.Scale, 1 << 30);
    try std.testing.expect(@abs(nA.raw - fixed.Scale) < tol);
    //   (b) the two post-selected distributions differ from forward
    try std.testing.expect(tvDistance(r.pA[0..], r.pB[0..]).raw > EPS);
    try std.testing.expect(tvDistance(r.pA[0..], r.pB_null[0..]).raw > EPS);
    //   (c) ...and from each other — boundary CHOICE matters
    try std.testing.expect(tvDistance(r.pB[0..], r.pB_null[0..]).raw > EPS);
    // Interpretation: (a)+(b) = selection is operationally real;
    // (c) = the future boundary's identity changes the interior — the
    // strongest honest statement the model supports. Whether that is
    // "retrocausality" or "conditioning" is the interpretational boundary
    // this harness cannot cross — filed as indistinguishable, per TSVF.
}
