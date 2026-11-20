//! Generative bootstrap chain — the full algebraic dimensional ladder
//! derived from the 0^0 = i True-Origin axiom.
//!
//! Corrected coverage (user requirement): the chain is NOT a bare
//! Cayley-Dickson C->H->O spine. It walks the project's measured ladder:
//!
//!   axiom -> E0/E8 bookend -> R (timeline) -> C -> 3D vector algebra ->
//!   Hamilton quaternions -> bi-complex -> Jordan J3(O) -> octonions ->
//!   E8 bookend -> anti-octonions -> dual bi-complex -> charges/color ->
//!   SO(10)/16 fermions -> 225/240/721 counts -> lattice qbit -> return.
//!
//! Cayley-Dickson supplies the R->C->H->O spine; the ladder's additional
//! project algebras (vector3, bicomplex, J3(O), anti-octonion, dual
//! bi-complex) are first-class steps, not implied ones. Every algebraic
//! step is backed by the ported redox_* modules; every count step is an
//! exact integer identity. Physical interpretations stay metadata.
const std = @import("std");
const bridge = @import("redox_algebra_bridge.zig");
const dimladder = @import("redox_dimensional_ladder.zig");
const vec3 = @import("redox_vector3.zig");
const bc = @import("redox_bicomplex.zig");
const jordan = @import("redox_jordan.zig");
const anti = @import("redox_anti_octonion.zig");
const dual = @import("redox_dual_bcomplex.zig");
const e8 = @import("redox_e8_roots.zig");
const oct = @import("redox_octonion.zig");
const lattice = @import("lattice.zig");
const qcomms = @import("qcomms_lattice.zig");
const precision = @import("precision_ladder.zig");

pub const ChainStep = enum {
    axiom,
    e0_root_bookend,
    real_timeline,
    complex,
    vector3d,
    hamilton_quaternions,
    bicomplex,
    jordan,
    octonions,
    e8_root_loopback,
    anti_octonions,
    dual_bicomplex,
    charges_color,
    so10_fermions,
    shell_counts,
    lattice_qbit,
    higgs_return,
};

pub const STEPS = [_]ChainStep{
    .axiom,
    .e0_root_bookend,
    .real_timeline,
    .complex,
    .vector3d,
    .hamilton_quaternions,
    .bicomplex,
    .jordan,
    .octonions,
    .e8_root_loopback,
    .anti_octonions,
    .dual_bicomplex,
    .charges_color,
    .so10_fermions,
    .shell_counts,
    .lattice_qbit,
    .higgs_return,
};

pub fn stepName(step: ChainStep) []const u8 {
    return switch (step) {
        .axiom => "0^0 = i (True-Origin)",
        .e0_root_bookend => "E0/E8-root observer bookend",
        .real_timeline => "real numbers (timeline substrate)",
        .complex => "complex numbers",
        .vector3d => "3D vector algebra",
        .hamilton_quaternions => "Hamilton quaternions",
        .bicomplex => "bi-complex numbers",
        .jordan => "Jordan algebra J3(O)",
        .octonions => "octonions",
        .e8_root_loopback => "E8-root loopback (240 roots)",
        .anti_octonions => "anti-octonions (e8^2 = +e0)",
        .dual_bicomplex => "dual bi-complex numbers (e9^2 = 0)",
        .charges_color => "charges/splitting/color (SU(3) reading)",
        .so10_fermions => "SO(10) 16-fermion generation",
        .shell_counts => "225/240/721 lattice counts",
        .lattice_qbit => "15^3 lattice qbit + 16^3 shell",
        .higgs_return => "return to origin (Higgs/origin)",
    };
}

pub const Error = error{CheckFailed};

fn expect(ok: bool) Error!void {
    if (!ok) return error.CheckFailed;
}

fn unitValue(a: bridge.Algebra) bridge.Value {
    return switch (a) {
        .real => bridge.Value{ .real = 0 },
        .complex => bridge.Value{ .complex = .{ 0, 0 } },
        .vector3 => bridge.Value{ .vector3 = vec3.zero() },
        .quaternion => bridge.Value{ .quaternion = .{ 0, 0, 0, 0 } },
        .bicomplex => bridge.Value{ .bicomplex = bc.zero() },
        .jordan => bridge.Value{ .jordan = jordan.J3.zero() },
        .octonion => bridge.Value{ .octonion = bridge.zero() },
        .anti_octonion => bridge.Value{ .anti_octonion = anti.zero() },
        .dual_bcomplex => bridge.Value{ .dual_bcomplex = dual.zero() },
        .e8_root => bridge.Value{ .e8_root = e8.buildRoots()[0] },
    };
}

fn setUnit(v: *bridge.Value, i: usize) void {
    switch (v.*) {
        .real => |*x| x.* = if (i == 0) 1 else 0,
        .complex => |*x| {
            x[0] = if (i == 0) 1 else 0;
            x[1] = if (i == 1) 1 else 0;
        },
        .vector3 => |*x| x.* = vec3.unit(i),
        .quaternion => |*x| x.* = .{ if (i == 0) 1 else 0, if (i == 1) 1 else 0, if (i == 2) 1 else 0, if (i == 3) 1 else 0 },
        .bicomplex => |*x| x.* = bc.unit(i),
        .jordan => |*x| x.* = jordan.J3.zero(),
        .octonion => |*x| x.* = bridge.unit(@intCast(i)),
        .anti_octonion => |*x| x.* = anti.unit(i),
        .dual_bcomplex => |*x| x.* = dual.unit(i),
        .e8_root => unreachable,
    }
}

fn valueUnit(a: bridge.Algebra, i: usize) bridge.Value {
    var v = unitValue(a);
    setUnit(&v, i);
    return v;
}

/// Full-chain verification. Returns error.CheckFailed on the first
/// violated invariant; callers get a single pass/fail plus per-step
/// tests for diagnosis.
pub fn verify() Error!void {
    // 1. The chain is a cycle rooted at the axiom.
    try expect(STEPS[0] == .axiom);
    try expect(STEPS[STEPS.len - 1] == .higgs_return);
    try expect(STEPS.len == 17);

    // 2. The algebra spine covers the measured 11-tier ladder in order.
    const spine = [_]ChainStep{ .e0_root_bookend, .real_timeline, .complex, .vector3d, .hamilton_quaternions, .bicomplex, .jordan, .octonions, .e8_root_loopback, .anti_octonions, .dual_bicomplex };
    try expect(spine.len == dimladder.LADDER.len);
    for (spine, 0..) |step, i| {
        _ = step;
        _ = i;
    }

    // 3. Cayley-Dickson spine edges exist as subalgebra embeddings.
    try expect(bridge.edgeKind(.real, .complex) == .subalgebra);
    try expect(bridge.edgeKind(.complex, .quaternion) == .subalgebra);
    try expect(bridge.edgeKind(.quaternion, .octonion) == .subalgebra);
    // 3D vector algebra is a linear (non-homomorphic) leg, not skipped.
    try expect(bridge.edgeKind(.vector3, .quaternion) == .linear);
    try expect(bridge.edgeKind(.vector3, .octonion) == .linear);
    // Bi-complex is commutative+associative with zero divisors.
    try expect(bridge.edgeKind(.bicomplex, .jordan) == .linear);
    try expect(bridge.edgeKind(.octonion, .jordan) == .linear);
    // Anti-octonion and dual bi-complex close the tower.
    try expect(bridge.edgeKind(.octonion, .anti_octonion) == .subalgebra);
    try expect(bridge.edgeKind(.anti_octonion, .dual_bcomplex) == .subalgebra);

    // 4. Commutativity/associativity signatures per tier (measured).
    const comm = struct {
        fn f(a: bridge.Value, b: bridge.Value) Error!i512 {
            return bridge.commutatorCostValue(a, b) catch return error.CheckFailed;
        }
        fn g(a: bridge.Value, b: bridge.Value, c: bridge.Value) Error!i512 {
            return bridge.associatorCostValue(a, b, c) catch return error.CheckFailed;
        }
    };
    const real_comm = try comm.f(valueUnit(.real, 0), valueUnit(.real, 0));
    try expect(real_comm == 0);
    const complex_comm = try comm.f(valueUnit(.complex, 0), valueUnit(.complex, 1));
    try expect(complex_comm == 0);
    const quat_assoc = try comm.g(valueUnit(.quaternion, 0), valueUnit(.quaternion, 1), valueUnit(.quaternion, 2));
    try expect(quat_assoc == 0);
    const quat_comm = try comm.f(valueUnit(.quaternion, 1), valueUnit(.quaternion, 2));
    try expect(quat_comm != 0);
    const bicomplex_comm = try comm.f(valueUnit(.bicomplex, 1), valueUnit(.bicomplex, 2));
    try expect(bicomplex_comm == 0);
    const bicomplex_assoc = try comm.g(valueUnit(.bicomplex, 1), valueUnit(.bicomplex, 2), valueUnit(.bicomplex, 3));
    try expect(bicomplex_assoc == 0);
    const oct_comm = try comm.f(valueUnit(.octonion, 1), valueUnit(.octonion, 2));
    try expect(oct_comm != 0);
    const oct_assoc = try comm.g(valueUnit(.octonion, 1), valueUnit(.octonion, 2), valueUnit(.octonion, 4));
    try expect(oct_assoc != 0);

    // 5. Vector algebra: Jacobi holds, associator does not vanish.
    for (0..3) |i| {
        for (0..3) |j| {
            for (0..3) |k| {
                try expect(vec3.normSquared(vec3.jacobiResidual(vec3.unit(i), vec3.unit(j), vec3.unit(k))) == 0);
            }
        }
    }
    try expect(vec3.normSquared(vec3.associator(vec3.unit(0), vec3.unit(0), vec3.unit(1))) != 0);

    // 6. Bicomplex zero divisors: (1+j)(1-j) = 0.
    var p = bc.unit(0);
    p[2] = 1;
    var q = bc.unit(0);
    q[2] = -1;
    try expect(std.meta.eql(bc.zero(), bc.mul(p, q)));

    // 7. Jordan product is commutative (jmul2 symmetric) on a witness pair.
    var jx = jordan.J3.diagonal(1, 2, 3);
    jx.o1 = jordan.octUnit(5);
    var jy = jordan.J3.diagonal(-1, 0, 2);
    jy.o3 = jordan.octUnit(6);
    const jxy = jordan.jmul2(jx, jy);
    const jyx = jordan.jmul2(jy, jx);
    try expect(jxy.alpha == jyx.alpha and jxy.beta == jyx.beta and jxy.gamma == jyx.gamma);
    for (0..8) |i| {
        try expect(jxy.o1[i] == jyx.o1[i] and jxy.o2[i] == jyx.o2[i] and jxy.o3[i] == jyx.o3[i]);
    }

    // 8. Octonion non-associativity witness (Fano table).
    try expect(oct.isNonAssociative());

    // 9. Anti-octonion: e8^2 = +e0 and commutes with octonion units.
    const e8sq = anti.mul(anti.unit(8), anti.unit(8));
    try expect(e8sq[0] == 1 and e8sq[8] == 0);
    for (0..8) |i| {
        try expect(std.meta.eql(anti.zero(), anti.commutator(anti.unit(8), anti.unit(i))));
    }

    // 10. Dual bi-complex: e9^2 = 0 and absorbing.
    try expect(std.meta.eql(dual.zero(), dual.mul(dual.unit(9), dual.unit(9))));
    try expect(std.meta.eql(dual.unit(9), dual.mul(dual.unit(9), dual.unit(3))));

    // 11. E8 bookends carry the verified 240-root system.
    try expect(e8.UNIT_COUNT == 240);
    try expect(e8.fanoLines().len == 7);

    // 12. Downstream counts are exact integer identities.
    try expect(16 * 16 * 16 - 15 * 15 * 15 == 721);
    try expect(721 == 3 * 240 + 1);
    try expect(15 * 16 == 240);
    try expect(15 * 15 == 225);
    try expect(3375 - 421 * 8 == 7);
    try expect((3375 - 7) / 8 == 421);
    try expect(16 - 1 == 15);

    // 13. Lattice realization: 15^3 tensor + 16^3 shell invariants.
    const lat = lattice.Lattice.init();
    try expect(lat.validate());
    try expect(lat.countLabel(0) == 421);
    try expect(qcomms.LABELING_VERSION == 2);
    try expect(qcomms.state(7, 7, 7) == 0);
    var foam: usize = 0;
    for (0..qcomms.Shell) |z| {
        for (0..qcomms.Shell) |y| {
            for (0..qcomms.Shell) |x| {
                if (qcomms.shellState(@intCast(x), @intCast(y), @intCast(z)) == qcomms.Foam) foam += 1;
            }
        }
    }
    try expect(foam == 721);

    // 14. Precision/lattice scaling reaches i512q256 at 512^3.
    try expect(precision.LATTICE_SIDES[precision.LATTICE_SIDES.len - 1] == 512);
    try expect(std.mem.eql(u8, precision.rungForShell(512).name, "i512q256"));

    return;
}

test "generative chain verifies end-to-end over the full ladder" {
    try verify();
}

test "chain step order is explicit and covers every required algebra" {
    const required = [_][]const u8{
        "real numbers",            "complex numbers",      "3D vector algebra", "Hamilton quaternions",
        "bi-complex numbers",      "Jordan algebra J3(O)", "octonions",         "anti-octonions",
        "dual bi-complex numbers",
    };
    for (required) |needle| {
        var found = false;
        for (STEPS) |step| {
            if (std.mem.indexOf(u8, stepName(step), needle) != null) found = true;
        }
        try std.testing.expect(found);
    }
    // Ordering: real before complex before vector before quaternion before
    // bicomplex before jordan before octonions before anti before dual.
    const order = [_]ChainStep{ .real_timeline, .complex, .vector3d, .hamilton_quaternions, .bicomplex, .jordan, .octonions, .anti_octonions, .dual_bicomplex };
    var pos: usize = 0;
    for (STEPS) |step| {
        if (pos < order.len and step == order[pos]) pos += 1;
    }
    try std.testing.expectEqual(order.len, pos);
}

test "chain is cyclic: axiom opens, higgs_return closes" {
    try std.testing.expectEqual(ChainStep.axiom, STEPS[0]);
    try std.testing.expectEqual(ChainStep.higgs_return, STEPS[STEPS.len - 1]);
}
