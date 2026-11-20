//! Sonoluminescence bubble-qubit model — integer-only port of the MOUND
//! module at axiom7revisited/src/physics/sonoluminescence.zig.
//!
//! The model identifies the 15^3 interior with a qubit state space and
//! the 16^3 shell with a cavitation bubble wall: 721 boundary cells act
//! as the decoherence interface, 7 channels map to octonion imaginaries
//! e1..e7, and photon timing rides the hydrogen hyperfine line.
//!
//! Port deltas vs the source:
//!   * all arithmetic integer-only (i64/i128 intermediates, SCALE=1e9)
//!   * the correlation matrix's f64 cos() is replaced by an integer
//!     Taylor evaluation `cosScaled` — verified against the source's
//!     expected matrix within 1% and against lattice measurements here.
//!
//! Classification: FORMAL_MODEL / CONSTRUCTION. Literature constants
//! (Cheng & Hyde 2026 compression ~9.04:1 and ~0.1 ns pulse width,
//! NIST argon ionization energies, hydrogen 21 cm line) are data wired
//! to lattice labels; nothing here measures a physical cavity.
const std = @import("std");
const tiers = @import("redox_scaling_tiers.zig");

pub const SCALE: i64 = 1_000_000_000;
pub const PHI: i64 = 1_618_033_989; // golden ratio, scaled
pub const PI: i64 = 3_141_592_654; // pi, scaled
pub const TWO_PI: i64 = 6_283_185_307;
pub const H_EV_S: i64 = 4_135_670; // h = 4.13567e-15 eV s, rescaled
pub const F_H_HZ: i64 = 1_420_405_752; // hydrogen line, Hz (raw)
pub const F_H_MHZ: i64 = 1_420_405_752_000; // 1420.405752 MHz, scaled
pub const T_H_NS: i64 = 704_000_000; // 0.704 ns, scaled
pub const OBSERVER_DENSITY: i64 = 124_740_741; // 421/3375, scaled

// ---------------------------------------------------------------------------
// Bubble-shell geometry — shared with the measured basisAt lattice
// ---------------------------------------------------------------------------

pub const BubbleShell = struct {
    interior_size: u8 = 15,
    shell_size: u8 = 16,
    n_channels: u8 = 7,

    pub fn interiorCells(self: *const BubbleShell) u32 {
        const n: u32 = self.interior_size;
        return n * n * n;
    }

    pub fn shellCells(self: *const BubbleShell) u32 {
        const n: u32 = self.shell_size;
        return n * n * n;
    }

    pub fn boundaryCells(self: *const BubbleShell) u32 {
        return self.shellCells() - self.interiorCells();
    }

    pub fn observerNodes() u32 {
        return 421;
    }

    /// 421/3375 in scaled fixed point.
    pub fn observerDensity() i64 {
        return @divTrunc(@as(i128, 421) * SCALE, 3375);
    }

    /// Cheng & Hyde (2026): R0 = 4.5 um -> Rmin = 0.498 um ~ 9.04:1.
    /// Source convention rounds the final radius to 0.5 um.
    pub fn compressionRatio() i64 {
        const initial: i128 = @divTrunc(45 * @as(i128, SCALE), 10);
        const final: i128 = @divTrunc(@as(i128, SCALE), 2);
        return @intCast(@divTrunc(initial * @as(i128, SCALE), final));
    }

    /// Per-qubit emission energy e = h * f_H * phi^shell, scaled eV.
    pub fn energyPerQubit(e_shell: u32) i64 {
        const e_base: i128 = @divTrunc(@as(i128, H_EV_S) * F_H_HZ, SCALE);
        var phi_pow: i128 = SCALE;
        var k: u32 = 0;
        while (k < e_shell) : (k += 1) {
            phi_pow = @divTrunc(phi_pow * @as(i128, PHI), SCALE);
        }
        return @intCast(@divTrunc(e_base * phi_pow, SCALE));
    }

    /// Decoherence through 7 channels: 7 * T_H.
    pub fn collapseTime(self: *const BubbleShell) i64 {
        return @as(i64, self.n_channels) * T_H_NS;
    }

    pub fn isStable(self: *const BubbleShell) bool {
        return self.interior_size > 0 and self.shell_size > self.interior_size;
    }
};

// ---------------------------------------------------------------------------
// Integer cosine: cos(x) with x scaled by 1e9, via Taylor series in
// i128 intermediates. Replaces the source module's f64 cos.
// ---------------------------------------------------------------------------

pub fn cosScaled(x_s: i64) i64 {
    // cos(x) = sum_k (-1)^k x^{2k}/(2k)! ; terms decay to zero in
    // scaled integer arithmetic for |x| <= ~2*pi.
    var term: i128 = SCALE;
    var sum: i128 = SCALE;
    var k: i64 = 1;
    while (k <= 40) : (k += 1) {
        // term_k = -term_{k-1} * x^2 / ((2k-1)(2k)). The divisions are
        // split between the two x_s multiplies so i128 intermediates
        // stay bounded for |x| up to ~3*pi.
        const half = @divTrunc(-term * @as(i128, x_s), @as(i128, 2 * k - 1) * SCALE);
        term = @divTrunc(half * @as(i128, x_s), @as(i128, 2 * k) * SCALE);
        if (term == 0) break;
        sum += term;
    }
    return @intCast(sum);
}

/// C(i,j) = cos(2*pi*|i-j|*phi / 7), all-integer evaluation.
pub fn correlationMatrix(out: *[7][7]i64) void {
    for (0..7) |i| {
        for (0..7) |j| {
            const d: i128 = @intCast(@abs(@as(i64, @intCast(i)) - @as(i64, @intCast(j))));
            const arg: i64 = @intCast(@divTrunc(@as(i128, TWO_PI) * d * PHI, 7 * @as(i128, SCALE)));
            out[i][j] = cosScaled(arg);
        }
    }
}

/// The source module's reference table (i64 x 1e9), kept as the
/// regression oracle for the integer cos.
pub const EXPECTED_MATRIX = [7][7]i64{
    .{ 1_000_000_000, 118_000_000, -972_000_000, -348_000_000, 890_000_000, 558_000_000, -758_000_000 },
    .{ 118_000_000, 1_000_000_000, 118_000_000, -972_000_000, -348_000_000, 890_000_000, 558_000_000 },
    .{ -972_000_000, 118_000_000, 1_000_000_000, 118_000_000, -972_000_000, -348_000_000, 890_000_000 },
    .{ -348_000_000, -972_000_000, 118_000_000, 1_000_000_000, 118_000_000, -972_000_000, -348_000_000 },
    .{ 890_000_000, -348_000_000, -972_000_000, 118_000_000, 1_000_000_000, 118_000_000, -972_000_000 },
    .{ 558_000_000, 890_000_000, -348_000_000, -972_000_000, 118_000_000, 1_000_000_000, 118_000_000 },
    .{ -758_000_000, 558_000_000, 890_000_000, -348_000_000, -972_000_000, 118_000_000, 1_000_000_000 },
};

// ---------------------------------------------------------------------------
// Channel structure
// ---------------------------------------------------------------------------

pub fn channelToOctonionMapping() [7]u8 {
    return .{ 1, 2, 3, 4, 5, 6, 7 }; // channels -> e1..e7
}

pub const CliffordSplit = struct {
    bivector: [3]u8,
    extension: [4]u8,
};

pub fn cliffordBivectorSplit() CliffordSplit {
    return .{ .bivector = .{ 1, 2, 3 }, .extension = .{ 4, 5, 6, 7 } };
}

/// Cheng & Hyde (2026) Table 2 + NIST: argon's seven successive
/// ionization energies in MJ/mol, scaled.
pub const ARGON_IONIZATION_MJ_MOL = [7]i64{
    1_520_000_000, 2_670_000_000, 3_930_000_000,  5_770_000_000,
    7_240_000_000, 8_780_000_000, 12_000_000_000,
};

/// Observable flash requires >100 photons (empirical threshold).
pub fn isCollapseEvent(photon_count: u32) bool {
    return photon_count > 100;
}

/// Thermal accommodation coefficient, isothermal default (alpha = 1.0).
pub fn boundaryAccommodation() i64 {
    return SCALE;
}

/// Emission pulse FWHM = T_H / 7 ~ 0.1006 ns, scaled.
pub fn emissionPulseWidth() i64 {
    return @divTrunc(T_H_NS, 7);
}

// ---------------------------------------------------------------------------
// Tests — port parity + cross-validation against the measured lattice
// ---------------------------------------------------------------------------

test "bubble geometry matches the measured lattice exactly" {
    const b = BubbleShell{};
    try std.testing.expectEqual(@as(u32, 3375), b.interiorCells());
    try std.testing.expectEqual(@as(u32, 4096), b.shellCells());
    try std.testing.expectEqual(@as(u32, 721), b.boundaryCells());
    // Cross-check against the canonical coloring, not just arithmetic.
    try std.testing.expectEqual(@as(?u3, 0), tiers.defectState(15));
    const h = tiers.histogram(15);
    try std.testing.expectEqual(@as(u64, 421), h[0]);
    try std.testing.expectEqual(@as(u32, 421), BubbleShell.observerNodes());
    // The shell factorization: 721 = 7 * 103 — the boundary is the
    // defect count times a prime.
    try std.testing.expectEqual(@as(u32, 7 * 103), b.boundaryCells());
}

test "observer density = 421/3375 within rounding" {
    const d = BubbleShell.observerDensity();
    try std.testing.expect(@abs(d - OBSERVER_DENSITY) <= 1);
}

test "compression ratio is 9:1 within the literature band" {
    const r = BubbleShell.compressionRatio();
    try std.testing.expect(r > 8 * SCALE and r < 10 * SCALE);
}

test "integer cosine matches the source correlation matrix" {
    var m: [7][7]i64 = undefined;
    correlationMatrix(&m);
    for (0..7) |i| {
        for (0..7) |j| {
            const diff = @abs(m[i][j] - EXPECTED_MATRIX[i][j]);
            // 1% tolerance — the source table is rounded to 3 decimals.
            try std.testing.expect(diff < 10_000_000);
        }
    }
    // Symmetric with unit diagonal.
    for (0..7) |i| {
        try std.testing.expectEqual(SCALE, m[i][i]);
        for (i + 1..7) |j| {
            try std.testing.expectEqual(m[i][j], m[j][i]);
        }
    }
}

test "integer cosine standalone: cos(0)=1, cos(pi)=-1" {
    try std.testing.expectEqual(SCALE, cosScaled(0));
    const cpi = cosScaled(PI);
    try std.testing.expect(@abs(cpi + SCALE) < 1_000);
    const cpi2 = cosScaled(@divTrunc(PI, 2));
    try std.testing.expect(@abs(cpi2) < 1_000);
}

test "channel structure: 7 channels map to e1..e7 with a 3+4 split" {
    const m = channelToOctonionMapping();
    for (m, 1..) |ch, idx| {
        try std.testing.expectEqual(@as(u8, @intCast(idx)), ch);
    }
    const split = cliffordBivectorSplit();
    try std.testing.expectEqual(@as(u8, 3), split.bivector.len);
    try std.testing.expectEqual(@as(u8, 4), split.extension.len);
}

test "photon timing: collapse = 7*T_H, pulse = T_H/7" {
    const b = BubbleShell{};
    try std.testing.expectEqual(@as(i64, 7) * T_H_NS, b.collapseTime());
    // T_H/7 ~ 0.1006 ns vs the paper's ~0.1 ns FWHM.
    try std.testing.expect(@abs(emissionPulseWidth() - 100_571_428) <= 1);
}

test "energy per qubit follows phi^shell scaling" {
    const e0 = BubbleShell.energyPerQubit(0);
    const e1 = BubbleShell.energyPerQubit(1);
    const e2 = BubbleShell.energyPerQubit(2);
    try std.testing.expect(e0 > 0);
    // e1/e0 = phi within integer truncation; e2/e0 = phi^2.
    try std.testing.expect(@abs(@divTrunc(e1 * SCALE, e0) - PHI) < 2_000_000);
    const phi2 = @divTrunc(@as(i128, PHI) * PHI, SCALE);
    try std.testing.expect(@abs(@divTrunc(@as(i128, e2) * SCALE, e0) - phi2) < 3_000_000);
}

test "collapse threshold and argon stages" {
    try std.testing.expect(!isCollapseEvent(100));
    try std.testing.expect(isCollapseEvent(101));
    for (1..7) |i| {
        try std.testing.expect(ARGON_IONIZATION_MJ_MOL[i] > ARGON_IONIZATION_MJ_MOL[i - 1]);
    }
    try std.testing.expectEqual(@as(i64, 1_520_000_000), ARGON_IONIZATION_MJ_MOL[0]);
    try std.testing.expectEqual(SCALE, boundaryAccommodation());
}
