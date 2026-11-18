const std = @import("std");
const lattice_mod = @import("lattice.zig");
const smith_table = @import("smith_table.zig");
const sha256 = std.crypto.hash.sha2.Sha256;

pub const Manifest = struct {
    node_count: usize,
    origin_count: usize,
    e0_count: usize,
    defect_count: u8,
    phase_cycle_steps: u8,
    smith_entry_count: usize,
    digest: [32]u8,
};

pub fn digestBytes(bytes: []const u8) [32]u8 {
    var digest: [32]u8 = undefined;
    sha256.hash(bytes, &digest, .{});
    return digest;
}

pub fn validate(lattice: *const lattice_mod.Lattice, table: *const smith_table.Table) bool {
    if (lattice.labels.len != lattice_mod.NODE_COUNT) return false;
    if (lattice.countLabel(0) != 421) return false;
    if (!lattice.hasLayerMirrorSymmetry()) return false;
    if (table.entries.len != smith_table.ENTRY_COUNT) return false;
    const center = table.get(0, 0) orelse return false;
    if (center.gamma_re != 0 or center.gamma_im != 0) return false;
    if (center.impedance_re != smith_table.SCALE or center.impedance_im != 0) return false;
    if (center.state != .finite) return false;
    if ((table.get(7, 0) orelse return false).state != .open) return false;
    if ((table.get(-7, 0) orelse return false).state != .short) return false;
    if (table.get(8, 0) != null) return false;

    var origin_count: usize = 0;
    var seen = [_]bool{false} ** lattice_mod.NODE_COUNT;
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const coord = lattice_mod.Lattice.coordFromIndex(flat) orelse return false;
        const position = lattice_mod.Lattice.index(coord) orelse return false;
        if (seen[position] or position != flat) return false;
        seen[position] = true;
        if (coord.x == 0 and coord.y == 0 and coord.z == 0) origin_count += 1;
    }
    for (seen) |present| if (!present) return false;
    return origin_count == 1;
}

pub fn manifest(lattice: *const lattice_mod.Lattice, table: *const smith_table.Table, digest: [32]u8) Manifest {
    var origin_count: usize = 0;
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const coord = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (coord.x == 0 and coord.y == 0 and coord.z == 0) origin_count += 1;
    }
    return .{
        .node_count = lattice.labels.len,
        .origin_count = origin_count,
        .e0_count = lattice.countLabel(0),
        .defect_count = lattice_mod.DEFECT_COUNT,
        .phase_cycle_steps = lattice_mod.PHASE_STEPS_PER_CYCLE,
        .smith_entry_count = table.entries.len,
        .digest = digest,
    };
}

pub fn writeJson(
    writer: anytype,
    lattice: *const lattice_mod.Lattice,
    table: *const smith_table.Table,
) !void {
    if (!validate(lattice, table)) return error.InvalidManifest;
    try writer.writeAll("{\"schema\":\"octonion-os-lattice-v1\",\"nodes\":[");
    for (0..lattice_mod.NODE_COUNT) |flat| {
        if (flat != 0) try writer.writeByte(',');
        const coord = lattice_mod.Lattice.coordFromIndex(flat).?;
        const label = lattice.labels[flat];
        const layer_index: usize = @intCast(@as(i16, coord.z) + 7);
        const phase = lattice_mod.Phase{ .eighth_turns = @intCast(@mod(@as(i16, coord.z) + 7, 8)) };
        try writer.print(
            "{{\"x\":{d},\"y\":{d},\"z\":{d},\"fano\":{d},\"layer\":{d},\"phase_eighth_turns\":{d},\"primary_e0\":{s}}}",
            .{ coord.x, coord.y, coord.z, label, layer_index + 1, phase.eighth_turns, if (coord.x == 0 and coord.y == 0 and coord.z == 0) "true" else "false" },
        );
    }
    try writer.writeAll("],\"smith\":[");
    for (0..smith_table.ENTRY_COUNT) |position| {
        if (position != 0) try writer.writeByte(',');
        const x: i8 = @intCast(@as(i16, @intCast(position % 15)) - 7);
        const y: i8 = @intCast(@as(i16, @intCast(position / 15)) - 7);
        const entry = table.entries[position];
        try writer.print(
            "{{\"x\":{d},\"y\":{d},\"gamma_re\":{d},\"gamma_im\":{d},\"z_re\":{d},\"z_im\":{d},\"state\":\"{s}\"}}",
            .{ x, y, entry.gamma_re, entry.gamma_im, entry.impedance_re, entry.impedance_im, @tagName(entry.state) },
        );
    }
    try writer.print(
        "],\"defect_count\":{d},\"defect_placement_defined\":false,\"phase_increment_eighth_turns\":1,\"phase_cycle_steps\":{d},\"digest_sha256\":\"{s}\"}}",
        .{ lattice_mod.DEFECT_COUNT, lattice_mod.PHASE_STEPS_PER_CYCLE, hexDigest(latticeDigest(lattice, table)) },
    );
}

fn latticeDigest(lattice: *const lattice_mod.Lattice, table: *const smith_table.Table) [32]u8 {
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    for (lattice.labels) |label| hash.update(&.{label});
    for (table.entries) |entry| {
        hash.update(std.mem.asBytes(&entry.gamma_re));
        hash.update(std.mem.asBytes(&entry.gamma_im));
        hash.update(std.mem.asBytes(&entry.impedance_re));
        hash.update(std.mem.asBytes(&entry.impedance_im));
        hash.update(&.{@intFromEnum(entry.state)});
    }
    var digest: [32]u8 = undefined;
    hash.final(&digest);
    return digest;
}

fn hexDigest(digest: [32]u8) [64]u8 {
    const hex = "0123456789abcdef";
    var output: [64]u8 = undefined;
    for (digest, 0..) |byte, i| {
        output[2 * i] = hex[byte >> 4];
        output[2 * i + 1] = hex[byte & 0x0f];
    }
    return output;
}

pub fn serializeAlloc(allocator: std.mem.Allocator, lattice: *const lattice_mod.Lattice, table: *const smith_table.Table) ![]u8 {
    var output = std.ArrayList(u8).init(allocator);
    errdefer output.deinit();
    try writeJson(output.writer(), lattice, table);
    return output.toOwnedSlice();
}

test "manifest validates lattice and Smith lookup" {
    const lattice = lattice_mod.Lattice.init();
    const lookup = exampleTable();
    try std.testing.expect(validate(&lattice, &lookup));
    const data = manifest(&lattice, &lookup, digestBytes("fixture"));
    try std.testing.expectEqual(@as(usize, 3375), data.node_count);
    try std.testing.expectEqual(@as(usize, 1), data.origin_count);
    try std.testing.expectEqual(@as(usize, 421), data.e0_count);
    try std.testing.expectEqual(@as(usize, 225), data.smith_entry_count);
}

test "serialization is deterministic and coordinates recover exactly" {
    const allocator = std.testing.allocator;
    const lattice = lattice_mod.Lattice.init();
    const lookup = exampleTable();
    const first = try serializeAlloc(allocator, &lattice, &lookup);
    defer allocator.free(first);
    const second = try serializeAlloc(allocator, &lattice, &lookup);
    defer allocator.free(second);
    try std.testing.expectEqualSlices(u8, first, second);
    const first_digest = digestBytes(first);
    const second_digest = digestBytes(second);
    try std.testing.expectEqualSlices(u8, &first_digest, &second_digest);
    try std.testing.expect(std.mem.startsWith(u8, first, "{\"schema\":\"octonion-os-lattice-v1\""));
    try std.testing.expect(std.mem.indexOf(u8, first, "\"phase_cycle_steps\":8") != null);
    try std.testing.expect(std.mem.indexOf(u8, first, "\"digest_sha256\":\"") != null);
}

test "all serialized lattice positions have exact inverse indices" {
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const coord = lattice_mod.Lattice.coordFromIndex(flat).?;
        try std.testing.expectEqual(flat, lattice_mod.Lattice.index(coord).?);
    }
}

test "quantized table center is matched and singular states are explicit" {
    const lookup = exampleTable();
    const center = lookup.get(0, 0).?;
    try std.testing.expectEqual(smith_table.ImpedanceState.finite, center.state);
    try std.testing.expectEqual(smith_table.SCALE, center.impedance_re);
    try std.testing.expectEqual(smith_table.ImpedanceState.open, lookup.get(7, 0).?.state);
    try std.testing.expectEqual(smith_table.ImpedanceState.short, lookup.get(-7, 0).?.state);
}

fn exampleTable() smith_table.Table {
    var result: smith_table.Table = .{ .entries = undefined };
    for (0..15) |row| {
        for (0..15) |column| {
            const x: i8 = @intCast(@as(i16, @intCast(column)) - 7);
            const y: i8 = @intCast(@as(i16, @intCast(row)) - 7);
            result.entries[smith_table.index(x, y).?] = .{
                .gamma_re = 0,
                .gamma_im = 0,
                .impedance_re = smith_table.SCALE,
                .impedance_im = 0,
                .state = .finite,
            };
        }
    }
    result.entries[smith_table.index(7, 0).?].state = .open;
    result.entries[smith_table.index(-7, 0).?].state = .short;
    return result;
}
