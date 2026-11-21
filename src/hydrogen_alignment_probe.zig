const std = @import("std");
const fixed = @import("fixed_point.zig");
const position = @import("phi_pi_position.zig");
const h21 = @import("h21_lattice_probe.zig");
const scaling = @import("redox_scaling_tiers.zig");

const Q128 = fixed.Q128;
const Raw = fixed.Raw;
const Complex = @import("quantum/state.zig").Complex;

pub const SIDE: usize = 15;
pub const SITE_COUNT: usize = SIDE * SIDE * SIDE;
pub const BOHR_RADIUS_IN_LATTICE_STEPS = Q128{ .raw = fixed.Scale };
pub const EXP_POLYNOMIAL_TERMS: usize = 24;

/// Integer hydrogen quantum numbers; the implemented bound orbital is 1s.
pub const Orbital = struct { n: u8, l: u8, m: i8 };
pub const GROUND_STATE = Orbital{ .n = 1, .l = 0, .m = 0 };

/// Exact nonrelativistic Coulomb 1s solution in atomic units:
/// ψ_100(r) = exp(-r/a0) / sqrt(π a0³). The lattice convention sets a0=1
/// lattice step and computes amplitudes from the radial equation's solution
/// factor exp(-r/a0); normalization over the finite lattice is discrete.
pub const GroundState = struct {
    origin: position.UCoord,
    amplitudes: [SITE_COUNT]Complex,
    norm_squared: Q128,
    density_at_origin: Q128,
    discrete_normalization: Q128,
};

/// Supplied ladder endpoints are three-component field-bound labels. They
/// are retained as scalar triples and are not silently equated with 3D
/// spatial coordinates or radial distances.
pub const FieldTriple = struct { x: Q128, y: Q128, z: Q128 };

pub const LadderEndpoint = struct {
    label: []const u8,
    e_label: u3,
    coordinates: FieldTriple,
    source_kind: enum { H21_marker, wavelength_cm },
};

pub const LADDER_H21_ENDPOINT = LadderEndpoint{
    .label = "H21,H21,H21",
    .e_label = 3,
    .coordinates = .{
        .x = Q128.fromInteger(21),
        .y = Q128.fromInteger(21),
        .z = Q128.fromInteger(21),
    },
    .source_kind = .H21_marker,
};

pub const LADDER_H21_RESOLVED_ENDPOINT = LadderEndpoint{
    .label = "21cm + 7/66cm",
    .e_label = 3,
    .coordinates = .{
        .x = Q128.fromRatio(21_106_060_606_060_606, 1_000_000_000_000_000) catch unreachable,
        .y = Q128.fromRatio(21_106_060_606_060_606, 1_000_000_000_000_000) catch unreachable,
        .z = Q128.fromRatio(21_106_060_606_060_606, 1_000_000_000_000_000) catch unreachable,
    },
    .source_kind = .H21_marker,
};

pub const TRIAD_H21_CORRECTED_ENDPOINT = LadderEndpoint{
    .label = "T(5,2,-4) + 7/66cm",
    .e_label = 3,
    .coordinates = .{
        .x = Q128.fromRatio(21_211_732_984_649_753, 1_000_000_000_000_000) catch unreachable,
        .y = Q128.fromRatio(21_211_732_984_649_753, 1_000_000_000_000_000) catch unreachable,
        .z = Q128.fromRatio(21_211_732_984_649_753, 1_000_000_000_000_000) catch unreachable,
    },
    .source_kind = .H21_marker,
};

pub const LADDER_21CM_ENDPOINT = LadderEndpoint{
    .label = "21cm,21cm,21cm",
    .e_label = 6,
    .coordinates = .{
        .x = Q128.fromRatio(21_106_114_054, 1_000_000_000) catch unreachable,
        .y = Q128.fromRatio(21_106_114_054, 1_000_000_000) catch unreachable,
        .z = Q128.fromRatio(21_106_114_054, 1_000_000_000) catch unreachable,
    },
    .source_kind = .wavelength_cm,
};

pub const DefectCorrection = struct {
    numerator: i128,
    denominator: i128,
    value: Q128,
    additive_increment: Q128,
    additive_candidate: Q128,
    measured_wavelength: Q128,
    additive_residual: Q128,
    triad_base: Q128,
    triad_corrected: Q128,
    triad_corrected_residual: Q128,
    triad_resolves_to_endpoint: bool,
};

pub const TriadGeometry = struct {
    pi_anchor_dimension: u3,
    pi_anchor_label: u3,
    pi_anchor_at_e0: bool,
    representation_dimensions: u2,
    gravity_bubble_radius: Q128,
    outer_phi_exponent: i16,
    inner_phi_exponent: i16,
    pi_exponent: i16,
    outer_reading: Q128,
    pi_bubble_reading: Q128,
    inner_reading: Q128,
    triad_value: Q128,
    center: Q128,
};

/// Reads the H21 triad as a 2D representation of the 3D positioned state:
/// E0 at dimension E2 anchors the π² gravity bubble, φ⁵ supplies the outer
/// reading, and φ⁻⁴ supplies the inner reading/return. This preserves the
/// framework's connected positional interpretation without claiming the
/// scalar sum alone reconstructs all three spatial coordinates.
pub fn deriveTriadGeometry() fixed.Error!TriadGeometry {
    const phi = try Q128.fromRatio(h21.PHI_APPROX_NUMERATOR, h21.CONSTANT_APPROX_DENOMINATOR);
    const pi = try Q128.fromRatio(h21.PI_APPROX_NUMERATOR, h21.CONSTANT_APPROX_DENOMINATOR);
    const outer = try phi.pow(h21.TRIAD_PHI_POWER);
    const center = try pi.pow(h21.TRIAD_PI_POWER);
    const inner = try phi.pow(h21.TRIAD_PHI_INVERSE_POWER);
    const total = outer.add(center).add(inner);
    return .{
        .pi_anchor_dimension = h21.TRIAD_PI_POWER,
        .pi_anchor_label = 0,
        .pi_anchor_at_e0 = true,
        .representation_dimensions = 2,
        .gravity_bubble_radius = center,
        .outer_phi_exponent = h21.TRIAD_PHI_POWER,
        .inner_phi_exponent = h21.TRIAD_PHI_INVERSE_POWER,
        .pi_exponent = h21.TRIAD_PI_POWER,
        .outer_reading = outer,
        .pi_bubble_reading = center,
        .inner_reading = inner,
        .triad_value = total,
        .center = center,
    };
}

/// Uses the triad as the e3 value being resolved toward the e6 endpoint:
/// T(5,2,-4) + 7/66 cm. Also records 21cm + 7/66cm as the integer
/// wavelength-scale check. The triad-corrected residual, not the integer
/// baseline residual, decides whether the complete triad reaches e6.
pub fn deriveDefectCorrection() fixed.Error!DefectCorrection {
    const integer_cm = Q128.fromInteger(21);
    const correction = try Q128.fromRatio(7, 66);
    const corrected = integer_cm.add(correction);
    const wavelength = LADDER_21CM_ENDPOINT.coordinates.x;
    const triad_probe = h21.H21Probe.run() catch return error.Overflow;
    const triad = try Q128.fromRatio(triad_probe.phi_triad_raw, h21.Q_SCALE);
    const triad_corrected = triad.add(correction);
    return .{
        .numerator = 7,
        .denominator = 66,
        .value = correction,
        .additive_increment = correction,
        .additive_candidate = corrected,
        .measured_wavelength = wavelength,
        .additive_residual = corrected.sub(wavelength),
        .triad_base = triad,
        .triad_corrected = triad_corrected,
        .triad_corrected_residual = triad_corrected.sub(wavelength),
        .triad_resolves_to_endpoint = triad_corrected.raw == wavelength.raw,
    };
}

/// Deterministic integer/Q128 approximation of exp(-x), x>=0. Repeated
/// argument halving bounds x to <=1/16, then a 24-term alternating Taylor
/// polynomial is evaluated and squared back to exp(-x). This is a fixed
/// numerical approximation; truncation/roundoff are covered by tested
/// tolerances, not asserted as a formal interval bound.
pub fn expNegative(x: Q128) Q128 {
    if (x.raw <= 0) return if (x.raw == 0) Q128.one else Q128.zero;
    if (x.raw > 32 * fixed.Scale) return Q128.zero;
    const sixteenth = Q128.fromRatio(1, 16) catch unreachable;
    var reduced = x;
    var squarings: u8 = 0;
    while (reduced.raw > sixteenth.raw) : (squarings += 1) {
        reduced = reduced.mul(Q128.fromRatio(1, 2) catch unreachable);
    }

    var sum = Q128.one;
    var term = Q128.one;
    for (1..25) |k| {
        term = term.mul(reduced).div(Q128.fromInteger(@intCast(k))) catch unreachable;
        sum = if (k % 2 == 0) sum.add(term) else sum.sub(term);
    }
    for (0..squarings) |_| sum = sum.mul(sum);
    return sum;
}

/// Exact coordinate-to-radius convention: signed integer lattice coordinates
/// are centered on E0. Radius uses Q128 sqrt and a0=1 cell step.
pub fn radius(coord: [3]i8) Q128 {
    var squared: i256 = 0;
    for (coord) |component| {
        const c: i256 = component;
        squared += c * c;
    }
    return (Q128.fromInteger(squared).sqrt() catch unreachable);
}

/// Returns the unnormalized 1s amplitude ψ~(r)=exp(-r/a0); the omitted
/// constant cancels exactly when the finite lattice vector is normalized.
pub fn unnormalizedAmplitude(coord: [3]i8) Q128 {
    return expNegative(radius(coord).div(BOHR_RADIUS_IN_LATTICE_STEPS) catch unreachable);
}

/// Build the 15³ interior ground-state wavefunction, normalize its sampled
/// amplitudes in Q128, and leave all 16³ compounding-shell amplitudes zero.
pub fn solveGroundState() GroundState {
    var amplitudes: [SITE_COUNT]Complex = [_]Complex{Complex.zero} ** SITE_COUNT;
    var norm = Q128.zero;
    for (0..SIDE) |z| {
        for (0..SIDE) |y| {
            for (0..SIDE) |x| {
                const sx: i8 = @intCast(@as(i16, @intCast(x)) - 7);
                const sy: i8 = @intCast(@as(i16, @intCast(y)) - 7);
                const sz: i8 = @intCast(@as(i16, @intCast(z)) - 7);
                const amp = unnormalizedAmplitude(.{ sx, sy, sz });
                const idx = (z * SIDE + y) * SIDE + x;
                amplitudes[idx] = Complex.fromReal(amp);
                norm = norm.add(amp.mul(amp));
            }
        }
    }
    const normalization = norm.sqrt() catch unreachable;
    for (&amplitudes) |*amplitude| {
        amplitude.re = amplitude.re.div(normalization) catch unreachable;
    }
    return .{
        .origin = .{ .x = 7, .y = 7, .z = 7 },
        .amplitudes = amplitudes,
        .norm_squared = discreteNorm(&amplitudes),
        .density_at_origin = amplitudes[7 + SIDE * (7 + SIDE * 7)].normSquared(),
        .discrete_normalization = normalization,
    };
}

fn discreteNorm(amplitudes: []const Complex) Q128 {
    var total = Q128.zero;
    for (amplitudes) |amplitude| total = total.add(amplitude.normSquared());
    return total;
}

/// 2D central-plane density: the displayed image is a section, not the full
/// 3D state. Coordinates are signed x,y in [-7,7], z=0.
pub fn centralPlaneDensity(state: *const GroundState, x: i8, y: i8) ?Q128 {
    if (x < -7 or x > 7 or y < -7 or y > 7) return null;
    const ux: usize = @intCast(@as(i16, x) + 7);
    const uy: usize = @intCast(@as(i16, y) + 7);
    const uz: usize = 7;
    const idx = (uz * SIDE + uy) * SIDE + ux;
    return state.amplitudes[idx].normSquared();
}

/// The 21 cm transition is hyperfine spin-flip between two 1s states. The
/// electronic spatial wavefunction is unchanged; this probe therefore
/// separates the spin transition energy from the 1s spatial solution.
pub const HyperfineLine = struct {
    frequency_hz: Q128,
    wavelength_cm: Q128,
    spatial_state_unchanged: bool,
    transition_kind: enum { hyperfine_spin_flip },
};

pub fn hyperfineLine() HyperfineLine {
    const frequency = Q128.fromRatio(1_420_405_751_768, 1_000) catch unreachable;
    const wavelength = Q128.fromRatio(21_106_114_054, 1_000_000_000) catch unreachable;
    return .{
        .frequency_hz = frequency,
        .wavelength_cm = wavelength,
        .spatial_state_unchanged = true,
        .transition_kind = .hyperfine_spin_flip,
    };
}

pub const ScaleBridge = struct {
    source_inner: u16,
    source_shell: u16,
    target_inner: u16,
    target_shell: u16,
    shell_participates_only_in_compounding: bool,
    source_shell_count: u64,
    target_pair_declared: bool,
};

pub fn scaleBridge() ScaleBridge {
    return .{
        .source_inner = 15,
        .source_shell = 16,
        .target_inner = scaling.TIERS[1].inner,
        .target_shell = scaling.TIERS[1].shell,
        .shell_participates_only_in_compounding = true,
        .source_shell_count = scaling.foamCount(15, 16),
        .target_pair_declared = scaling.TIERS[1].inner == 30 and scaling.TIERS[1].shell == 32,
    };
}

test "expNegative has exact anchor and bounded approximation checks" {
    try std.testing.expectEqual(fixed.Scale, expNegative(Q128.zero).raw);
    const x = Q128.fromInteger(1);
    const e_minus_one = expNegative(x);
    const reference = Q128.fromRatio(367_879_441_171_442_321, 1_000_000_000_000_000_000) catch unreachable;
    try std.testing.expect(e_minus_one.sub(reference).abs().raw < @divTrunc(fixed.Scale, 1_000_000_000_000));
    try std.testing.expectEqual(@as(Raw, 0), expNegative(Q128.fromInteger(33)).raw);
}

test "1s Coulomb ground state is E0-centered, radial, and discretely normalized" {
    const state = solveGroundState();
    try std.testing.expectEqual(@as(usize, 7), state.origin.x);
    try std.testing.expectEqual(@as(usize, 7), state.origin.y);
    try std.testing.expectEqual(@as(usize, 7), state.origin.z);
    try std.testing.expect(state.norm_squared.sub(Q128.one).abs().raw < @divTrunc(fixed.Scale, 1_000_000_000_000));
    const center = 7 + SIDE * (7 + SIDE * 7);
    try std.testing.expect(state.amplitudes[center].re.raw > state.amplitudes[center + 1].re.raw);
    try std.testing.expect(state.amplitudes[center + 1].re.raw == state.amplitudes[center - 1].re.raw);
    try std.testing.expect(state.amplitudes[center + 1].im.raw == 0);
    try std.testing.expect(state.discrete_normalization.raw > 1 * fixed.Scale);
    try std.testing.expect(state.discrete_normalization.raw < 2 * fixed.Scale);
    try std.testing.expect(state.density_at_origin.raw > 0);
}

test "central density image is the z=0 section of the 3D state" {
    const state = solveGroundState();
    const center = centralPlaneDensity(&state, 0, 0).?;
    const axis = centralPlaneDensity(&state, 1, 0).?;
    const diagonal = centralPlaneDensity(&state, 1, 1).?;
    try std.testing.expect(center.raw > axis.raw);
    try std.testing.expect(axis.raw > diagonal.raw);
    try std.testing.expectEqual(axis.raw, centralPlaneDensity(&state, -1, 0).?.raw);
    try std.testing.expect(centralPlaneDensity(&state, 8, 0) == null);
    try std.testing.expectEqual(center, state.amplitudes[7 + SIDE * (7 + SIDE * 7)].normSquared());
    try std.testing.expectEqual(centralPlaneDensity(&state, 1, 0).?.raw, centralPlaneDensity(&state, 0, 1).?.raw);
}

test "21 cm line is a hyperfine transition that retains the 1s spatial state" {
    const line = hyperfineLine();
    try std.testing.expect(line.spatial_state_unchanged);
    try std.testing.expectEqual(@as(i256, 1_420_405_751), line.frequency_hz.toInteger());
    try std.testing.expectEqual(@as(i256, 21), line.wavelength_cm.toInteger());
    try std.testing.expectEqual(@as(u8, 2), h21.TRIAD_PI_POWER);
}

test "dimensional ladder endpoints are preserved as H21 and measured 21 cm triples" {
    try std.testing.expectEqual(@as(u3, 3), LADDER_H21_ENDPOINT.e_label);
    try std.testing.expectEqual(@as(u3, 6), LADDER_21CM_ENDPOINT.e_label);
    try std.testing.expectEqual(@as(i256, 21), LADDER_H21_ENDPOINT.coordinates.x.toInteger());
    try std.testing.expectEqual(LADDER_H21_ENDPOINT.coordinates.x.raw, LADDER_H21_ENDPOINT.coordinates.y.raw);
    try std.testing.expectEqual(LADDER_H21_ENDPOINT.coordinates.y.raw, LADDER_H21_ENDPOINT.coordinates.z.raw);
    try std.testing.expect(LADDER_21CM_ENDPOINT.coordinates.x.cmp(LADDER_H21_ENDPOINT.coordinates.x) > 0);
    try std.testing.expectEqual(LADDER_21CM_ENDPOINT.coordinates.x.raw, LADDER_21CM_ENDPOINT.coordinates.y.raw);
    try std.testing.expectEqual(LADDER_21CM_ENDPOINT.coordinates.y.raw, LADDER_21CM_ENDPOINT.coordinates.z.raw);
}

test "e6 21cm endpoint correction is additive to 21 centimeters" {
    const correction = try deriveDefectCorrection();
    try std.testing.expectEqual(@as(i128, 7), correction.numerator);
    try std.testing.expectEqual(@as(i128, 66), correction.denominator);
    try std.testing.expectEqual(try Q128.fromRatio(7, 66), correction.value);
    try std.testing.expect(correction.additive_residual.raw < 0);
    try std.testing.expect(correction.additive_increment.raw > 0);
    try std.testing.expectEqual(@as(i256, 21), correction.additive_candidate.toInteger());
    try std.testing.expect(correction.additive_candidate.sub(Q128.fromRatio(21_106, 1_000) catch unreachable).abs().raw < fixed.Scale / 1_000);
    try std.testing.expect(correction.triad_corrected.cmp(correction.triad_base) > 0);
    try std.testing.expect(correction.triad_corrected.sub(correction.additive_candidate).raw > 0);
    try std.testing.expect(correction.triad_corrected_residual.raw > fixed.Scale / 10);
    try std.testing.expect(!correction.triad_resolves_to_endpoint);
    try std.testing.expect(
        correction.triad_corrected.sub(TRIAD_H21_CORRECTED_ENDPOINT.coordinates.x).abs().raw <
            fixed.Scale / 1_000_000_000_000,
    );
}

test "H21 triad has central pi bubble and inward/outward phi readings" {
    const geometry = try deriveTriadGeometry();
    try std.testing.expect(geometry.pi_anchor_at_e0);
    try std.testing.expectEqual(@as(u3, 2), geometry.pi_anchor_dimension);
    try std.testing.expectEqual(@as(u3, 0), geometry.pi_anchor_label);
    try std.testing.expectEqual(@as(u2, 2), geometry.representation_dimensions);
    try std.testing.expectEqual(@as(i16, 5), geometry.outer_phi_exponent);
    try std.testing.expectEqual(@as(i16, -4), geometry.inner_phi_exponent);
    try std.testing.expectEqual(@as(i16, 2), geometry.pi_exponent);
    try std.testing.expect(geometry.outer_reading.cmp(geometry.pi_bubble_reading) > 0);
    try std.testing.expect(geometry.pi_bubble_reading.cmp(geometry.inner_reading) > 0);
    try std.testing.expectEqual(geometry.pi_bubble_reading.raw, geometry.center.raw);
    try std.testing.expect(geometry.triad_value.raw > 21 * fixed.Scale);
    try std.testing.expect(geometry.outer_reading.raw > 11 * fixed.Scale);
    try std.testing.expect(geometry.pi_bubble_reading.raw > 9 * fixed.Scale);
    try std.testing.expect(geometry.inner_reading.raw < fixed.Scale);
    const corrected = geometry.triad_value.add(Q128.fromRatio(7, 66) catch unreachable);
    try std.testing.expect(
        corrected.sub(TRIAD_H21_CORRECTED_ENDPOINT.coordinates.x).abs().raw <
            fixed.Scale / 1_000_000_000_000,
    );
}

test "scale bridge compounds the 16 cube shell and then proceeds to 30/32" {
    const bridge = scaleBridge();
    try std.testing.expectEqual(@as(u16, 15), bridge.source_inner);
    try std.testing.expectEqual(@as(u16, 16), bridge.source_shell);
    try std.testing.expectEqual(@as(u64, 721), bridge.source_shell_count);
    try std.testing.expectEqual(@as(u16, 30), bridge.target_inner);
    try std.testing.expectEqual(@as(u16, 32), bridge.target_shell);
    try std.testing.expect(bridge.shell_participates_only_in_compounding);
    try std.testing.expect(bridge.target_pair_declared);
}
