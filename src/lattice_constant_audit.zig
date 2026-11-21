//! Exact lattice-native integer census compared against the 145-row triad
//! table. This module does not fit signatures or infer physical units.
const std = @import("std");
const fp = @import("fixed_point.zig");
const scaled = @import("scaled_lattice_probe.zig");
const mound = @import("mound_triad.zig");
const table_mod = @import("mound_triad_table.zig");
const hydrogen = @import("h21_lattice_probe.zig");

const Q128 = fp.Q128;

pub const SCALE_COUNT: usize = 7;
pub const CANDIDATE_COUNT: usize = SCALE_COUNT * 6;
pub const SCALE_ZERO_SIDE: u16 = 15;
pub const FIRST_DENSE_SCALE: u16 = 32;
pub const TRIAD_ROW_COUNT: usize = table_mod.TABLE_LEN;

/// Scale 0 is 15^3; scale 1 is absent; scales 2..7 use sides 32..1024.
/// Scale 0 uses the canonical histogram; larger scale coloring/counts are
/// modeled as uniform modulo-8 metadata and are not dense enumerations.
pub const ScaleSignature = struct {
    scale_index: u3,
    interior_side: u16,
    shell_side: u16,
    interior_sites: u64,
    shell_sites: u64,
    shell_only_when_compounding: bool,
    label_counts: [8]u64,
    label_imbalance: [8]i64,
    e0_sites: u64,
    defect_count: u64,
    e0_fraction: Q128,
    e0_fraction_reduced_num: u64,
    e0_fraction_reduced_den: u64,
    cardinal_ray_sites: u64,
    coloring_has_unique_defect: bool,
};

pub const ScaleSignatureError = error{ScaleOverflow};

pub const AuditError = error{ScaleOverflow};

fn gcd(a_in: u64, b_in: u64) u64 {
    var a = a_in;
    var b = b_in;
    while (b != 0) {
        const r = a % b;
        a = b;
        b = r;
    }
    return a;
}

/// Integer-only scale signature; only scale 0 uses the canonical coloring.
pub fn scaleSignature(scale_index: u3) ScaleSignatureError!ScaleSignature {
    if (scale_index == 1) return error.ScaleOverflow;
    const side_u32: u32 = if (scale_index == 0) SCALE_ZERO_SIDE else @as(u32, FIRST_DENSE_SCALE) << (scale_index - 2);
    if (side_u32 > std.math.maxInt(u16)) return error.ScaleOverflow;
    const side: u16 = @intCast(side_u32);
    const shell: u16 = if (scale_index == 0) 16 else @intCast(@as(u32, side) * 2);
    const interior_sites = cube(side);
    const shell_sites = cube(shell) - interior_sites;
    const counts = if (scale_index == 0)
        scaled.stateHistogram(side)
    else
        [_]u64{interior_sites / 8} ** 8;
    var imbalance: [8]i64 = undefined;
    for (counts, 0..) |count, label| {
        const total: i64 = @intCast(interior_sites);
        imbalance[label] = 8 * @as(i64, @intCast(count)) - total;
    }
    const e0_sites = counts[0];
    const defect_count: u64 = if (scale_index == 0) 7 else 0;
    const has_unique_defect = scale_index == 0 and scaled.defectState(side) != null;
    const divisor = gcd(e0_sites, interior_sites);
    const e0_fraction = Q128.fromRatio(e0_sites, interior_sites) catch return error.ScaleOverflow;
    return .{
        .scale_index = scale_index,
        .interior_side = side,
        .shell_side = shell,
        .interior_sites = interior_sites,
        .shell_sites = shell_sites,
        .shell_only_when_compounding = true,
        .label_counts = counts,
        .label_imbalance = imbalance,
        .e0_sites = e0_sites,
        .defect_count = defect_count,
        .e0_fraction = e0_fraction,
        .e0_fraction_reduced_num = e0_sites / divisor,
        .e0_fraction_reduced_den = interior_sites / divisor,
        .cardinal_ray_sites = if (scale_index == 0) 42 else 0,
        .coloring_has_unique_defect = has_unique_defect,
    };
}

fn cube(side: u16) u64 {
    const n: u64 = side;
    return n * n * n;
}

pub fn allScaleSignatures() ScaleSignatureError![SCALE_COUNT]ScaleSignature {
    var signatures: [SCALE_COUNT]ScaleSignature = undefined;
    signatures[0] = try scaleSignature(0);
    for (1..SCALE_COUNT) |slot| {
        const scale_index: u3 = @intCast(slot + 1);
        signatures[slot] = try scaleSignature(scale_index);
    }
    return signatures;
}

pub const CandidateKind = enum {
    lattice_volume,
    e0_population,
    defect_count,
    shell_population,
    e0_fraction,
    defect_fraction,
};

pub const Candidate = struct {
    scale_index: u3,
    kind: CandidateKind,
    label: []const u8,
    value: Q128,
};

/// The candidate set contains exact scale-local integers and rational
/// fractions only. Duplicate numerical values are retained with provenance.
pub fn candidates() AuditError![CANDIDATE_COUNT]Candidate {
    const signatures = try allScaleSignatures();
    var out: [CANDIDATE_COUNT]Candidate = undefined;
    for (signatures, 0..) |signature, index| {
        const scale_index = signature.scale_index;
        const defect_fraction = Q128.fromRatio(signature.defect_count, signature.interior_sites) catch return error.ScaleOverflow;
        const values = [_]struct { kind: CandidateKind, label: []const u8, value: Q128 }{
            .{ .kind = .lattice_volume, .label = "interior_sites", .value = Q128.fromInteger(signature.interior_sites) },
            .{ .kind = .e0_population, .label = "e0_sites", .value = Q128.fromInteger(signature.e0_sites) },
            .{ .kind = .defect_count, .label = "defect_count", .value = Q128.fromInteger(signature.defect_count) },
            .{ .kind = .shell_population, .label = "compounding_shell_sites", .value = Q128.fromInteger(signature.shell_sites) },
            .{ .kind = .e0_fraction, .label = "e0_population_fraction", .value = signature.e0_fraction },
            .{ .kind = .defect_fraction, .label = "7_defect_over_volume", .value = defect_fraction },
        };
        for (values, 0..) |value, offset| {
            const out_index = index * 6 + offset;
            out[out_index] = .{
                .scale_index = scale_index,
                .kind = value.kind,
                .label = value.label,
                .value = value.value,
            };
        }
    }
    return out;
}

pub const Match = struct {
    candidate_index: usize,
    row_index: usize,
    constant_name: []const u8,
    category: []const u8,
    unit: []const u8,
    candidate_label: []const u8,
    candidate_kind: CandidateKind,
    candidate_scale: u3,
    predicted: Q128,
    target: Q128,
    abs_residual: Q128,
    relative_residual: Q128,
    candidate_is_exact: bool,
};

pub const AuditReport = struct {
    candidate_count: usize = CANDIDATE_COUNT,
    row_count: usize = TRIAD_ROW_COUNT,
    comparisons: usize = 0,
    representable_targets: usize = 0,
    skipped_target_underflows: usize = 0,
    arithmetic_errors: usize = 0,
    exact_matches: usize = 0,
    within_one_percent: usize = 0,
    within_tenth_percent: usize = 0,
    within_one_ppm: usize = 0,
    triad_rows_evaluable: usize = 0,
    triad_rows_underflowed: usize = 0,
    triad_arithmetic_errors: usize = 0,
    triad_nearest: [TRIAD_ROW_COUNT]TriadComparison = undefined,
    triad_value: Q128 = Q128.zero,
    triad_corrected_value: Q128 = Q128.zero,
    triad_correction: Q128 = Q128.zero,
    nearest: [CANDIDATE_COUNT]Match = undefined,
};

pub const TriadComparison = struct {
    row_index: usize,
    constant_name: []const u8,
    unit: []const u8,
    signature_value: Q128,
    lattice_candidate: Q128,
    lattice_candidate_scale: u3,
    lattice_candidate_label: []const u8,
    absolute_residual: Q128,
    relative_residual: Q128,
};

/// Compare lattice-derived values with every representable constant target.
/// No triad signatures are fitted or used to construct candidate values.
pub fn audit() AuditReport {
    const all_candidates = candidates() catch return .{ .arithmetic_errors = 1 };
    var report: AuditReport = .{};
    const h21_probe = hydrogen.H21Probe.run() catch return .{ .arithmetic_errors = 1 };
    report.triad_value = Q128.fromRatio(h21_probe.phi_triad_raw, hydrogen.Q_SCALE) catch return .{ .arithmetic_errors = 1 };
    report.triad_correction = Q128.fromRatio(hydrogen.LATTICE_CORRECTION_NUMERATOR, hydrogen.LATTICE_CORRECTION_DENOMINATOR) catch return .{ .arithmetic_errors = 1 };
    report.triad_corrected_value = report.triad_value.add(report.triad_correction);
    for (table_mod.table, 0..) |entry, row_index| {
        const signature = mound.evaluate(@intCast(entry.a), @intCast(entry.b), @intCast(entry.c)) catch {
            report.triad_arithmetic_errors += 1;
            continue;
        };
        if (signature.underflowed) report.triad_rows_underflowed += 1 else report.triad_rows_evaluable += 1;
        const signed_signature = if (entry.sign < 0) signature.magnitude.neg() else signature.magnitude;
        var nearest_scale: u3 = 0;
        var nearest_candidate = Q128.zero;
        var nearest_label: []const u8 = "";
        var nearest_abs = Q128.zero;
        var nearest_rel = Q128.one;
        var found_nearest = false;
        for (all_candidates) |candidate| {
            const abs_residual = candidate.value.sub(signed_signature).abs();
            const relative = abs_residual.div(signed_signature.abs()) catch continue;
            if (!found_nearest or relative.cmp(nearest_rel) < 0) {
                found_nearest = true;
                nearest_scale = candidate.scale_index;
                nearest_candidate = candidate.value;
                nearest_label = candidate.label;
                nearest_abs = abs_residual;
                nearest_rel = relative;
            }
        }
        report.triad_nearest[row_index] = .{
            .row_index = row_index,
            .constant_name = entry.name,
            .unit = entry.unit,
            .signature_value = signed_signature,
            .lattice_candidate = nearest_candidate,
            .lattice_candidate_scale = nearest_scale,
            .lattice_candidate_label = nearest_label,
            .absolute_residual = nearest_abs,
            .relative_residual = nearest_rel,
        };
    }
    for (all_candidates, 0..) |candidate, candidate_index| {
        var nearest: ?Match = null;
        for (table_mod.table, 0..) |entry, row_index| {
            const target = mound.targetValue(entry) catch {
                report.arithmetic_errors += 1;
                continue;
            };
            if (target.raw == 0) {
                report.skipped_target_underflows += 1;
                continue;
            }
            report.representable_targets += 1;
            const signed_target = if (entry.sign < 0) target.neg() else target;
            const abs_residual = candidate.value.sub(signed_target).abs();
            const relative = abs_residual.div(signed_target.abs()) catch {
                report.arithmetic_errors += 1;
                continue;
            };
            const match = Match{
                .candidate_index = candidate_index,
                .row_index = row_index,
                .constant_name = entry.name,
                .category = entry.category,
                .unit = entry.unit,
                .candidate_label = candidate.label,
                .candidate_kind = candidate.kind,
                .candidate_scale = candidate.scale_index,
                .predicted = candidate.value,
                .target = signed_target,
                .abs_residual = abs_residual,
                .relative_residual = relative,
                .candidate_is_exact = candidate.value.raw == signed_target.raw,
            };
            report.comparisons += 1;
            if (match.candidate_is_exact) report.exact_matches += 1;
            if (relative.cmp(Q128.fromRatio(1, 100) catch unreachable) <= 0) report.within_one_percent += 1;
            if (relative.cmp(Q128.fromRatio(1, 1_000) catch unreachable) <= 0) report.within_tenth_percent += 1;
            if (relative.cmp(Q128.fromRatio(1, 1_000_000) catch unreachable) <= 0) report.within_one_ppm += 1;
            if (nearest == null or relative.cmp(nearest.?.relative_residual) < 0) {
                nearest = match;
            }
        }
        report.nearest[candidate_index] = nearest orelse Match{
            .candidate_index = candidate_index,
            .row_index = 0,
            .constant_name = "",
            .category = "",
            .unit = "",
            .candidate_label = candidate.label,
            .candidate_kind = candidate.kind,
            .candidate_scale = candidate.scale_index,
            .predicted = Q128.zero,
            .target = Q128.zero,
            .abs_residual = Q128.zero,
            .relative_residual = Q128.one,
            .candidate_is_exact = false,
        };
    }
    return report;
}

test "scale 0 to scale 2 skips 16^3 as a standalone tier" {
    const signatures = try allScaleSignatures();
    try std.testing.expectEqual(@as(u16, 15), signatures[0].interior_side);
    try std.testing.expectEqual(@as(u16, 16), signatures[0].shell_side);
    try std.testing.expectEqual(@as(u64, 721), signatures[0].shell_sites);
    try std.testing.expectEqual(@as(u64, 3_375), signatures[0].interior_sites);
    try std.testing.expectEqual(@as(u64, 421), signatures[0].e0_sites);
    try std.testing.expectEqual(@as(u64, 7), signatures[0].defect_count);
    try std.testing.expectEqual(@as(u64, 421), signatures[0].e0_fraction_reduced_num);
    try std.testing.expectEqual(@as(u64, 3_375), signatures[0].e0_fraction_reduced_den);
    try std.testing.expectError(error.ScaleOverflow, scaleSignature(1));
    try std.testing.expectEqual(@as(u16, 32), signatures[1].interior_side);
    try std.testing.expectEqual(@as(u3, 2), signatures[1].scale_index);
    try std.testing.expectEqual(@as(u16, 64), signatures[1].shell_side);
    for (signatures, 0..) |signature, index| {
        try std.testing.expectEqual(@as(u3, @intCast(if (index == 0) 0 else index + 1)), signature.scale_index);
        try std.testing.expectEqual(signature.interior_sites, sumCounts(signature.label_counts));
        if (index > 1) try std.testing.expectEqual(@as(u16, signatures[index - 1].interior_side * 2), signature.interior_side);
    }
    try std.testing.expectEqual(@as(u16, 1_024), signatures[6].interior_side);
    try std.testing.expectEqual(@as(u64, 0), signatures[6].defect_count);
}

test "scale signatures expose exact scale zero and uniform higher-scale metadata" {
    const signatures = try allScaleSignatures();
    const expected_sides = [_]u16{ 15, 32, 64, 128, 256, 512, 1_024 };
    const expected_shells = [_]u64{
        721,
        64 * 64 * 64 - 32 * 32 * 32,
        128 * 128 * 128 - 64 * 64 * 64,
        256 * 256 * 256 - 128 * 128 * 128,
        512 * 512 * 512 - 256 * 256 * 256,
        1_024 * 1_024 * 1_024 - 512 * 512 * 512,
        2_048 * 2_048 * 2_048 - 1_024 * 1_024 * 1_024,
    };
    for (signatures, 0..) |signature, index| {
        const side = expected_sides[index];
        const volume = cube(side);
        try std.testing.expectEqual(side, signature.interior_side);
        try std.testing.expectEqual(volume, signature.interior_sites);
        try std.testing.expectEqual(expected_shells[index], signature.shell_sites);
        try std.testing.expect(signature.shell_only_when_compounding);
        if (index == 0) {
            try std.testing.expectEqual(@as(u64, 42), signature.cardinal_ray_sites);
            try std.testing.expect(signature.coloring_has_unique_defect);
            try std.testing.expectEqual(@as(i64, -7), signature.label_imbalance[0]);
            for (signature.label_counts[1..]) |count| try std.testing.expectEqual(@as(u64, 422), count);
        } else {
            try std.testing.expectEqual(@as(u64, 0), signature.defect_count);
            try std.testing.expect(!signature.coloring_has_unique_defect);
            for (signature.label_counts) |count| try std.testing.expectEqual(volume / 8, count);
            for (signature.label_imbalance) |imbalance| try std.testing.expectEqual(@as(i64, 0), imbalance);
        }
    }
}

test "candidate values are exact and retain skipped scale indices" {
    const all_candidates = try candidates();
    try std.testing.expectEqual(CANDIDATE_COUNT, all_candidates.len);
    const expected_sides = [_]u3{ 0, 2, 3, 4, 5, 6, 7 };
    for (expected_sides, 0..) |scale, index| {
        const first_candidate = all_candidates[index * 6];
        try std.testing.expectEqual(scale, first_candidate.scale_index);
        try std.testing.expectEqual(CandidateKind.lattice_volume, first_candidate.kind);
    }
    try std.testing.expectEqual(Q128.fromInteger(3_375).raw, all_candidates[0].value.raw);
    try std.testing.expectEqual(Q128.fromInteger(421).raw, all_candidates[1].value.raw);
    try std.testing.expectEqual(Q128.fromInteger(7).raw, all_candidates[2].value.raw);
    try std.testing.expectEqual(Q128.fromInteger(721).raw, all_candidates[3].value.raw);
    try std.testing.expectEqual((try Q128.fromRatio(421, 3_375)).raw, all_candidates[4].value.raw);
    try std.testing.expectEqual((try Q128.fromRatio(7, 3_375)).raw, all_candidates[5].value.raw);
    try std.testing.expectEqual(Q128.zero.raw, all_candidates[8].value.raw);
    try std.testing.expectEqual((try Q128.fromRatio(1, 8)).raw, all_candidates[10].value.raw);
    try std.testing.expectEqual(Q128.fromInteger(32_768).raw, all_candidates[13].value.raw);
    try std.testing.expectEqual(Q128.zero.raw, all_candidates[14].value.raw);
    try std.testing.expectEqual(Q128.fromInteger(1_835_008).raw, all_candidates[15].value.raw);
    try std.testing.expectEqual(Q128.zero.raw, all_candidates[17].value.raw);
}

fn sumCounts(counts: [8]u64) u64 {
    var sum: u64 = 0;
    for (counts) |count| sum += count;
    return sum;
}

test "lattice and triad comparisons retain exact results and evidence classes" {
    const report = audit();
    try std.testing.expectEqual(@as(usize, 42), report.candidate_count);
    try std.testing.expectEqual(@as(usize, 145), report.row_count);
    try std.testing.expectEqual(@as(usize, 5_997), report.comparisons);
    try std.testing.expectEqual(@as(usize, 42), report.skipped_target_underflows);
    try std.testing.expectEqual(@as(usize, 51), report.arithmetic_errors);
    try std.testing.expect(report.exact_matches == 0);
    try std.testing.expectEqual(@as(usize, 0), report.within_one_percent);
    try std.testing.expectEqual(@as(usize, 0), report.within_tenth_percent);
    try std.testing.expectEqual(@as(usize, 0), report.within_one_ppm);
    try std.testing.expectEqual(@as(usize, 143), report.triad_rows_evaluable);
    try std.testing.expectEqual(@as(usize, 2), report.triad_rows_underflowed);
    try std.testing.expectEqual(@as(usize, 0), report.triad_arithmetic_errors);
    try std.testing.expect(report.triad_nearest[123].constant_name.len > 0);
    try std.testing.expect(report.triad_value.raw > Q128.fromInteger(21).raw);
}
