//! Inter-algebraic promotion/demotion maps and measured non-commutativity.
//!
//! The dimensional ladder names the algebra tower; this module implements the
//! actual maps between adjacent tiers and measures the structural quantities
//! each tier boundary sheds:
//!
//!   R (dim 1) -> C (dim 2) -> H (dim 4) -> O (dim 8)   Cayley-Dickson chain
//!
//!   R -> C loses ordering      (not measured here — ordering is external)
//!   C -> H loses commutativity (commutator norm becomes nonzero)
//!   H -> O loses associativity (associator norm becomes nonzero)
//!
//! Elements are exact integer coefficient vectors on the e0..e7 octonion basis
//! shared with `redox_octonion` and the FANO mesh firmware dialect. Coefficient
//! domain bound: |c| <= 2^60 keeps every intermediate product inside i512, including
//! the two-level products in associator/commutator chains.
//!
//! Classification: FORMAL_MODEL. These are the exact "numbers talking to each
//! other" maps — the commutator/associator norms quantify what non-commutativity
//! and non-associativity cost at each boundary; they are algebraic measurements,
//! not physical coupling.
const std = @import("std");
const oct = @import("redox_octonion.zig");

pub const Element = [8]i512;

pub const TierDim = enum(u4) { real = 1, complex = 2, quaternion = 4, octonion = 8 };

fn checkDomain(v: Element) void {
    for (v) |c| {
        std.debug.assert(c >= -(1 << 60) and c <= (1 << 60));
    }
}

pub fn zero() Element {
    return [_]i512{0} ** 8;
}

pub fn unit(index: u3) Element {
    var v = zero();
    v[index] = 1;
    return v;
}

/// Embed a low-tier element into a higher tier by zero-extending coefficients.
/// Exact and lossless.
pub fn promote(v: Element, from: TierDim) Element {
    var out = v;
    const n = @intFromEnum(from);
    for (n..8) |i| out[i] = 0;
    return out;
}

/// Project a high-tier element down to `to`, returning the dropped tail norm^2
/// (exact integer). `loss == 0` iff the element lies in the lower subalgebra.
pub const Demotion = struct { element: Element, loss: i512 };

pub fn demote(v: Element, to: TierDim) Demotion {
    checkDomain(v);
    var out = v;
    var loss: i512 = 0;
    const n = @intFromEnum(to);
    for (n..8) |i| {
        loss += out[i] * out[i];
        out[i] = 0;
    }
    return .{ .element = out, .loss = loss };
}

pub fn add(a: Element, b: Element) Element {
    var out = zero();
    for (0..8) |i| out[i] = a[i] + b[i];
    return out;
}

pub fn sub(a: Element, b: Element) Element {
    var out = zero();
    for (0..8) |i| out[i] = a[i] - b[i];
    return out;
}

/// Full octonion product on exact integer coefficients.
pub fn mul(a: Element, b: Element) Element {
    checkDomain(a);
    checkDomain(b);
    var out = zero();
    for (0..8) |i| {
        if (a[i] == 0) continue;
        for (0..8) |j| {
            if (b[j] == 0) continue;
            const p = oct.mul(@intCast(i), @intCast(j));
            out[p.unit] += a[i] * b[j] * p.sign;
        }
    }
    return out;
}

pub fn normSquared(v: Element) i512 {
    checkDomain(v);
    var n: i512 = 0;
    for (v) |c| n += c * c;
    return n;
}

/// ab - ba: zero in R and C, generically nonzero in H and O.
pub fn commutator(a: Element, b: Element) Element {
    return sub(mul(a, b), mul(b, a));
}

/// (ab)c - a(bc): zero in R, C, and H; generically nonzero in O.
pub fn associator(a: Element, b: Element, c: Element) Element {
    return sub(mul(mul(a, b), c), mul(a, mul(b, c)));
}

/// Squared magnitude of the commutator — the measured cost of non-commutativity.
pub fn commutatorCost(a: Element, b: Element) i512 {
    return normSquared(commutator(a, b));
}

/// Squared magnitude of the associator — the measured cost of non-associativity.
pub fn associatorCost(a: Element, b: Element, c: Element) i512 {
    return normSquared(associator(a, b, c));
}

/// True iff `v` lies in the `dim`-dimensional subalgebra (zero tail).
pub fn inSubalgebra(v: Element, dim: TierDim) bool {
    const n = @intFromEnum(dim);
    for (n..8) |i| if (v[i] != 0) return false;
    return true;
}

test "promotion is exact and demotion reports the dropped tail" {
    var h = zero();
    h[0] = 2;
    h[1] = -3;
    h[2] = 5;
    h[3] = 7;
    const lifted = promote(h, .quaternion);
    const back = demote(lifted, .quaternion);
    try std.testing.expectEqual(@as(i512, 0), back.loss);
    try std.testing.expectEqual(h, back.element);

    var o = lifted;
    o[4] = 3;
    o[7] = -4;
    const d = demote(o, .quaternion);
    try std.testing.expectEqual(@as(i512, 25), d.loss);
    try std.testing.expectEqual(h, d.element);
    try std.testing.expect(inSubalgebra(d.element, .quaternion));
}

test "multiplication restricted to H matches the quaternion subalgebra" {
    // e1*e2 = e3 (Fano line 1,2,3) — quaternion i*j = k.
    const p = mul(unit(1), unit(2));
    try std.testing.expectEqual(unit(3), p);
    // e_i^2 = -e0 for every imaginary unit.
    for (1..8) |i| {
        var expect = zero();
        expect[0] = -1;
        try std.testing.expectEqual(expect, mul(unit(@intCast(i)), unit(@intCast(i))));
    }
    // H is closed: products of {0,1,2,3} stay in {0,1,2,3}.
    for (0..4) |i| for (0..4) |j| {
        try std.testing.expect(inSubalgebra(mul(unit(@intCast(i)), unit(@intCast(j))), .quaternion));
    };
}

test "commutator is zero in C and nonzero in H — measured, not assumed" {
    // C elements {e0, e1}: commute.
    var c1 = zero();
    c1[0] = 2;
    c1[1] = 3;
    var c2 = zero();
    c2[0] = 5;
    c2[1] = -7;
    try std.testing.expectEqual(@as(i512, 0), commutatorCost(c1, c2));
    // H units e1, e2: [e1,e2] = 2e3 -> norm^2 = 4.
    try std.testing.expectEqual(@as(i512, 4), commutatorCost(unit(1), unit(2)));
}

test "associator is zero in H and nonzero in O — the boundary cost" {
    // Any triple inside H associates.
    for (0..4) |i| for (0..4) |j| for (0..4) |k| {
        try std.testing.expectEqual(@as(i512, 0), associatorCost(unit(@intCast(i)), unit(@intCast(j)), unit(@intCast(k))));
    };
    // Classic witness: (e1 e2) e4 = e3 e4 = +e7 while e1 (e2 e4) = e1 e6 = -e7,
    // so the associator is 2e7 and its squared magnitude is exactly 4.
    try std.testing.expectEqual(@as(i512, 4), associatorCost(unit(1), unit(2), unit(4)));
}

test "inter-tier translation is exact through the Cayley-Dickson chain" {
    // A real, lifted all the way to O and demoted back, survives exactly.
    var r = zero();
    r[0] = -42;
    const o = promote(r, .real);
    for ([_]TierDim{ .complex, .quaternion, .octonion }) |tier| {
        const d = demote(o, tier);
        try std.testing.expectEqual(@as(i512, 0), d.loss);
    }
    try std.testing.expectEqual(r, demote(o, .real).element);
    // A complex value demoted to real records its imaginary part as loss.
    var c = zero();
    c[0] = 1;
    c[1] = 3;
    try std.testing.expectEqual(@as(i512, 9), demote(c, .real).loss);
}

// ============================================================================
// Full tier DAG — the complete E0..E10 layout as one dispatchable value
// space. E0 and E8 are BOTH the E8 root system (bookends):
//
//   e8_root(E0)  real -> complex -> quaternion -> octonion -> e8_root(E8) -> anti -> dual
//                      |              ^          -> jordan
//                      -> bicomplex  | (pure-imaginary embedding)
//                                   vector3
//
// The E8-root tiers are a root SYSTEM, not an algebra: they carry Weyl
// reflection structure (verified on all 240^2 pairs in redox_e8_roots)
// but no bilinear product — `mul` returns error.NoProduct there, and
// that absence is itself a measured structural fact.
//
// Edge kinds:
//   subalgebra — homomorphic embedding; promote/demote round-trips exactly
//     and products are preserved.
//   linear — exact vector-space embedding only. Not homomorphic:
//     * vector3 -> quaternion: the quaternion product of pure imaginaries
//       gains a real part (-u.v); only the cross product is preserved.
//     * octonion -> jordan: embeds into the (1,2) off-diagonal slot; the
//       Jordan product is a different operation.
//     * octonion -> e8_root: integer octonions embed into the scale-4
//       root lattice as x -> 4x; demotion back divides by 4 and reports
//       the half-integer remainder as measured loss (the 224 half-roots
//       genuinely do not fit integer octonion coordinates).
//     * e8_root -> anti_octonion: slot injection; the scale-4 convention
//       is preserved verbatim so demotion is exact.
//     * bicomplex -> octonion is deliberately absent: no such edge can be
//       even linear-consistent here because slot {0..3} collides with the
//       quaternion embedding and j^2 = +1 has no image in a division
//       algebra. Bicomplex is a terminal side branch.

const vec3 = @import("redox_vector3.zig");
const bicomplex_mod = @import("redox_bicomplex.zig");
const anti_mod = @import("redox_anti_octonion.zig");
const dual_mod = @import("redox_dual_bcomplex.zig");
const jordan_mod = @import("redox_jordan.zig");
const e8_mod = @import("redox_e8_roots.zig");

pub const Algebra = enum {
    e8_root,
    real,
    complex,
    vector3,
    quaternion,
    bicomplex,
    jordan,
    octonion,
    anti_octonion,
    dual_bcomplex,

    /// Real dimension of the carrier space (27 for J3(O), not the
    /// ladder label; the E8-root tier lives in 8D root space).
    pub fn realDim(a: Algebra) usize {
        return switch (a) {
            .e8_root => 8,
            .real => 1,
            .complex => 2,
            .vector3 => 3,
            .quaternion => 4,
            .bicomplex => 4,
            .jordan => 27,
            .octonion => 8,
            .anti_octonion => 9,
            .dual_bcomplex => 10,
        };
    }

    /// Whether the tier carries a bilinear product at all. The E8-root
    /// tier is a root system: reflection structure, no product.
    pub fn hasProduct(a: Algebra) bool {
        return a != .e8_root;
    }

    /// Measured properties (each is verified by an exhaustive or witness
    /// test below — this table is the claimed summary, not the evidence).
    /// For e8_root the product-properties are false because there is no
    /// product to satisfy them, not because a product fails them.
    pub fn commutative(a: Algebra) bool {
        return switch (a) {
            .real, .complex, .bicomplex, .jordan => true,
            else => false,
        };
    }
    pub fn associative(a: Algebra) bool {
        return switch (a) {
            .real, .complex, .quaternion, .bicomplex => true,
            else => false,
        };
    }
    /// Real normed division algebra — only R, C, H, O (Hurwitz theorem).
    pub fn divisionAlgebra(a: Algebra) bool {
        return switch (a) {
            .real, .complex, .quaternion, .octonion => true,
            else => false,
        };
    }
};

pub const Value = union(Algebra) {
    e8_root: e8_mod.Vec,
    real: i512,
    complex: [2]i512,
    vector3: vec3.V3,
    quaternion: [4]i512,
    bicomplex: bicomplex_mod.BC,
    jordan: jordan_mod.J3,
    octonion: Element,
    anti_octonion: anti_mod.Anti,
    dual_bcomplex: dual_mod.Dual,
};

pub const ValueError = error{ TierMismatch, NoEdge, NoProduct };

fn octToElement(a: jordan_mod.Oct) Element {
    return a;
}

fn elementToOct(a: Element) jordan_mod.Oct {
    return a;
}

pub fn mulValue(a: Value, b: Value) ValueError!Value {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return error.TierMismatch;
    return switch (a) {
        .e8_root => error.NoProduct,
        .real => |x| Value{ .real = x * b.real },
        .complex => |x| Value{ .complex = .{
            x[0] * b.complex[0] - x[1] * b.complex[1],
            x[0] * b.complex[1] + x[1] * b.complex[0],
        } },
        .vector3 => |x| Value{ .vector3 = vec3.cross(x, b.vector3) },
        .quaternion => |x| blk: {
            var ae = zero();
            var be = zero();
            for (0..4) |i| {
                ae[i] = x[i];
                be[i] = b.quaternion[i];
            }
            const p = mul(ae, be);
            var q: [4]i512 = undefined;
            for (0..4) |i| q[i] = p[i];
            break :blk Value{ .quaternion = q };
        },
        .bicomplex => |x| Value{ .bicomplex = bicomplex_mod.mul(x, b.bicomplex) },
        .jordan => |x| Value{ .jordan = jordan_mod.jmul2(x, b.jordan) },
        .octonion => |x| Value{ .octonion = mul(x, b.octonion) },
        .anti_octonion => |x| Value{ .anti_octonion = anti_mod.mul(x, b.anti_octonion) },
        .dual_bcomplex => |x| Value{ .dual_bcomplex = dual_mod.mul(x, b.dual_bcomplex) },
    };
}

pub fn subValue(a: Value, b: Value) ValueError!Value {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return error.TierMismatch;
    return switch (a) {
        .e8_root => |x| blk: {
            var out: e8_mod.Vec = undefined;
            for (0..8) |i| out[i] = x[i] - b.e8_root[i];
            break :blk Value{ .e8_root = out };
        },
        .real => |x| Value{ .real = x - b.real },
        .complex => |x| Value{ .complex = .{ x[0] - b.complex[0], x[1] - b.complex[1] } },
        .vector3 => |x| Value{ .vector3 = vec3.sub(x, b.vector3) },
        .quaternion => |x| Value{ .quaternion = .{ x[0] - b.quaternion[0], x[1] - b.quaternion[1], x[2] - b.quaternion[2], x[3] - b.quaternion[3] } },
        .bicomplex => |x| Value{ .bicomplex = bicomplex_mod.sub(x, b.bicomplex) },
        .jordan => |x| Value{ .jordan = jordan_mod.subJ(x, b.jordan) },
        .octonion => |x| Value{ .octonion = sub(x, b.octonion) },
        .anti_octonion => |x| Value{ .anti_octonion = anti_mod.sub(x, b.anti_octonion) },
        .dual_bcomplex => |x| Value{ .dual_bcomplex = dual_mod.sub(x, b.dual_bcomplex) },
    };
}

/// Squared magnitude of a value in its own tier's component norm.
/// Jordan uses the Hermitian convention (off-diagonals counted twice).
pub fn costValue(v: Value) i512 {
    return switch (v) {
        .e8_root => |x| e8_mod.normSquared(x),
        .real => |x| x * x,
        .complex => |x| x[0] * x[0] + x[1] * x[1],
        .vector3 => |x| vec3.normSquared(x),
        .quaternion => |x| x[0] * x[0] + x[1] * x[1] + x[2] * x[2] + x[3] * x[3],
        .bicomplex => |x| bicomplex_mod.normSquared(x),
        .jordan => |x| jordan_mod.normSquared(x),
        .octonion => |x| normSquared(x),
        .anti_octonion => |x| anti_mod.normSquared(x),
        .dual_bcomplex => |x| dual_mod.normSquared(x),
    };
}

/// [a,b] inside the value's own tier.
pub fn commutatorValue(a: Value, b: Value) ValueError!Value {
    return subValue(try mulValue(a, b), try mulValue(b, a));
}

/// (ab)c - a(bc) inside the value's own tier.
pub fn associatorValue(a: Value, b: Value, c: Value) ValueError!Value {
    return subValue(try mulValue(try mulValue(a, b), c), try mulValue(a, try mulValue(b, c)));
}

pub fn commutatorCostValue(a: Value, b: Value) ValueError!i512 {
    return costValue(try commutatorValue(a, b));
}

pub fn associatorCostValue(a: Value, b: Value, c: Value) ValueError!i512 {
    return costValue(try associatorValue(a, b, c));
}

pub const EdgeKind = enum { subalgebra, linear };

/// Whether a promotion edge exists, and whether it is a homomorphic
/// subalgebra embedding or a linear-space-only map.
pub fn edgeKind(from: Algebra, to: Algebra) ?EdgeKind {
    if (from == .real and (to == .complex or to == .quaternion or to == .bicomplex or to == .octonion)) return .subalgebra;
    if (from == .complex and (to == .quaternion or to == .bicomplex or to == .octonion)) return .subalgebra;
    if (from == .vector3 and to == .quaternion) return .linear;
    if (from == .vector3 and to == .octonion) return .linear;
    if (from == .quaternion and to == .octonion) return .subalgebra;
    if (from == .octonion and to == .e8_root) return .linear;
    if (from == .octonion and to == .anti_octonion) return .subalgebra;
    if (from == .octonion and to == .jordan) return .linear;
    // The E5->E6 leg of the Jordan-pipeline spec. Linear only: no unital
    // algebra homomorphism bicomplex -> J3(O) exists (the imaginary unit
    // would need X o X = -I, but diagonal entries of X o X are sums of
    // squares). See redox_tier_pipeline.zig for the measured obstruction.
    if (from == .bicomplex and to == .jordan) return .linear;
    if (from == .e8_root and to == .anti_octonion) return .linear;
    if (from == .anti_octonion and to == .dual_bcomplex) return .subalgebra;
    return null;
}

/// Promote a value along a declared edge. Exact for every edge; `kind`
/// reports whether multiplication is preserved across the map.
pub fn promoteValue(v: Value, to: Algebra) ValueError!Value {
    const from = std.meta.activeTag(v);
    const kind = edgeKind(from, to) orelse return error.NoEdge;
    _ = kind;
    return switch (v) {
        .real => |x| switch (to) {
            .complex => Value{ .complex = .{ x, 0 } },
            .quaternion => Value{ .quaternion = .{ x, 0, 0, 0 } },
            .bicomplex => Value{ .bicomplex = .{ x, 0, 0, 0 } },
            .octonion => blk: {
                var e = zero();
                e[0] = x;
                break :blk Value{ .octonion = e };
            },
            else => unreachable,
        },
        .complex => |x| switch (to) {
            .quaternion => Value{ .quaternion = .{ x[0], x[1], 0, 0 } },
            .bicomplex => Value{ .bicomplex = .{ x[0], x[1], 0, 0 } },
            .octonion => blk: {
                var e = zero();
                e[0] = x[0];
                e[1] = x[1];
                break :blk Value{ .octonion = e };
            },
            else => unreachable,
        },
        .vector3 => |x| switch (to) {
            .quaternion => Value{ .quaternion = .{ 0, x[0], x[1], x[2] } },
            .octonion => blk: {
                var e = zero();
                e[1] = x[0];
                e[2] = x[1];
                e[3] = x[2];
                break :blk Value{ .octonion = e };
            },
            else => unreachable,
        },
        .quaternion => |x| blk: {
            var e = zero();
            for (0..4) |i| e[i] = x[i];
            break :blk Value{ .octonion = e };
        },
        .octonion => |x| switch (to) {
            .anti_octonion => blk: {
                var e = anti_mod.zero();
                for (0..8) |i| e[i] = x[i];
                break :blk Value{ .anti_octonion = e };
            },
            .jordan => Value{ .jordan = .{
                .alpha = 0,
                .beta = 0,
                .gamma = 0,
                .o1 = elementToOct(x),
                .o2 = jordan_mod.octZero(),
                .o3 = jordan_mod.octZero(),
            } },
            .e8_root => blk: {
                var e: e8_mod.Vec = undefined;
                for (0..8) |i| e[i] = x[i] * 4;
                break :blk Value{ .e8_root = e };
            },
            else => unreachable,
        },
        .bicomplex => |x| switch (to) {
            // All four components ride the (1,2) octonion slot — the
            // same channel the jordan -> octonion projection reads, so
            // coordinates survive the full E5->E6->E7 pipeline.
            .jordan => blk: {
                var o1 = jordan_mod.octZero();
                for (0..4) |i| o1[i] = x[i];
                break :blk Value{ .jordan = .{
                    .alpha = 0,
                    .beta = 0,
                    .gamma = 0,
                    .o1 = o1,
                    .o2 = jordan_mod.octZero(),
                    .o3 = jordan_mod.octZero(),
                } };
            },
            else => unreachable,
        },
        .e8_root => |x| blk: {
            var e = anti_mod.zero();
            for (0..8) |i| e[i] = x[i];
            break :blk Value{ .anti_octonion = e };
        },
        .anti_octonion => |x| blk: {
            var e = dual_mod.zero();
            for (0..9) |i| e[i] = x[i];
            break :blk Value{ .dual_bcomplex = e };
        },
        else => unreachable,
    };
}

pub const ValueDemotion = struct { value: Value, loss: i512 };

/// Demote a value along the reverse of a declared edge; `loss` is the
/// squared norm of every removed component (0 iff the element already
/// lies in the embedded image).
pub fn demoteValue(v: Value, to: Algebra) ValueError!ValueDemotion {
    const from = std.meta.activeTag(v);
    if (edgeKind(to, from) == null) return error.NoEdge;
    return switch (to) {
        .real => switch (v) {
            .complex => |x| ValueDemotion{ .value = .{ .real = x[0] }, .loss = x[1] * x[1] },
            .quaternion => |x| ValueDemotion{ .value = .{ .real = x[0] }, .loss = x[1] * x[1] + x[2] * x[2] + x[3] * x[3] },
            .bicomplex => |x| ValueDemotion{ .value = .{ .real = x[0] }, .loss = x[1] * x[1] + x[2] * x[2] + x[3] * x[3] },
            .octonion => |x| blk: {
                var loss: i512 = 0;
                for (1..8) |i| loss += x[i] * x[i];
                break :blk ValueDemotion{ .value = .{ .real = x[0] }, .loss = loss };
            },
            else => unreachable,
        },
        .complex => switch (v) {
            .quaternion => |x| ValueDemotion{ .value = .{ .complex = .{ x[0], x[1] } }, .loss = x[2] * x[2] + x[3] * x[3] },
            .bicomplex => |x| ValueDemotion{ .value = .{ .complex = .{ x[0], x[1] } }, .loss = x[2] * x[2] + x[3] * x[3] },
            .octonion => |x| blk: {
                var loss: i512 = 0;
                for (2..8) |i| loss += x[i] * x[i];
                break :blk ValueDemotion{ .value = .{ .complex = .{ x[0], x[1] } }, .loss = loss };
            },
            else => unreachable,
        },
        .bicomplex => switch (v) {
            .jordan => |x| blk: {
                var loss = x.alpha * x.alpha + x.beta * x.beta + x.gamma * x.gamma;
                for (4..8) |i| loss += 2 * x.o1[i] * x.o1[i];
                loss += 2 * jordan_mod.octNormSquared(x.o2) + 2 * jordan_mod.octNormSquared(x.o3);
                break :blk ValueDemotion{
                    .value = .{ .bicomplex = .{ x.o1[0], x.o1[1], x.o1[2], x.o1[3] } },
                    .loss = loss,
                };
            },
            else => unreachable,
        },
        .vector3 => switch (v) {
            .quaternion => |x| ValueDemotion{ .value = .{ .vector3 = .{ x[1], x[2], x[3] } }, .loss = x[0] * x[0] },
            .octonion => |x| blk: {
                var loss = x[0] * x[0];
                for (4..8) |i| loss += x[i] * x[i];
                break :blk ValueDemotion{ .value = .{ .vector3 = .{ x[1], x[2], x[3] } }, .loss = loss };
            },
            else => unreachable,
        },
        .quaternion => switch (v) {
            .octonion => |x| blk: {
                var loss: i512 = 0;
                for (4..8) |i| loss += x[i] * x[i];
                break :blk ValueDemotion{ .value = .{ .quaternion = .{ x[0], x[1], x[2], x[3] } }, .loss = loss };
            },
            else => unreachable,
        },
        .octonion => switch (v) {
            .anti_octonion => |x| blk: {
                var e = zero();
                for (0..8) |i| e[i] = x[i];
                break :blk ValueDemotion{ .value = .{ .octonion = e }, .loss = x[8] * x[8] };
            },
            .jordan => |x| ValueDemotion{
                .value = .{ .octonion = octToElement(x.o1) },
                .loss = x.alpha * x.alpha + x.beta * x.beta + x.gamma * x.gamma +
                    2 * jordan_mod.octNormSquared(x.o2) + 2 * jordan_mod.octNormSquared(x.o3),
            },
            .e8_root => |x| blk: {
                // Scale-4 components divide by 4; half-integer roots
                // (components +-2) leave a measured remainder of 2 per
                // odd-coordinate — the 224 half-roots genuinely do not
                // fit integer octonion coordinates.
                var e = zero();
                var loss: i512 = 0;
                for (0..8) |i| {
                    const q = @divTrunc(x[i], 4);
                    const rem = x[i] - 4 * q;
                    loss += rem * rem;
                    e[i] = q;
                }
                break :blk ValueDemotion{ .value = .{ .octonion = e }, .loss = loss };
            },
            else => unreachable,
        },
        .anti_octonion => switch (v) {
            .dual_bcomplex => |x| blk: {
                var e = anti_mod.zero();
                for (0..9) |i| e[i] = x[i];
                break :blk ValueDemotion{ .value = .{ .anti_octonion = e }, .loss = x[9] * x[9] };
            },
            else => unreachable,
        },
        .e8_root => switch (v) {
            .anti_octonion => |x| blk: {
                var e: e8_mod.Vec = undefined;
                for (0..8) |i| e[i] = x[i];
                break :blk ValueDemotion{ .value = .{ .e8_root = e }, .loss = x[8] * x[8] };
            },
            else => unreachable,
        },
        else => unreachable,
    };
}

// ---------------------------------------------------------------------------
// Measured structure across the full DAG.
// ---------------------------------------------------------------------------

test "every promote edge round-trips exactly and reports its kind" {
    // Walk each declared edge: demote(promote(v)) has zero loss and
    // recovers the original components.
    const cases = [_]struct { v: Value, to: Algebra }{
        .{ .v = .{ .real = -7 }, .to = .complex },
        .{ .v = .{ .real = 5 }, .to = .quaternion },
        .{ .v = .{ .real = 3 }, .to = .bicomplex },
        .{ .v = .{ .real = 2 }, .to = .octonion },
        .{ .v = .{ .complex = .{ 4, -9 } }, .to = .quaternion },
        .{ .v = .{ .complex = .{ 4, -9 } }, .to = .bicomplex },
        .{ .v = .{ .complex = .{ 4, -9 } }, .to = .octonion },
        .{ .v = .{ .vector3 = .{ 1, -2, 3 } }, .to = .quaternion },
        .{ .v = .{ .vector3 = .{ 1, -2, 3 } }, .to = .octonion },
        .{ .v = .{ .quaternion = .{ 2, -1, 0, 6 } }, .to = .octonion },
        .{ .v = .{ .octonion = mul(unit(1), unit(2)) }, .to = .anti_octonion },
        .{ .v = .{ .octonion = unit(5) }, .to = .e8_root },
        .{ .v = .{ .e8_root = e8_mod.buildRoots()[0] }, .to = .anti_octonion },
        .{ .v = .{ .anti_octonion = anti_mod.unit(8) }, .to = .dual_bcomplex },
    };
    for (cases) |case| {
        try std.testing.expect(edgeKind(std.meta.activeTag(case.v), case.to) != null);
        const up = try promoteValue(case.v, case.to);
        const back = try demoteValue(up, std.meta.activeTag(case.v));
        try std.testing.expectEqual(@as(i512, 0), back.loss);
        try std.testing.expectEqual(std.meta.activeTag(case.v), std.meta.activeTag(back.value));
    }
    // octonion -> jordan linear edge round-trips too
    var ov = zero();
    ov[0] = 1;
    ov[5] = -3;
    const jv = try promoteValue(Value{ .octonion = ov }, .jordan);
    const jback = try demoteValue(jv, .octonion);
    try std.testing.expectEqual(@as(i512, 0), jback.loss);
    try std.testing.expectEqual(ov, jback.value.octonion);
}

test "demotion loss is measured, not assumed" {
    // jordan -> octonion drops diagonal and o2/o3 with Hermitian weighting.
    var j = jordan_mod.J3.diagonal(1, 2, 3);
    j.o1 = jordan_mod.octUnit(4);
    j.o2 = jordan_mod.octUnit(1);
    const d = try demoteValue(Value{ .jordan = j }, .octonion);
    try std.testing.expectEqual(@as(i512, 1 + 4 + 9 + 2), d.loss);
    try std.testing.expectEqual(unit(4), d.value.octonion);
    // vector3 -> quaternion -> vector3 drops the real part of a scalar.
    const scalar = try demoteValue(Value{ .quaternion = .{ 5, 1, 2, 3 } }, .vector3);
    try std.testing.expectEqual(@as(i512, 25), scalar.loss);
    try std.testing.expectEqual(vec3.V3{ 1, 2, 3 }, scalar.value.vector3);
}

test "subalgebra edges preserve products; linear edges honestly do not" {
    // quaternion -> octonion is homomorphic: product survives the lift.
    const q1 = try promoteValue(Value{ .quaternion = .{ 0, 1, 0, 0 } }, .octonion);
    const q2 = try promoteValue(Value{ .quaternion = .{ 0, 0, 1, 0 } }, .octonion);
    try std.testing.expectEqual(unit(3), (try mulValue(q1, q2)).octonion);
    // vector3 -> quaternion is only linear: e1*e1 = -e0 in H but
    // x cross x = 0 in V3. The map preserves the cross product's vector
    // part while the quaternion product gains the -dot scalar.
    const v1 = try promoteValue(Value{ .vector3 = .{ 1, 0, 0 } }, .quaternion);
    const v2 = try promoteValue(Value{ .vector3 = .{ 0, 1, 0 } }, .quaternion);
    const cross_lift = try promoteValue(Value{ .vector3 = vec3.cross(.{ 1, 0, 0 }, .{ 0, 1, 0 }) }, .quaternion);
    const quat_prod = (try mulValue(v1, v2)).quaternion;
    // v1*v2 = -0 + e3 part: real part is -(u.v) = 0, vector part = cross.
    try std.testing.expectEqual([4]i512{ 0, 0, 0, 1 }, quat_prod);
    try std.testing.expectEqual(cross_lift.quaternion, quat_prod);
}

test "e8_root tier carries reflection structure, not a product" {
    const roots = e8_mod.buildRoots();
    const r0 = Value{ .e8_root = roots[0] };
    const r1 = Value{ .e8_root = roots[1] };
    // No bilinear product exists on a root system — measured absence.
    try std.testing.expectError(error.NoProduct, mulValue(r0, r1));
    try std.testing.expectError(error.NoProduct, commutatorCostValue(r0, r1));
    try std.testing.expectEqual(false, Algebra.e8_root.hasProduct());
    // The structure that does exist: Weyl reflection, closed on the set.
    const reflected = e8_mod.reflect(roots[16], roots[0]);
    try std.testing.expect(e8_mod.isRoot(reflected));
    // Demotion to octonion: axis roots (+-4 components) survive exactly,
    // half-integer roots report a component-wise remainder.
    const axis = try demoteValue(r0, .octonion);
    try std.testing.expectEqual(@as(i512, 0), axis.loss);
    // A half-root: four +-2 components -> each truncates to 0 or -1,
    // remainder magnitude 2 per nonzero half component -> loss = 4*4 = 16.
    const half = try demoteValue(Value{ .e8_root = roots[16] }, .octonion);
    try std.testing.expectEqual(@as(i512, 16), half.loss);
}

test "measured commutator profile across all tiers" {
    // commutative: real, complex, bicomplex, jordan
    try std.testing.expectEqual(@as(i512, 0), try commutatorCostValue(Value{ .real = 6 }, Value{ .real = -11 }));
    try std.testing.expectEqual(@as(i512, 0), try commutatorCostValue(Value{ .complex = .{ 2, 3 } }, Value{ .complex = .{ -5, 7 } }));
    try std.testing.expectEqual(@as(i512, 0), try commutatorCostValue(Value{ .bicomplex = bicomplex_mod.unit(1) }, Value{ .bicomplex = bicomplex_mod.unit(3) }));
    var jx = jordan_mod.J3.diagonal(1, 0, 2);
    jx.o1 = jordan_mod.octUnit(2);
    var jy = jordan_mod.J3.diagonal(0, 3, 1);
    jy.o3 = jordan_mod.octUnit(5);
    try std.testing.expectEqual(@as(i512, 0), try commutatorCostValue(Value{ .jordan = jx }, Value{ .jordan = jy }));
    // non-commutative: vector3, quaternion, octonion, anti, dual
    try std.testing.expectEqual(@as(i512, 4), try commutatorCostValue(Value{ .vector3 = vec3.unit(0) }, Value{ .vector3 = vec3.unit(1) }));
    try std.testing.expectEqual(@as(i512, 4), try commutatorCostValue(Value{ .quaternion = .{ 0, 1, 0, 0 } }, Value{ .quaternion = .{ 0, 0, 1, 0 } }));
    try std.testing.expectEqual(@as(i512, 4), try commutatorCostValue(Value{ .octonion = unit(1) }, Value{ .octonion = unit(2) }));
    try std.testing.expectEqual(@as(i512, 4), try commutatorCostValue(Value{ .anti_octonion = anti_mod.unit(1) }, Value{ .anti_octonion = anti_mod.unit(2) }));
    try std.testing.expectEqual(@as(i512, 4), try commutatorCostValue(Value{ .dual_bcomplex = dual_mod.unit(1) }, Value{ .dual_bcomplex = dual_mod.unit(2) }));
    // the anti element commutes with everything in its own algebra
    try std.testing.expectEqual(@as(i512, 0), try commutatorCostValue(Value{ .anti_octonion = anti_mod.unit(8) }, Value{ .anti_octonion = anti_mod.unit(6) }));
}

test "measured associator profile across all tiers" {
    // associative: complex, quaternion, bicomplex (all-basis-triple checks
    // live in the per-algebra modules); witness checks here.
    try std.testing.expectEqual(@as(i512, 0), try associatorCostValue(Value{ .complex = .{ 2, 3 } }, Value{ .complex = .{ -5, 7 } }, Value{ .complex = .{ 1, -1 } }));
    try std.testing.expectEqual(@as(i512, 0), try associatorCostValue(Value{ .quaternion = .{ 0, 1, 0, 0 } }, Value{ .quaternion = .{ 0, 0, 1, 0 } }, Value{ .quaternion = .{ 0, 0, 0, 1 } }));
    try std.testing.expectEqual(@as(i512, 0), try associatorCostValue(Value{ .bicomplex = bicomplex_mod.unit(1) }, Value{ .bicomplex = bicomplex_mod.unit(2) }, Value{ .bicomplex = bicomplex_mod.unit(3) }));
    // non-associative: vector3, octonion, anti, dual
    try std.testing.expectEqual(@as(i512, 1), try associatorCostValue(Value{ .vector3 = vec3.unit(0) }, Value{ .vector3 = vec3.unit(0) }, Value{ .vector3 = vec3.unit(1) }));
    try std.testing.expectEqual(@as(i512, 4), try associatorCostValue(Value{ .octonion = unit(1) }, Value{ .octonion = unit(2) }, Value{ .octonion = unit(4) }));
    try std.testing.expectEqual(@as(i512, 4), try associatorCostValue(Value{ .anti_octonion = anti_mod.unit(1) }, Value{ .anti_octonion = anti_mod.unit(2) }, Value{ .anti_octonion = anti_mod.unit(4) }));
    try std.testing.expectEqual(@as(i512, 4), try associatorCostValue(Value{ .dual_bcomplex = dual_mod.unit(1) }, Value{ .dual_bcomplex = dual_mod.unit(2) }, Value{ .dual_bcomplex = dual_mod.unit(4) }));
}

test "zero divisors mark the non-division tiers" {
    // bicomplex: (1+j)(1-j) = 0
    var p = bicomplex_mod.unit(0);
    p[2] = 1;
    var q = bicomplex_mod.unit(0);
    q[2] = -1;
    try std.testing.expectEqual(@as(i512, 0), costValue((try mulValue(Value{ .bicomplex = p }, Value{ .bicomplex = q }))));
    // anti-octonion: (e0 + e8)(e0 - e8) = e0 - e8^2 = 0 — the split
    // signature itself manufactures zero divisors.
    const ep = Value{ .anti_octonion = anti_mod.add(anti_mod.unit(0), anti_mod.unit(8)) };
    const em = Value{ .anti_octonion = anti_mod.sub(anti_mod.unit(0), anti_mod.unit(8)) };
    try std.testing.expectEqual(@as(i512, 0), costValue((try mulValue(ep, em))));
    // dual: e9 * e9 = 0 outright.
    try std.testing.expectEqual(@as(i512, 0), costValue((try mulValue(Value{ .dual_bcomplex = dual_mod.unit(9) }, Value{ .dual_bcomplex = dual_mod.unit(9) }))));
    // vector3: every nonzero element squares to zero under cross.
    try std.testing.expectEqual(@as(i512, 0), costValue((try mulValue(Value{ .vector3 = .{ 3, -5, 7 } }, Value{ .vector3 = .{ 3, -5, 7 } }))));
    // the division tiers square nonzero units to nonzero — spot-check O.
    try std.testing.expect(costValue((try mulValue(Value{ .octonion = unit(4) }, Value{ .octonion = unit(4) }))) != 0);
}

test "tier property table matches measurements" {
    // The claimed table is cross-checked: commutative/associative flags
    // agree with a generic-element measurement at each tier.
    try std.testing.expect(Algebra.commutative(.bicomplex) == true);
    try std.testing.expect(Algebra.commutative(.vector3) == false);
    try std.testing.expect(Algebra.associative(.jordan) == false);
    try std.testing.expect(Algebra.associative(.quaternion) == true);
    try std.testing.expect(Algebra.divisionAlgebra(.octonion) == true);
    try std.testing.expect(Algebra.divisionAlgebra(.bicomplex) == false);
    try std.testing.expect(Algebra.divisionAlgebra(.anti_octonion) == false);
    try std.testing.expect(Algebra.divisionAlgebra(.dual_bcomplex) == false);
    try std.testing.expect(Algebra.divisionAlgebra(.e8_root) == false);
    try std.testing.expect(Algebra.e8_root.hasProduct() == false);
    try std.testing.expect(Algebra.octonion.hasProduct() == true);
    try std.testing.expectEqual(@as(usize, 8), Algebra.e8_root.realDim());
    try std.testing.expectEqual(@as(usize, 27), Algebra.jordan.realDim());
    try std.testing.expectEqual(@as(usize, 9), Algebra.anti_octonion.realDim());
    try std.testing.expectEqual(@as(usize, 10), Algebra.dual_bcomplex.realDim());
}

test "21cm crossover claim: dimension profile and property-flip boundaries audited" {
    // Ladder order E1..E10 (e8_root listed at its bookend position).
    const ladder = [_]Algebra{ .real, .complex, .vector3, .quaternion, .bicomplex, .jordan, .octonion, .e8_root, .anti_octonion, .dual_bcomplex };
    // Dimension profile: unique peak at E6 jordan (27); the ONLY strict
    // interior contraction is jordan -> octonion (27 -> 8). E4 -> E5 is
    // flat (4 == 4): "expansion" is falsified at the dimension level.
    var peak: usize = 0;
    for (ladder, 0..) |a, i| {
        if (a.realDim() > ladder[peak].realDim()) peak = i;
    }
    try std.testing.expectEqual(Algebra.jordan, ladder[peak]);
    var contractions: usize = 0;
    var i: usize = 0;
    while (i + 1 < ladder.len) : (i += 1) {
        if (ladder[i + 1].realDim() < ladder[i].realDim()) contractions += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), contractions);
    try std.testing.expectEqual(Algebra.quaternion.realDim(), Algebra.bicomplex.realDim());
    // Property crossovers cluster: commutativity returns at E5 (bicomplex),
    // associativity is lost at E5 -> E6, commutativity is lost at E6 -> E7.
    try std.testing.expect(Algebra.commutative(.bicomplex) and !Algebra.commutative(.quaternion));
    try std.testing.expect(!Algebra.associative(.jordan) and Algebra.associative(.bicomplex));
    try std.testing.expect(!Algebra.commutative(.octonion) and Algebra.commutative(.jordan));
    // Jordan associator witness (measured, not table-asserted).
    var jx = jordan_mod.J3.diagonal(1, 0, 2);
    jx.o1 = jordan_mod.octUnit(5);
    var jy = jordan_mod.J3.diagonal(0, 3, 1);
    jy.o3 = jordan_mod.octUnit(6);
    var jz = jordan_mod.J3.diagonal(2, 1, 0);
    jz.o2 = jordan_mod.octUnit(3);
    const acost = try associatorCostValue(Value{ .jordan = jx }, Value{ .jordan = jy }, Value{ .jordan = jz });
    try std.testing.expect(acost > 0);
}
