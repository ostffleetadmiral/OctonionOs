//! mound_triad.zig — MOUND triad operator T(a,b,c) = φ^a + π^b + φ^c
//! evaluated over the 145-row constant table in Q128 fixed-point.
//!
//! Evidence tier: ARITHMETIC VERIFICATION of the donor's claimed coverage.
//! The table encodes 145 physical constants with fitted (a,b,c) signatures;
//! this module independently recomputes every triad in integer fixed-point
//! and reports the residual distribution. A good fit is NOT evidence that
//! the physical model is correct — it verifies that the table's arithmetic
//! claims reproduce under this engine's semantics.
//!
//! Sign convention: `sign` is physical metadata applied to the positive
//! triad magnitude. The raw operator is always a positive sum; signed
//! comparison against signed targets happens in verifyAll.
//!
//! Underflow: |exponent| can reach 214, far beyond Q128's ~2^127 value
//! range. Negative exponents are evaluated as reciprocal-base powers
//! (matching the donor's q128Pow semantics) so tiny true values flush to
//! zero and are reported via `underflowed` rather than treated as
//! arithmetic failures.

const std = @import("std");
const fp = @import("fixed_point.zig");
const Q128 = fp.Q128;
const table_mod = @import("mound_triad_table.zig");
const Entry = table_mod.Entry;

/// φ = (1+√5)/2 in Q128.128 raw form (same literal as donor constants.zig).
pub const PHI = Q128.fromRaw(550588435450341336629110977315780544564);
/// π in Q128.128 raw form.
pub const PI = Q128.fromRaw(1069028584064966747859680373161870783300);

pub const TABLE_LEN = table_mod.TABLE_LEN;
pub const table = table_mod.table;

pub const Error = fp.Error || error{ ExponentRange, TargetOverflow };

pub const TermResult = struct {
    value: Q128,
    /// True when the true mathematical value is nonzero but fell below
    /// the Q128 precision floor and flushed to zero.
    underflowed: bool,
};

pub const TriadResult = struct {
    /// Positive magnitude φ^a + π^b + φ^c.
    magnitude: Q128,
    /// True if any of the three terms underflowed.
    underflowed: bool,
    pa: TermResult,
    pb: TermResult,
    pc: TermResult,
};

pub const SignedResult = struct {
    /// sign × magnitude — the physical prediction.
    value: Q128,
    underflowed: bool,
};

/// Largest safe positive exponent per base before Q128 overflow.
/// φ^180 ≈ 5.6e37 and π^74 ≈ 6e36, both below 2^127 ≈ 1.7e38.
/// Q128.mul truncates silently on overflow, so pow is range-gated here.
const PHI_MAX_POS: i32 = 180;
const PI_MAX_POS: i32 = 74;

fn pow10I256(e: u32) i256 {
    var r: i256 = 1;
    var i: u32 = 0;
    while (i < e) : (i += 1) r *= 10;
    return r;
}

fn ratio(num: i256, den: i256) Q128 {
    return Q128.fromRatio(num, den) catch unreachable;
}

/// base^exp with underflow-safe negative exponents.
/// Negative exponents invert the base first (donor q128Pow semantics) so
/// intermediates never exceed 1 and true values below 2^-129 flush to 0.
fn powTerm(base: Q128, exp: i32, max_pos: i32) Error!TermResult {
    if (exp == 0) return .{ .value = Q128.one, .underflowed = false };
    if (exp == std.math.minInt(i32) or exp > max_pos) return error.ExponentRange;
    if (exp < 0) {
        const inv = try Q128.one.div(base);
        var result = Q128.one;
        var b = inv;
        var k: u32 = @intCast(-exp);
        while (k > 0) : (k >>= 1) {
            if ((k & 1) == 1) result = result.mul(b);
            if (k > 1) b = b.mul(b);
        }
        return .{
            .value = result,
            .underflowed = result.raw == 0,
        };
    }
    return .{ .value = try base.pow(exp), .underflowed = false };
}

/// Evaluate the triad magnitude for signature (a,b,c).
pub fn evaluate(a: i32, b: i32, c: i32) Error!TriadResult {
    const pa = try powTerm(PHI, a, PHI_MAX_POS);
    const pb = try powTerm(PI, b, PI_MAX_POS);
    const pc = try powTerm(PHI, c, PHI_MAX_POS);
    const sum = pa.value.add(pb.value).add(pc.value);
    return .{
        .magnitude = sum,
        .underflowed = pa.underflowed or pb.underflowed or pc.underflowed,
        .pa = pa,
        .pb = pb,
        .pc = pc,
    };
}

/// Signed prediction for a table entry: sign × magnitude.
pub fn signedValue(e: Entry) Error!SignedResult {
    const t = try evaluate(@intCast(e.a), @intCast(e.b), @intCast(e.c));
    const value = if (e.sign < 0) t.magnitude.neg() else t.magnitude;
    return .{ .value = value, .underflowed = t.underflowed };
}

/// Convert a table target (target_num × 10^target_exp10) to Q128.
/// Uses exact integer scaling: num×10^exp for exp>=0, num/10^-exp for
/// exp<0 — both rounded once via fromInteger/fromRatio.
pub fn targetValue(e: Entry) Error!Q128 {
    const num: i256 = e.target_num;
    const exp = e.target_exp10;
    if (exp >= 0) {
        const scaled = num * pow10I256(@intCast(exp));
        // Guard: fromInteger multiplies by 2^128; keep |value| < 2^127.
        const limit = std.math.maxInt(i256) / fp.Scale;
        if (scaled > limit or scaled < -limit) return error.TargetOverflow;
        return Q128.fromInteger(scaled);
    }
    return Q128.fromRatio(num, pow10I256(@intCast(-exp)));
}

pub const RowReport = struct {
    index: usize,
    name: []const u8,
    category: []const u8,
    /// Signed prediction.
    predicted: Q128,
    /// Signed target.
    target: Q128,
    /// |predicted - target|.
    abs_err: Q128,
    /// abs_err / |target| as a fraction (e.g. 0.01 = 1%).
    rel_err: Q128,
    underflowed: bool,
};

pub const Report = struct {
    rows: [TABLE_LEN]RowReport = undefined,
    /// Rows with a representable nonzero target that were evaluated.
    total: usize = 0,
    /// Rows whose |target| fell below the Q128 precision floor (~2.9e-39)
    /// and flushed to zero — e.g. Planck time 5.39e-44 s. Not failures.
    target_underflow_rows: usize = 0,
    target_underflow_index: usize = 0,
    arithmetic_failures: usize = 0,
    underflow_rows: usize = 0,
    /// Cumulative thresholds on rel_err (fraction): <0.1%, <1%, <2%, <5%.
    within_0p1pct: usize = 0,
    within_1pct: usize = 0,
    within_2pct: usize = 0,
    within_5pct: usize = 0,
    max_rel_err: Q128 = Q128.zero,
    max_rel_err_index: usize = 0,
};

/// Recompute all 145 rows and collect residual statistics.
/// Arithmetic failures (zero target, range errors) are counted, not fatal.
pub fn verifyAll() Report {
    const t_0p1 = ratio(1, 1000);
    const t_1 = ratio(1, 100);
    const t_2 = ratio(1, 50);
    const t_5 = ratio(1, 20);
    var report: Report = .{};
    for (table, 0..) |e, i| {
        const idx = i;
        const target = targetValue(e) catch {
            report.arithmetic_failures += 1;
            continue;
        };
        if (target.raw == 0) {
            report.target_underflow_rows += 1;
            if (report.target_underflow_rows == 1) report.target_underflow_index = idx;
            continue;
        }
        const t = signedValue(e) catch {
            report.arithmetic_failures += 1;
            continue;
        };
        const abs_err = t.value.sub(target).abs();
        const rel_err = abs_err.div(target.abs()) catch Q128.one;
        const row: RowReport = .{
            .index = idx,
            .name = e.name,
            .category = e.category,
            .predicted = t.value,
            .target = target,
            .abs_err = abs_err,
            .rel_err = rel_err,
            .underflowed = t.underflowed,
        };
        report.rows[report.total] = row;
        report.total += 1;
        if (t.underflowed) report.underflow_rows += 1;
        if (rel_err.raw < t_0p1.raw) report.within_0p1pct += 1;
        if (rel_err.raw < t_1.raw) report.within_1pct += 1;
        if (rel_err.raw < t_2.raw) report.within_2pct += 1;
        if (rel_err.raw < t_5.raw) report.within_5pct += 1;
        if (Q128.cmp(rel_err, report.max_rel_err) > 0) {
            report.max_rel_err = rel_err;
            report.max_rel_err_index = idx;
        }
    }
    return report;
}

// ---------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------

test "table covers exactly 145 constants" {
    try std.testing.expectEqual(@as(usize, 145), table.len);
    try std.testing.expectEqual(@as(usize, 145), TABLE_LEN);
}

test "triad (0,0,0) equals 3" {
    const t = try evaluate(0, 0, 0);
    try std.testing.expectEqual(Q128.fromInteger(3).raw, t.magnitude.raw);
}

test "triad symmetric in a and c" {
    const t1 = try evaluate(5, 2, -4);
    const t2 = try evaluate(-4, 2, 5);
    try std.testing.expectEqual(t1.magnitude.raw, t2.magnitude.raw);
}

test "hydrogen 21cm signature (5,2,-4) lands near 21.1" {
    const t = try evaluate(5, 2, -4);
    // φ^5 + π^2 + φ^-4 ≈ 11.09 + 9.87 + 0.146 ≈ 21.106
    const lo = Q128.fromInteger(21);
    const hi = Q128.fromInteger(22);
    try std.testing.expect(Q128.cmp(t.magnitude, lo) > 0);
    try std.testing.expect(Q128.cmp(t.magnitude, hi) < 0);
    try std.testing.expect(!t.underflowed);
}

test "negative exponents underflow safely to zero" {
    const t = try powTerm(PHI, -214, PHI_MAX_POS);
    try std.testing.expectEqual(@as(i256, 0), t.value.raw);
    try std.testing.expect(t.underflowed);
    const p = try powTerm(PI, -100, PI_MAX_POS);
    try std.testing.expectEqual(@as(i256, 0), p.value.raw);
    try std.testing.expect(p.underflowed);
}

test "positive powers stay in range" {
    const t = try evaluate(161, 66, 163);
    try std.testing.expect(t.magnitude.raw > 0);
}

test "target conversion round-trips hydrogen 21cm" {
    var found = false;
    for (table) |e| {
        if (std.mem.indexOf(u8, e.name, "21cm") != null) {
            const tv = try targetValue(e);
            const lo = Q128.fromInteger(21);
            const hi = Q128.fromInteger(22);
            try std.testing.expect(Q128.cmp(tv, lo) > 0);
            try std.testing.expect(Q128.cmp(tv, hi) < 0);
            found = true;
        }
    }
    try std.testing.expect(found);
}

test "verifyAll: 144 evaluable rows + 1 target underflow, no failures" {
    const report = verifyAll();
    try std.testing.expectEqual(@as(usize, 144), report.total);
    try std.testing.expectEqual(@as(usize, 1), report.target_underflow_rows);
    try std.testing.expectEqual(@as(usize, 0), report.arithmetic_failures);
    try std.testing.expect(report.within_5pct == report.total);
    // Donor claims ~131/145 within 1%; allow small fixed-point drift.
    try std.testing.expect(report.within_1pct >= 125);
}

test "verifyAll: worst residual stays under 5%" {
    const report = verifyAll();
    try std.testing.expect(report.max_rel_err_index < TABLE_LEN);
    try std.testing.expect(Q128.cmp(report.max_rel_err, ratio(1, 20)) < 0);
}

test "sign convention: negative-sign rows predict negative" {
    var neg_count: usize = 0;
    for (table) |e| {
        if (e.sign < 0) {
            const t = try signedValue(e);
            try std.testing.expect(t.value.raw < 0);
            neg_count += 1;
        }
    }
    try std.testing.expect(neg_count > 0);
}

test "every table signature is non-degenerate" {
    for (table) |e| {
        try std.testing.expect(e.a != 0 or e.b != 0 or e.c != 0);
        try std.testing.expect(e.target_num != 0);
    }
}
