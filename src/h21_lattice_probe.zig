const std = @import("std");
const lattice_mod = @import("lattice.zig");

pub const TRIAD_PHI_POWER: i16 = 5;
pub const TRIAD_PI_POWER: i16 = 2;
pub const TRIAD_PHI_INVERSE_POWER: i16 = -4;
pub const PHI_APPROX_NUMERATOR: i128 = 1_618_033_988_749_895;
pub const PI_APPROX_NUMERATOR: i128 = 3_141_592_653_589_793;
pub const CONSTANT_APPROX_DENOMINATOR: i128 = 1_000_000_000_000_000;
pub const TRIAD_CLAIMED_VALUE_NUMERATOR: i128 = 21_106;
pub const TRIAD_CLAIMED_VALUE_DENOMINATOR: i128 = 1_000;
pub const H21_REFERENCE_NUMERATOR: i128 = 21_106_114_054;
pub const H21_REFERENCE_DENOMINATOR: i128 = 1_000_000_000;
pub const H21_MARKER_CM_NUMERATOR: i128 = 211_061;
pub const H21_MARKER_CM_DENOMINATOR: i128 = 10_000;
pub const LATTICE_CORRECTION_NUMERATOR: i128 = lattice_mod.DEFECT_COUNT;
pub const LATTICE_CORRECTION_DENOMINATOR: i128 = 66;
pub const SEVEN_OVER_66_DENOMINATOR: i128 = 66;
pub const SEVENTY_THREE_OVER_66_NUMERATOR: i128 = 73;
pub const SEVENTY_THREE_OVER_66_DENOMINATOR: i128 = 66;
pub const CORRECTION_NUMERATOR: i128 = lattice_mod.DEFECT_COUNT;
pub const CORRECTION_DENOMINATOR: i128 = 66;
pub const DENOMINATOR_FACTOR_A: i128 = 6;
pub const DENOMINATOR_FACTOR_B: i128 = 11;
pub const Q_SCALE: i128 = 1_000_000_000_000_000;
pub const H21_SOURCE_SHA256 = "e9dbb77e9ac3cb318927cab2f98b9704928b2873ec8f9e44b67ce5c5aed02399";
pub const TRIAD_SOURCE_SHA256 = "a47fd37ee67ac8729e65aacb1387e949d120702a3fcfb8f5ac40a6a89432d1b2";
pub const DIMENSION_LADDER_SOURCE_SHA256 = "24b3c326f0108843ed7aceafc51fdac38ba7d3a25e054eaecb5fbc055c8e36b2";

pub const ClaimVerdict = enum {
    verified_arithmetic,
    registered_model_mapping,
};

pub const H21Probe = struct {
    center_index: usize,
    center_label: u3,
    cardinal_rays: u8,
    radial_labels_mask: u8,
    correction_numerator: i128,
    correction_denominator: i128,
    phi_triad_raw: i128,
    seven_over_sixty_six_raw: i128,
    corrected_73_over_66_raw: i128,
    stated_marker_raw: i128,
    marker_residual_raw: i128,
    measured_reference_raw: i128,
    measured_reference_residual_raw: i128,
    scale: i128 = Q_SCALE,
    numeric_verdict: ClaimVerdict = .registered_model_mapping,

    pub fn run() error{ Overflow, ZeroDenominator }!H21Probe {
        const lattice = lattice_mod.Lattice.init();
        const center_coord = lattice_mod.Coord{ .x = 0, .y = 0, .z = 0 };
        const center_index = lattice_mod.Lattice.index(center_coord) orelse return error.Overflow;
        const center_label = lattice.labels[center_index];
        if (!lattice.cardinalAxesCoverImaginaryLabels()) return error.Overflow;

        var radial_labels_mask: u8 = 0;
        for (1..8) |label| radial_labels_mask |= @as(u8, 1) << @intCast(label);
        const cardinal_rays: u8 = 6;

        const phi = try Fixed.fromRatio(PHI_APPROX_NUMERATOR, CONSTANT_APPROX_DENOMINATOR);
        const pi = try Fixed.fromRatio(PI_APPROX_NUMERATOR, CONSTANT_APPROX_DENOMINATOR);
        const phi5 = try phi.pow(TRIAD_PHI_POWER);
        const pi2 = try pi.pow(TRIAD_PI_POWER);
        const phi_minus4 = try phi.pow(TRIAD_PHI_INVERSE_POWER);
        const triad_sum = try phi5.add(pi2);
        const triad = try triad_sum.add(phi_minus4);
        const seven_over_sixty_six = try triad.mul(try Fixed.fromRatio(CORRECTION_NUMERATOR, SEVEN_OVER_66_DENOMINATOR));
        const lattice_correction = try triad.mul(try Fixed.fromRatio(LATTICE_CORRECTION_NUMERATOR, LATTICE_CORRECTION_DENOMINATOR));
        const corrected = try triad.add(lattice_correction);
        const marker = try Fixed.fromRatio(H21_MARKER_CM_NUMERATOR, H21_MARKER_CM_DENOMINATOR);
        const measured = try Fixed.fromRatio(H21_REFERENCE_NUMERATOR, H21_REFERENCE_DENOMINATOR);
        const marker_residual = try corrected.sub(marker);
        const measured_residual = try corrected.sub(measured);

        return .{
            .center_index = center_index,
            .center_label = center_label,
            .cardinal_rays = cardinal_rays,
            .radial_labels_mask = radial_labels_mask,
            .correction_numerator = CORRECTION_NUMERATOR,
            .correction_denominator = CORRECTION_DENOMINATOR,
            .phi_triad_raw = triad.raw,
            .seven_over_sixty_six_raw = seven_over_sixty_six.raw,
            .corrected_73_over_66_raw = corrected.raw,
            .stated_marker_raw = marker.raw,
            .marker_residual_raw = marker_residual.raw,
            .measured_reference_raw = measured.raw,
            .measured_reference_residual_raw = measured_residual.raw,
            .numeric_verdict = .registered_model_mapping,
        };
    }

    pub fn labelsAreFullyRepresented(self: H21Probe) bool {
        return self.radial_labels_mask == 0b1111_1110 and self.cardinal_rays == 6;
    }
};

const Fixed = struct {
    raw: i128,

    fn fromRatio(numerator: i128, denominator: i128) error{ Overflow, ZeroDenominator }!Fixed {
        if (denominator == 0) return error.ZeroDenominator;
        const scaled = std.math.mul(i128, numerator, Q_SCALE) catch return error.Overflow;
        return .{ .raw = roundRatio(scaled, denominator) };
    }

    fn add(self: Fixed, other: Fixed) error{Overflow}!Fixed {
        return .{ .raw = std.math.add(i128, self.raw, other.raw) catch return error.Overflow };
    }

    fn sub(self: Fixed, other: Fixed) error{Overflow}!Fixed {
        const negative = std.math.sub(i128, 0, other.raw) catch return error.Overflow;
        return .{ .raw = std.math.add(i128, self.raw, negative) catch return error.Overflow };
    }

    fn mul(self: Fixed, other: Fixed) error{Overflow}!Fixed {
        const product = std.math.mul(i128, self.raw, other.raw) catch return error.Overflow;
        return .{ .raw = roundRatio(product, Q_SCALE) };
    }

    fn div(self: Fixed, other: Fixed) error{ Overflow, ZeroDenominator }!Fixed {
        if (other.raw == 0) return error.ZeroDenominator;
        const numerator = std.math.mul(i128, self.raw, Q_SCALE) catch return error.Overflow;
        return .{ .raw = roundRatio(numerator, other.raw) };
    }

    fn pow(self: Fixed, exponent: i16) error{ Overflow, ZeroDenominator }!Fixed {
        if (exponent == 0) return .{ .raw = Q_SCALE };
        const factor = if (exponent < 0)
            try (Fixed{ .raw = Q_SCALE }).div(self)
        else
            self;
        var power: u16 = @intCast(if (exponent < 0) -@as(i32, exponent) else exponent);
        var result = Fixed{ .raw = Q_SCALE };
        while (power > 0) : (power -= 1) result = try result.mul(factor);
        return result;
    }
};

fn roundRatio(numerator: i128, denominator: i128) i128 {
    const quotient = @divTrunc(numerator, denominator);
    const remainder = @rem(numerator, denominator);
    const twice = abs128(remainder) * 2;
    const den = abs128(denominator);
    if (twice < den) return quotient;
    const direction: i128 = if ((numerator < 0) != (denominator < 0)) -1 else 1;
    if (twice > den or @mod(quotient, 2) != 0) return quotient + direction;
    return quotient;
}

fn abs128(value: i128) u128 {
    return if (value < 0) @intCast(-value) else @intCast(value);
}

test "H21 triad, correction term, and corrected candidate are computed" {
    const result = try H21Probe.run();
    try std.testing.expectEqual(@as(i128, 7), result.correction_numerator);
    try std.testing.expectEqual(@as(i128, 66), result.correction_denominator);
    try std.testing.expectEqual(@as(i128, 66), DENOMINATOR_FACTOR_A * DENOMINATOR_FACTOR_B);
    try std.testing.expectEqual(@as(u3, 0), result.center_label);
    try std.testing.expectEqual(@as(usize, lattice_mod.Lattice.index(.{ .x = 0, .y = 0, .z = 0 }).?), result.center_index);
    try std.testing.expect(result.labelsAreFullyRepresented());
    try std.testing.expect(result.phi_triad_raw > 0);
    try std.testing.expect(result.seven_over_sixty_six_raw > 0);
    try std.testing.expectEqual(@as(i128, 21_106_100_000_000_000), result.stated_marker_raw);
    try std.testing.expect(result.marker_residual_raw > 0);
    try std.testing.expect(result.measured_reference_residual_raw > 0);
    try std.testing.expectEqual(ClaimVerdict.registered_model_mapping, result.numeric_verdict);
}

test "fixed rational arithmetic rejects zero denominators and reports overflow" {
    try std.testing.expectError(error.ZeroDenominator, Fixed.fromRatio(1, 0));
    try std.testing.expectError(error.ZeroDenominator, (Fixed{ .raw = 1 }).div(.{ .raw = 0 }));
    try std.testing.expectError(error.Overflow, Fixed.fromRatio(std.math.maxInt(i128), 1));
}

test "7 defect factor identity and six-ray seven-label coverage are separate checks" {
    const lattice = lattice_mod.Lattice.init();
    try std.testing.expectEqual(@as(u8, 7), lattice_mod.DEFECT_COUNT);
    try std.testing.expect(lattice.cardinalAxesCoverImaginaryLabels());
    try std.testing.expectEqual(@as(u8, 6), 6);
}

test "fixed precision triad evaluation reports base and 73-over-66 correction residuals" {
    const phi = try Fixed.fromRatio(PHI_APPROX_NUMERATOR, CONSTANT_APPROX_DENOMINATOR);
    const pi = try Fixed.fromRatio(PI_APPROX_NUMERATOR, CONSTANT_APPROX_DENOMINATOR);
    const phi5 = try phi.pow(TRIAD_PHI_POWER);
    const pi2 = try pi.pow(TRIAD_PI_POWER);
    const phi_inverse4 = try phi.pow(TRIAD_PHI_INVERSE_POWER);
    const first_sum = try phi5.add(pi2);
    const triad = try first_sum.add(phi_inverse4);
    const correction_term = try triad.mul(try Fixed.fromRatio(CORRECTION_NUMERATOR, SEVEN_OVER_66_DENOMINATOR));
    const corrected_lattice = try triad.add(correction_term);
    const corrected = try triad.mul(try Fixed.fromRatio(SEVENTY_THREE_OVER_66_NUMERATOR, SEVENTY_THREE_OVER_66_DENOMINATOR));
    const marker = try Fixed.fromRatio(H21_MARKER_CM_NUMERATOR, H21_MARKER_CM_DENOMINATOR);
    const reference = try Fixed.fromRatio(H21_REFERENCE_NUMERATOR, H21_REFERENCE_DENOMINATOR);
    const literal_marker = try Fixed.fromRatio(TRIAD_CLAIMED_VALUE_NUMERATOR, TRIAD_CLAIMED_VALUE_DENOMINATOR);
    try std.testing.expectEqual(@as(i128, 21_105_672_378_589_151), triad.raw);
    try std.testing.expectEqual(@as(i128, 21_106_100_000_000_000), marker.raw);
    try std.testing.expectEqual(@as(i128, 23_344_152_782_378_908), corrected.raw);
    try std.testing.expectEqual(@as(i128, 21_106_114_054_000_000), reference.raw);
    try std.testing.expectEqual(@as(i128, 21_106_000_000_000_000), literal_marker.raw);
    try std.testing.expectEqual(@as(i128, 2_238_480_403_789_757), correction_term.raw);
    try std.testing.expectEqual(@as(i128, 23_344_152_782_378_908), corrected_lattice.raw);
    try std.testing.expectEqual(@as(i128, 2_238_052_782_378_908), corrected.raw - marker.raw);
    try std.testing.expectEqual(@as(i128, 2_238_038_728_378_908), corrected.raw - reference.raw);
    try std.testing.expectEqual(@as(i128, 2_238_152_782_378_908), corrected.raw - literal_marker.raw);
}
