//! Evidence-tiered claim registry for RedOx.
const std = @import("std");

pub const Category = enum { exact_math, formal_model, construction, empirical_hardware_result, unverified_physical_hypothesis, rejected_or_inconsistent };
pub const Claim = struct { id: []const u8, statement: []const u8, category: Category, falsifier: []const u8 };

pub const CLAIMS = [_]Claim{
    .{ .id = "lattice_shell_counts", .statement = "15^3 + (16^3-15^3) = 16^3", .category = .exact_math, .falsifier = "integer count mismatch" },
    .{ .id = "lattice_mirror", .statement = "layer shift mirrors around layer 8", .category = .exact_math, .falsifier = "paired layer mismatch" },
    .{ .id = "qcomms_digest_repeatability", .statement = "fixed input produces fixed digest", .category = .empirical_hardware_result, .falsifier = "replicated digest mismatch" },
    .{ .id = "e_checksum", .statement = "E forward/inverse product is an algebraic checksum", .category = .formal_model, .falsifier = "symbolic identity failure" },
    .{ .id = "physical_entanglement", .statement = "classical hosts exhibit physical entanglement", .category = .unverified_physical_hypothesis, .falsifier = "no physical quantum substrate or failed Bell test" },
    .{ .id = "quantum_equivalence", .statement = "RedOx classical execution is quantum-equivalent", .category = .unverified_physical_hypothesis, .falsifier = "classical control explains result" },
    .{ .id = "checksum_physics", .statement = "the checksum is a derived physical law", .category = .rejected_or_inconsistent, .falsifier = "dimensional analysis identifies formal identity only" },
};

test "claim registry keeps physical hypotheses distinct from exact math" {
    try std.testing.expect(CLAIMS.len >= 7);
    try std.testing.expectEqual(Category.exact_math, CLAIMS[0].category);
    try std.testing.expectEqual(Category.unverified_physical_hypothesis, CLAIMS[4].category);
}
