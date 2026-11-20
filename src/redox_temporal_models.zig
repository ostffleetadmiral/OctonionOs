//! Temporal formal models: negative group delay and indefinite causal order.
//!
//! Classification: FORMAL_MODEL. Both are integer-sequence/algebra models that
//! reproduce the *signature* of the named phenomena; neither claims the
//! physics.
//!
//! NGD model: physical negative-group-delay devices work by in-band slope
//! compensation — a filter whose transfer phase advances slowly-varying
//! envelope components. The integer model applies the canonical form
//!     y[n] = x[n] + k * (x[n] - x[n-1])
//! to a smooth bump. For k > 0 the output peak index precedes the input peak:
//! the "advanced" envelope. The band-limit caveat is real: this fails on
//! sharp transitions (information still moves causally) and the model shows
//! that directly.
//!
//! ICO model: a quantum switch routes operations in an order selected by a
//! control bit. Output differs between orders iff the operations do not
//! commute — here measured exactly through `redox_algebra_bridge`.
const std = @import("std");
const bridge = @import("redox_algebra_bridge.zig");

/// Peak index (argmax) of a nonnegative integer sequence.
pub fn peakIndex(seq: []const i512) usize {
    var best: usize = 0;
    for (seq, 0..) |v, i| {
        if (v > seq[best]) best = i;
    }
    return best;
}

/// NGD slope-compensation filter. `k` in integer units; caller provides the
/// output buffer. y[0] = x[0]. Returns the output peak index.
pub fn ngdFilter(x: []const i512, k: i512, out: []i512) usize {
    std.debug.assert(out.len == x.len);
    out[0] = x[0];
    for (1..x.len) |i| {
        out[i] = x[i] + k * (x[i] - x[i - 1]);
    }
    return peakIndex(out);
}

/// Half-Gaussian bump: x[i] = amp * R / (R + (i-c)^2), exact rational envelope
/// in integer form. A "slowly varying" band-limited signal.
pub fn bump(out: []i512, center: usize, amp: i512, radius: i512) void {
    for (out, 0..) |*v, i| {
        const d: i512 = @as(i512, @intCast(i)) - @as(i512, @intCast(center));
        v.* = @divTrunc(amp * radius * radius, radius * radius + d * d);
    }
}

/// Quantum switch over octonion left-multiplication: control bit selects the
/// order in which unit multipliers (a, b) are applied to `state`.
pub fn quantumSwitch(control: u1, a: u3, b: u3, state: bridge.Element) bridge.Element {
    const ua = bridge.unit(a);
    const ub = bridge.unit(b);
    return if (control == 0) bridge.mul(ub, bridge.mul(ua, state)) else bridge.mul(ua, bridge.mul(ub, state));
}

/// True iff the switch's two orders produce different outputs on `state` —
/// the order-sensitivity that underlies ICO models.
pub fn orderSensitive(a: u3, b: u3, state: bridge.Element) bool {
    const s0 = quantumSwitch(0, a, b, state);
    const s1 = quantumSwitch(1, a, b, state);
    for (0..8) |i| if (s0[i] != s1[i]) return true;
    return false;
}

test "NGD model: envelope peak advances on a smooth bump" {
    var x: [64]i512 = undefined;
    bump(&x, 40, 1000, 6);
    const in_peak = peakIndex(&x);
    try std.testing.expectEqual(@as(usize, 40), in_peak);
    var y: [64]i512 = undefined;
    const out_peak = ngdFilter(&x, 3, &y);
    // Slope compensation pulls energy forward: the output maximum sits
    // strictly earlier than the input maximum.
    try std.testing.expect(out_peak < in_peak);
}

test "NGD model: sharp transitions are not advanced (band-limit caveat)" {
    // A step edge has no slowly-varying envelope to advance; slope
    // compensation produces a one-sample spike, not earlier information.
    var x: [16]i512 = [_]i512{0} ** 16;
    for (8..16) |i| x[i] = 100;
    var y: [16]i512 = undefined;
    const out_peak = ngdFilter(&x, 2, &y);
    // The spike lands at index 8 — the edge itself, not before it.
    try std.testing.expectEqual(@as(usize, 8), out_peak);
    try std.testing.expectEqual(@as(i512, 300), y[8]);
}

test "quantum switch output differs iff multipliers do not commute" {
    const state = bridge.unit(5);
    // e1 and e2 do not commute (e1 e2 = e3, e2 e1 = -e3): order matters.
    try std.testing.expect(orderSensitive(1, 2, state));
    // Same unit twice: commutes trivially, orders identical.
    try std.testing.expect(!orderSensitive(1, 1, state));
    // Explicit outputs: control=0 computes b·(a·state); control=1 the reverse.
    const s0 = quantumSwitch(0, 1, 2, state);
    const s1 = quantumSwitch(1, 1, 2, state);
    // control=0: e2*(e1*e5) = e2*(-e4) = -e6 (e1*e5 = -e4 via line 1,4,5)
    var e0 = bridge.zero();
    e0[6] = -1;
    try std.testing.expectEqual(e0, s0);
    // control=1: e1*(e2*e5) = e1*e7 = +e6 (e2*e5 = +e7 via line 2,5,7)
    var e1 = bridge.zero();
    e1[6] = 1;
    try std.testing.expectEqual(e1, s1);
}
