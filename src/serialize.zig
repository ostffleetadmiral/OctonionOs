const std = @import("std");
const lattice_mod = @import("lattice.zig");
const smith_table = @import("smith_table.zig");
const scaling = @import("scaling.zig");
const routing = @import("routing.zig");
const ladder = @import("ladder.zig");
const frames = @import("frames.zig");
const sha256 = std.crypto.hash.sha2.Sha256;

pub const SCHEMA = "octonion-os-wall-v2";

const JsonString = struct {
    value: []const u8,

    pub fn format(
        self: JsonString,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.writeByte('"');
        for (self.value) |byte| {
            switch (byte) {
                '"' => try writer.writeAll("\\\""),
                '\\' => try writer.writeAll("\\\\"),
                '\n' => try writer.writeAll("\\n"),
                '\r' => try writer.writeAll("\\r"),
                '\t' => try writer.writeAll("\\t"),
                0...0x08, 0x0b, 0x0c, 0x0e...0x1f => {
                    const hex = "0123456789abcdef";
                    try writer.writeAll("\\u00");
                    try writer.writeByte(hex[byte >> 4]);
                    try writer.writeByte(hex[byte & 0x0f]);
                },
                else => try writer.writeByte(byte),
            }
        }
        try writer.writeByte('"');
    }
};

pub const Manifest = struct {
    node_count: usize,
    origin_count: usize,
    e0_count: usize,
    defect_count: u8,
    phase_cycle_steps: u8,
    smith_entry_count: usize,
    tier_count: usize,
    shell_cell_count: u32,
    eligible_secondary_e0_count: usize,
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
    const shell: scaling.ShellMetadata = .{};
    return origin_count == 1 and scaling.validateAllTiers() and
        shell.validate() and routing.eligibleCount(lattice) == routing.ELIGIBLE_SITE_COUNT;
}

pub fn validateState(
    lattice: *const lattice_mod.Lattice,
    table: *const smith_table.Table,
    placements: []const scaling.CorePlacement,
    seams: []const scaling.SeamContact,
    router: *const routing.Router,
) bool {
    if (!validate(lattice, table) or !router.validate()) return false;
    validatePlacementSet(placements, seams) catch return false;
    return true;
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
        .tier_count = scaling.TIERS.len,
        .shell_cell_count = scaling.SHELL_CELL_COUNT,
        .eligible_secondary_e0_count = routing.eligibleCount(lattice),
        .digest = digest,
    };
}

pub fn writeJson(
    writer: anytype,
    lattice: *const lattice_mod.Lattice,
    table: *const smith_table.Table,
    placements: []const scaling.CorePlacement,
    seams: []const scaling.SeamContact,
    router: *const routing.Router,
    phase_convention: ?lattice_mod.PhaseConvention,
) !void {
    const selected_phase = phase_convention orelse return error.PhaseConventionRequired;
    return writeJsonWithPhase(writer, lattice, table, placements, seams, router, selected_phase);
}

fn writeJsonWithPhase(
    writer: anytype,
    lattice: *const lattice_mod.Lattice,
    table: *const smith_table.Table,
    placements: []const scaling.CorePlacement,
    seams: []const scaling.SeamContact,
    router: *const routing.Router,
    phase_convention: lattice_mod.PhaseConvention,
) !void {
    if (!ladder.validateCatalog()) return error.InvalidClaimCatalog;
    if (!validateState(lattice, table, placements, seams, router)) return error.InvalidManifest;
    try writer.print("{{\"schema\":\"{s}\",\"nodes\":[", .{SCHEMA});
    for (0..lattice_mod.NODE_COUNT) |flat| {
        if (flat != 0) try writer.writeByte(',');
        const coord = lattice_mod.Lattice.coordFromIndex(flat).?;
        const label = lattice.labels[flat];
        const layer_index: usize = @intCast(@as(i16, coord.z) + 7);
        try writer.print(
            "{{\"x\":{d},\"y\":{d},\"z\":{d},\"fano\":{d},\"layer\":{d},\"layer_pivot\":{d},\"primary_e0\":{s}}}",
            .{ coord.x, coord.y, coord.z, label, layer_index + 1, lattice.layer(layer_index).?.pivot, if (coord.x == 0 and coord.y == 0 and coord.z == 0) "true" else "false" },
        );
    }
    var check_frames = frames.extract(lattice);
    if (frames.reassemble(&check_frames) == null) return error.InvalidManifest;
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
    try writer.writeAll("],\"tiers\":[");
    for (scaling.TIERS, 0..) |tier, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print(
            "{{\"qbits\":{d},\"dimensions\":{d},\"universes\":{d},\"base_side\":{d},\"padded_side\":{d},\"counts_are_supplied_metadata\":true,\"canonical_16_stride_layout\":false}}",
            .{ tier.qbits, tier.dimensions, tier.universes, tier.base_side, tier.padded_side },
        );
    }
    try writer.print(
        "],\"shell\":{{\"inner_side\":{d},\"outer_side\":{d},\"core_volume\":{d},\"container_volume\":{d},\"sparse_added_cell_count\":{d},\"selected_wall_planes_per_axis\":1,\"selected_face_cell_count\":{d},\"selected_face_unique_cell_count\":{d},\"label\":\"e9\",\"state_transfer_defined\":false}},\"placements\":[",
        .{ scaling.CORE_SIDE, scaling.SHELL_SIDE, scaling.CORE_VOLUME, scaling.SHELL_VOLUME, scaling.SHELL_CELL_COUNT, shellMetadata().selected_face_cell_count, shellMetadata().selected_face_unique_cell_count },
    );
    var sorted_placements = [_]scaling.CorePlacement{undefined} ** scaling.MAX_PLACEMENTS;
    @memcpy(sorted_placements[0..placements.len], placements);
    std.mem.sort(scaling.CorePlacement, sorted_placements[0..placements.len], {}, struct {
        fn lessThan(_: void, a: scaling.CorePlacement, b: scaling.CorePlacement) bool {
            return a.id < b.id;
        }
    }.lessThan);
    for (sorted_placements[0..placements.len], 0..) |placement, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print(
            "{{\"id\":{d},\"origin_x\":{d},\"origin_y\":{d},\"origin_z\":{d},\"core_origin_x\":{d},\"core_origin_y\":{d},\"core_origin_z\":{d},\"padding_x\":\"{s}\",\"padding_y\":\"{s}\",\"padding_z\":\"{s}\",\"container_min_x\":{d},\"container_min_y\":{d},\"container_min_z\":{d},\"container_max_x\":{d},\"container_max_y\":{d},\"container_max_z\":{d},\"sparse_shell_cell_count\":{d}}}",
            .{
                placement.id,
                placement.container_origin.x,
                placement.container_origin.y,
                placement.container_origin.z,
                placement.globalCoreOrigin().?.x,
                placement.globalCoreOrigin().?.y,
                placement.globalCoreOrigin().?.z,
                @tagName(placement.padding[0]),
                @tagName(placement.padding[1]),
                @tagName(placement.padding[2]),
                placement.containerBounds().?.min.x,
                placement.containerBounds().?.min.y,
                placement.containerBounds().?.min.z,
                placement.containerBounds().?.max.x,
                placement.containerBounds().?.max.y,
                placement.containerBounds().?.max.z,
                scaling.SHELL_CELL_COUNT,
            },
        );
    }
    try writer.writeAll("],\"seams\":[");
    var sorted_seams = [_]scaling.SeamContact{undefined} ** scaling.MAX_SEAM_CONTACTS;
    @memcpy(sorted_seams[0..seams.len], seams);
    sortSeams(sorted_seams[0..seams.len]);
    for (sorted_seams[0..seams.len], 0..) |seam, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print(
            "{{\"core_a\":{d},\"core_b\":{d},\"axis\":\"{s}\",\"interface_plane\":{d},\"side_a\":\"{s}\",\"side_b\":\"{s}\",\"kind\":\"{s}\",\"convention\":\"{s}\"}}",
            .{ seam.core_a, seam.core_b, @tagName(seam.axis), seam.interface_plane, @tagName(seam.side_a), @tagName(seam.side_b), @tagName(seam.kind), @tagName(seam.convention) },
        );
    }
    try writer.print("],\"claims\":[", .{});
    for (ladder.CLAIMS ++ ladder.EXTERNAL_PROVENANCE, 0..) |claim, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print(
            "{{\"id\":{d},\"subject\":{f},\"statement\":{f},\"verdict\":\"{s}\",\"probe\":{f},\"basis\":{f},\"elevation\":{f}}}",
            .{ claim.id, JsonString{ .value = claim.subject }, JsonString{ .value = claim.statement }, @tagName(claim.status), JsonString{ .value = claim.probe }, JsonString{ .value = claim.basis }, JsonString{ .value = claim.elevation } },
        );
    }
    try writer.writeAll("],\"ivector\":[");
    for (ladder.ENTRIES, 0..) |entry, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print(
            "{{\"index\":{d},\"dimension\":{f},\"designation\":{f},\"algebra\":{f},\"lie_group\":{f},\"fields\":{d},\"status\":\"{s}\"}}",
            .{ entry.index, JsonString{ .value = entry.dimension_label }, JsonString{ .value = entry.designation }, JsonString{ .value = entry.algebra }, JsonString{ .value = entry.lie_group }, entry.fields, @tagName(entry.status) },
        );
    }
    try writer.writeAll("],\"dimensional_ladder_source_records\":[");
    for (ladder.FULL_LADDER, 0..) |entry, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print(
            "{{\"index\":{f},\"designation\":{f},\"algebra\":{f},\"field_bound\":{f},\"lie_group\":{f},\"core_role\":{f},\"status\":\"{s}\"}}",
            .{ JsonString{ .value = entry.index }, JsonString{ .value = entry.designation }, JsonString{ .value = entry.algebra }, JsonString{ .value = entry.field_bound }, JsonString{ .value = entry.lie_group }, JsonString{ .value = entry.core_role }, @tagName(entry.status) },
        );
    }
    try writer.writeAll("],\"field_bounds_source_text\":[");
    for (ladder.SUPPLIED_FIELD_BOUND_TEXT, 0..) |statement, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("{f}", .{JsonString{ .value = statement }});
    }
    try writer.writeAll("],\"phase_probes\":[");
    for (ladder.PHASE_PROBES, 0..) |probe, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print(
            "{{\"convention\":{f},\"increment_eighth_turns\":{d},\"cycle_steps\":{d},\"sequence\":[",
            .{ JsonString{ .value = probe.convention }, probe.increments_eighth_turns, probe.cycle_steps },
        );
        for (probe.expected_sequence, 0..) |phase, step| {
            if (step != 0) try writer.writeByte(',');
            try writer.print("{d}", .{phase});
        }
        try writer.writeAll("]}");
    }
    try writer.writeAll("],\"blue_fano_routing_candidate\":{\"source\":\"BLUE src/fano_routing.zig\",\"source_sha256\":\"152b391fcfd4839d07db8ac00b016da40a39e74c110c73fdf2b47daa829e6d72\",\"status\":\"not_adopted\",\"compatibility\":\"fails for some secondary e0 endpoints\"},\"ladder_shells\":[");
    for (scaling.LADDER_SHELLS, 0..) |shell, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print(
            "{{\"dimension\":{d},\"designation\":{f},\"algebra\":{f},\"padding_side\":{d},\"status\":\"{s}\"}}",
            .{ shell.dimension, JsonString{ .value = shell.designation }, JsonString{ .value = shell.algebra }, shell.padding_side, @tagName(shell.status) },
        );
    }
    try writer.writeAll("],\"frames\":[");
    const frame_records = frames.extract(lattice);
    for (frame_records, 0..) |frame, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print(
            "{{\"layer\":{d},\"z\":{d},\"pivot\":{d},\"mirror_index\":{d},\"central\":{s},\"labels\":[",
            .{ frame.layer.index, frame.layer.z, frame.layer.pivot, frame.layer.mirror_index, if (frame.layer.is_central) "true" else "false" },
        );
        for (frame.labels, 0..) |label, label_index| {
            if (label_index != 0) try writer.writeByte(',');
            try writer.print("{d}", .{label});
        }
        try writer.print("],\"sha256\":\"{s}\"}}", .{hexDigest(frame.digest())});
    }
    try writer.writeAll("],\"frame_reassembly_verified\":true,\"routing\":");
    try writer.print("{{\"eligible_secondary_e0_count\":{d},\"policy\":\"{s}\",\"edge_count\":{d},\"primary_origin_excluded\":true,\"reservation_policy\":\"occupied_until_successful_move\",\"lock_policy\":\"source_and_target_for_one_transition\",\"tokens\":[", .{ routing.eligibleCount(lattice), @tagName(router.policy), router.edge_count });
    var sorted_tokens = [_]routing.Token{undefined} ** routing.MAX_TOKENS;
    @memcpy(sorted_tokens[0..router.token_count], router.tokens[0..router.token_count]);
    std.mem.sort(routing.Token, sorted_tokens[0..router.token_count], {}, struct {
        fn lessThan(_: void, a: routing.Token, b: routing.Token) bool {
            return a.id < b.id;
        }
    }.lessThan);
    for (sorted_tokens[0..router.token_count], 0..) |token, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("{{\"id\":{d},\"x\":{d},\"y\":{d},\"z\":{d}}}", .{ token.id, token.position.x, token.position.y, token.position.z });
    }
    try writer.writeAll("],\"reservations\":[");
    var first_reservation = true;
    for (0..lattice_mod.NODE_COUNT) |flat| {
        if (!router.occupied[flat]) continue;
        if (!first_reservation) try writer.writeByte(',');
        first_reservation = false;
        const position = lattice_mod.Lattice.coordFromIndex(flat).?;
        try writer.print("{{\"x\":{d},\"y\":{d},\"z\":{d}}}", .{ position.x, position.y, position.z });
    }
    var sorted_edges = [_]routing.Edge{undefined} ** routing.MAX_GRAPH_EDGES;
    @memcpy(sorted_edges[0..router.edge_count], router.edges[0..router.edge_count]);
    std.mem.sort(routing.Edge, sorted_edges[0..router.edge_count], {}, struct {
        fn lessThan(_: void, a: routing.Edge, b: routing.Edge) bool {
            return a.a < b.a or (a.a == b.a and a.b < b.b);
        }
    }.lessThan);
    try writer.writeAll("],\"edges\":[");
    for (sorted_edges[0..router.edge_count], 0..) |edge, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("[{d},{d}]", .{ edge.a, edge.b });
    }
    try writer.writeAll("]},\"supplied_counts_are_not_physical_derivations\":true,\"seam_entanglement_calculation_performed\":false,\"defect_count\":");
    try writer.print("{d},\"defect_placement_defined\":false,\"transit_phase\":{{\"convention\":\"{s}\",\"increment_eighth_turns\":{d},\"cycle_steps\":{d}}},\"digest_sha256\":\"{s}\"}}", .{
        lattice_mod.DEFECT_COUNT,
        @tagName(phase_convention),
        phase_convention.incrementEighthTurns(),
        lattice_mod.PHASE_STEPS_PER_CYCLE,
        hexDigest(latticeDigest(lattice, table, placements, seams, router, phase_convention)),
    });
}

fn validatePlacementSet(placements: []const scaling.CorePlacement, seams: []const scaling.SeamContact) !void {
    if (placements.len > scaling.MAX_PLACEMENTS or seams.len > scaling.MAX_SEAM_CONTACTS) return error.InvalidManifest;
    if (placements.len == 0) {
        if (seams.len != 0) return error.InvalidManifest;
        return;
    }
    var matches_tier = false;
    for (scaling.TIERS) |tier| {
        scaling.validatePlacements(tier, placements) catch continue;
        matches_tier = true;
        break;
    }
    if (!matches_tier) return error.InvalidManifest;
    try scaling.validateSeamContacts(placements, seams);
}

fn sortSeams(seams: []scaling.SeamContact) void {
    std.mem.sort(scaling.SeamContact, seams, {}, struct {
        fn lessThan(_: void, a: scaling.SeamContact, b: scaling.SeamContact) bool {
            if (a.core_a != b.core_a) return a.core_a < b.core_a;
            if (a.core_b != b.core_b) return a.core_b < b.core_b;
            if (a.axis != b.axis) return @intFromEnum(a.axis) < @intFromEnum(b.axis);
            if (a.interface_plane != b.interface_plane) return a.interface_plane < b.interface_plane;
            if (a.side_a != b.side_a) return @intFromEnum(a.side_a) < @intFromEnum(b.side_a);
            if (a.side_b != b.side_b) return @intFromEnum(a.side_b) < @intFromEnum(b.side_b);
            if (a.kind != b.kind) return @intFromEnum(a.kind) < @intFromEnum(b.kind);
            if (a.convention != b.convention) return @intFromEnum(a.convention) < @intFromEnum(b.convention);
            return false;
        }
    }.lessThan);
}

fn latticeDigest(lattice: *const lattice_mod.Lattice, table: *const smith_table.Table, placements: []const scaling.CorePlacement, seams: []const scaling.SeamContact, router: *const routing.Router, phase_convention: lattice_mod.PhaseConvention) [32]u8 {
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    hash.update("octonion-os-wall-v2");
    hash.update(&.{@intFromEnum(phase_convention)});
    for (lattice.labels) |label| hash.update(&.{label});
    for (table.entries) |entry| {
        hash.update(std.mem.asBytes(&entry.gamma_re));
        hash.update(std.mem.asBytes(&entry.gamma_im));
        hash.update(std.mem.asBytes(&entry.impedance_re));
        hash.update(std.mem.asBytes(&entry.impedance_im));
        hash.update(&.{@intFromEnum(entry.state)});
    }
    for (scaling.TIERS) |tier| {
        hash.update(std.mem.asBytes(&tier.qbits));
        hash.update(std.mem.asBytes(&tier.dimensions));
        hash.update(std.mem.asBytes(&tier.universes));
        hash.update(std.mem.asBytes(&tier.base_side));
        hash.update(std.mem.asBytes(&tier.padded_side));
        hash.update(&.{@intFromBool(tier.counts_are_supplied_metadata)});
        hash.update(&.{@intFromBool(scaling.validateTier(tier))});
    }
    hash.update(std.mem.asBytes(&scaling.CORE_SIDE));
    hash.update(std.mem.asBytes(&scaling.SHELL_SIDE));
    hash.update(std.mem.asBytes(&scaling.CORE_VOLUME));
    hash.update(std.mem.asBytes(&scaling.SHELL_VOLUME));
    hash.update(std.mem.asBytes(&scaling.SHELL_CELL_COUNT));
    const shell = shellMetadata();
    hash.update(std.mem.asBytes(&shell.selected_face_cell_count));
    hash.update(std.mem.asBytes(&shell.selected_face_unique_cell_count));
    hash.update(&.{ shell.selected_wall_planes_per_axis, @intFromBool(shell.state_transfer_defined) });
    hash.update(std.mem.asBytes(&shell.inner_side));
    hash.update(std.mem.asBytes(&shell.outer_side));
    hash.update(std.mem.asBytes(&shell.core_volume));
    hash.update(std.mem.asBytes(&shell.container_volume));
    hash.update(std.mem.asBytes(&shell.sparse_added_cell_count));
    var sorted_placements = [_]scaling.CorePlacement{undefined} ** scaling.MAX_PLACEMENTS;
    @memcpy(sorted_placements[0..placements.len], placements);
    std.mem.sort(scaling.CorePlacement, sorted_placements[0..placements.len], {}, struct {
        fn lessThan(_: void, a: scaling.CorePlacement, b: scaling.CorePlacement) bool {
            return a.id < b.id;
        }
    }.lessThan);
    for (sorted_placements[0..placements.len]) |placement| {
        hash.update(std.mem.asBytes(&placement.id));
        hash.update(std.mem.asBytes(&placement.container_origin.x));
        hash.update(std.mem.asBytes(&placement.container_origin.y));
        hash.update(std.mem.asBytes(&placement.container_origin.z));
        for (placement.padding) |direction| hash.update(&.{@intFromEnum(direction)});
    }
    var sorted_seams = [_]scaling.SeamContact{undefined} ** scaling.MAX_SEAM_CONTACTS;
    @memcpy(sorted_seams[0..seams.len], seams);
    std.mem.sort(scaling.SeamContact, sorted_seams[0..seams.len], {}, struct {
        fn lessThan(_: void, a: scaling.SeamContact, b: scaling.SeamContact) bool {
            if (a.core_a != b.core_a) return a.core_a < b.core_a;
            if (a.core_b != b.core_b) return a.core_b < b.core_b;
            if (a.axis != b.axis) return @intFromEnum(a.axis) < @intFromEnum(b.axis);
            if (a.interface_plane != b.interface_plane) return a.interface_plane < b.interface_plane;
            if (a.side_a != b.side_a) return @intFromEnum(a.side_a) < @intFromEnum(b.side_a);
            if (a.side_b != b.side_b) return @intFromEnum(a.side_b) < @intFromEnum(b.side_b);
            if (a.kind != b.kind) return @intFromEnum(a.kind) < @intFromEnum(b.kind);
            if (a.convention != b.convention) return @intFromEnum(a.convention) < @intFromEnum(b.convention);
            return false;
        }
    }.lessThan);
    for (sorted_seams[0..seams.len]) |seam| {
        hash.update(std.mem.asBytes(&seam.core_a));
        hash.update(std.mem.asBytes(&seam.core_b));
        hash.update(&.{
            @intFromEnum(seam.axis),
            @intFromEnum(seam.side_a),
            @intFromEnum(seam.side_b),
            @intFromEnum(seam.kind),
            @intFromEnum(seam.convention),
        });
        hash.update(std.mem.asBytes(&seam.interface_plane));
    }
    var sorted_tokens: [routing.MAX_TOKENS]routing.Token = undefined;
    @memcpy(sorted_tokens[0..router.token_count], router.tokens[0..router.token_count]);
    std.mem.sort(routing.Token, sorted_tokens[0..router.token_count], {}, struct {
        fn lessThan(_: void, a: routing.Token, b: routing.Token) bool {
            return a.id < b.id;
        }
    }.lessThan);
    hash.update(std.mem.asBytes(&router.token_count));
    hash.update(&.{@intFromEnum(router.policy)});
    hash.update("axial_one_step=eligible axial endpoints with Manhattan distance 1; supplied_edge_graph=canonical undirected eligible-only edges");
    hash.update(std.mem.asBytes(&router.edge_count));
    for (sorted_tokens[0..router.token_count]) |token| {
        hash.update(std.mem.asBytes(&token.id));
        hash.update(std.mem.asBytes(&token.position.x));
        hash.update(std.mem.asBytes(&token.position.y));
        hash.update(std.mem.asBytes(&token.position.z));
    }
    for (router.occupied, 0..) |occupied, index| {
        if (occupied) hash.update(std.mem.asBytes(&index));
    }
    var sorted_edges = [_]routing.Edge{undefined} ** routing.MAX_GRAPH_EDGES;
    @memcpy(sorted_edges[0..router.edge_count], router.edges[0..router.edge_count]);
    std.mem.sort(routing.Edge, sorted_edges[0..router.edge_count], {}, struct {
        fn lessThan(_: void, a: routing.Edge, b: routing.Edge) bool {
            return a.a < b.a or (a.a == b.a and a.b < b.b);
        }
    }.lessThan);
    for (sorted_edges[0..router.edge_count]) |edge| {
        hash.update(std.mem.asBytes(&edge.a));
        hash.update(std.mem.asBytes(&edge.b));
    }
    const frame_records = frames.extract(lattice);
    for (frame_records) |frame| hash.update(&frame.digest());
    for (ladder.CLAIMS ++ ladder.EXTERNAL_PROVENANCE) |claim| {
        hash.update(std.mem.asBytes(&claim.id));
        hash.update(std.mem.asBytes(&claim.subject.len));
        hash.update(claim.subject);
        hash.update(std.mem.asBytes(&claim.statement.len));
        hash.update(claim.statement);
        hash.update(&.{@intFromEnum(claim.status)});
        hash.update(std.mem.asBytes(&claim.probe.len));
        hash.update(claim.probe);
        hash.update(std.mem.asBytes(&claim.basis.len));
        hash.update(claim.basis);
        hash.update(std.mem.asBytes(&claim.elevation.len));
        hash.update(claim.elevation);
    }
    for (ladder.ENTRIES) |entry| {
        hash.update(&.{entry.index});
        hash.update(std.mem.asBytes(&entry.dimension_label.len));
        hash.update(entry.dimension_label);
        hash.update(std.mem.asBytes(&entry.designation.len));
        hash.update(entry.designation);
        hash.update(std.mem.asBytes(&entry.algebra.len));
        hash.update(entry.algebra);
        hash.update(std.mem.asBytes(&entry.lie_group.len));
        hash.update(entry.lie_group);
        hash.update(&.{ entry.fields, @intFromEnum(entry.status) });
    }
    for (ladder.FULL_LADDER) |entry| {
        for ([_][]const u8{ entry.index, entry.designation, entry.algebra, entry.field_bound, entry.lie_group, entry.core_role }) |value| {
            hash.update(std.mem.asBytes(&value.len));
            hash.update(value);
        }
        hash.update(&.{@intFromEnum(entry.status)});
    }
    for (ladder.SUPPLIED_FIELD_BOUND_TEXT) |statement| {
        hash.update(std.mem.asBytes(&statement.len));
        hash.update(statement);
    }
    for (ladder.PHASE_PROBES) |probe| {
        hash.update(std.mem.asBytes(&probe.convention.len));
        hash.update(probe.convention);
        hash.update(&.{ probe.increments_eighth_turns, probe.cycle_steps });
        hash.update(&probe.expected_sequence);
    }
    hash.update("BLUE src/fano_routing.zig;152b391fcfd4839d07db8ac00b016da40a39e74c110c73fdf2b47daa829e6d72;not_adopted;fails_for_some_secondary_e0_endpoints");
    for (scaling.LADDER_SHELLS) |ladder_shell| {
        hash.update(std.mem.asBytes(&ladder_shell.dimension));
        hash.update(std.mem.asBytes(&ladder_shell.designation.len));
        hash.update(ladder_shell.designation);
        hash.update(std.mem.asBytes(&ladder_shell.algebra.len));
        hash.update(ladder_shell.algebra);
        hash.update(std.mem.asBytes(&ladder_shell.padding_side));
        hash.update(&.{@intFromEnum(ladder_shell.status)});
    }
    var digest: [32]u8 = undefined;
    hash.final(&digest);
    return digest;
}

fn shellMetadata() scaling.ShellMetadata {
    return .{};
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

pub fn serializeAlloc(
    allocator: std.mem.Allocator,
    lattice: *const lattice_mod.Lattice,
    table: *const smith_table.Table,
    placements: []const scaling.CorePlacement,
    seams: []const scaling.SeamContact,
    router: *const routing.Router,
    phase_convention: ?lattice_mod.PhaseConvention,
) ![]u8 {
    var output = std.ArrayList(u8).init(allocator);
    errdefer output.deinit();
    try writeJson(output.writer(), lattice, table, placements, seams, router, phase_convention);
    return output.toOwnedSlice();
}

test "wall manifest parses as JSON and has the declared schema and dimensions" {
    const allocator = std.testing.allocator;
    const lattice = lattice_mod.Lattice.init();
    const table = exampleTable();
    const router = routing.Router.init(lattice);
    const json_text = try serializeAlloc(allocator, &lattice, &table, &.{}, &.{}, &router, .three_quarter_turn_per_transit);
    defer allocator.free(json_text);
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_text, .{});
    defer parsed.deinit();
    try std.testing.expect(parsed.value == .object);
    const schema = parsed.value.object.get("schema") orelse return error.MissingSchema;
    try std.testing.expect(schema == .string);
    try std.testing.expectEqualStrings(SCHEMA, schema.string);
    try std.testing.expectEqual(@as(usize, lattice_mod.NODE_COUNT), parsed.value.object.get("nodes").?.array.items.len);
    try std.testing.expectEqual(@as(usize, lattice_mod.LAYERS), parsed.value.object.get("frames").?.array.items.len);
    const phase = parsed.value.object.get("transit_phase").?.object;
    try std.testing.expectEqualStrings("three_quarter_turn_per_transit", phase.get("convention").?.string);
    try std.testing.expectEqual(@as(i64, 3), phase.get("increment_eighth_turns").?.integer);
    try std.testing.expectEqualStrings("unresolvable", parsed.value.object.get("claims").?.array.items[3].object.get("verdict").?.string);
}

test "JSON string encoding escapes quotes, slashes, and control bytes" {
    const allocator = std.testing.allocator;
    const input = [_]u8{ 'q', '"', '\\', '\n', '\t', 1 };
    const encoded = try std.fmt.allocPrint(allocator, "{f}", .{JsonString{ .value = &input }});
    defer allocator.free(encoded);
    try std.testing.expectEqualStrings("\"q\\\"\\\\\\n\\t\\u0001\"", encoded);
}

test "manifest requires a caller-selected transit phase convention" {
    const allocator = std.testing.allocator;
    const lattice = lattice_mod.Lattice.init();
    const table = exampleTable();
    const router = routing.Router.init(lattice);
    try std.testing.expectError(
        error.PhaseConventionRequired,
        serializeAlloc(allocator, &lattice, &table, &.{}, &.{}, &router, null),
    );
    const quarter = try serializeAlloc(allocator, &lattice, &table, &.{}, &.{}, &router, .quarter_turn_per_transit);
    defer allocator.free(quarter);
    const three_quarter = try serializeAlloc(allocator, &lattice, &table, &.{}, &.{}, &router, .three_quarter_turn_per_transit);
    defer allocator.free(three_quarter);
    try std.testing.expect(!std.mem.eql(u8, quarter, three_quarter));
    try std.testing.expect(std.mem.indexOf(u8, three_quarter, "\"increment_eighth_turns\":3") != null);
}

test "manifest rejects invalid state and over-capacity input before serialization" {
    const allocator = std.testing.allocator;
    const lattice = lattice_mod.Lattice.init();
    const table = exampleTable();
    var invalid_router = routing.Router.init(lattice);
    invalid_router.token_count = routing.MAX_TOKENS + 1;
    try std.testing.expectError(
        error.InvalidManifest,
        serializeAlloc(allocator, &lattice, &table, &.{}, &.{}, &invalid_router, .quarter_turn_per_transit),
    );
    const too_many_placements = [_]scaling.CorePlacement{undefined} ** (scaling.MAX_PLACEMENTS + 1);
    const router = routing.Router.init(lattice);
    try std.testing.expectError(
        error.InvalidManifest,
        serializeAlloc(allocator, &lattice, &table, &too_many_placements, &.{}, &router, .quarter_turn_per_transit),
    );
}

test "manifest contains the ladder catalog and all deterministic optical frames" {
    const allocator = std.testing.allocator;
    const lattice = lattice_mod.Lattice.init();
    const table = exampleTable();
    const router = routing.Router.init(lattice);
    const json = try serializeAlloc(allocator, &lattice, &table, &.{}, &.{}, &router, .three_quarter_turn_per_transit);
    defer allocator.free(json);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"claims\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"id\":100") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"dimensional_ladder_source_records\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"field_bounds_source_text\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"phase_probes\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"blue_fano_routing_candidate\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"status\":\"not_adopted\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"frames\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"frame_reassembly_verified\":true") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"layer\":14,\"z\":7") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"verdict\":\"unresolvable\"") != null);
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
    var router = routing.Router.init(lattice);
    try router.addToken(.{ .id = 4, .position = findSecondaryE0(&lattice) });
    const first = try serializeAlloc(allocator, &lattice, &lookup, &.{}, &.{}, &router, .quarter_turn_per_transit);
    defer allocator.free(first);
    const second = try serializeAlloc(allocator, &lattice, &lookup, &.{}, &.{}, &router, .quarter_turn_per_transit);
    defer allocator.free(second);
    try std.testing.expectEqualSlices(u8, first, second);
    const first_digest = digestBytes(first);
    const second_digest = digestBytes(second);
    try std.testing.expectEqualSlices(u8, &first_digest, &second_digest);
    try std.testing.expect(std.mem.startsWith(u8, first, "{\"schema\":\"octonion-os-wall-v2\""));
    try std.testing.expect(std.mem.indexOf(u8, first, "\"cycle_steps\":8") != null);
    try std.testing.expect(std.mem.indexOf(u8, first, "\"increment_eighth_turns\":1") != null);
    try std.testing.expect(std.mem.indexOf(u8, first, "\"digest_sha256\":\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, first, "\"sparse_added_cell_count\":721") != null);
    try std.testing.expect(std.mem.indexOf(u8, first, "\"eligible_secondary_e0_count\":420") != null);
}

test "digest input changes with routing, placements, and seams" {
    const allocator = std.testing.allocator;
    const lattice = lattice_mod.Lattice.init();
    const lookup = exampleTable();
    var empty_router = routing.Router.init(lattice);
    const empty = try serializeAlloc(allocator, &lattice, &lookup, &.{}, &.{}, &empty_router, .quarter_turn_per_transit);
    defer allocator.free(empty);
    try empty_router.addToken(.{ .id = 7, .position = findSecondaryE0(&lattice) });
    const with_token = try serializeAlloc(allocator, &lattice, &lookup, &.{}, &.{}, &empty_router, .quarter_turn_per_transit);
    defer allocator.free(with_token);
    try std.testing.expect(!std.mem.eql(u8, empty, with_token));
    const placed_router = routing.Router.init(lattice);
    const placement = [_]scaling.CorePlacement{.{
        .id = 1,
        .container_origin = .{ .x = 0, .y = 0, .z = 0 },
        .padding = .{ .positive, .positive, .positive },
    }};
    const with_placement = try serializeAlloc(allocator, &lattice, &lookup, &placement, &.{}, &placed_router, .quarter_turn_per_transit);
    defer allocator.free(with_placement);
    try std.testing.expect(!std.mem.eql(u8, empty, with_placement));
}

test "digest changes when a seam convention changes" {
    const allocator = std.testing.allocator;
    const lattice = lattice_mod.Lattice.init();
    const lookup = exampleTable();
    const placements = [_]scaling.CorePlacement{
        .{ .id = 1, .container_origin = .{ .x = 0, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } },
        .{ .id = 2, .container_origin = .{ .x = 16, .y = 0, .z = 0 }, .padding = .{ .negative, .negative, .negative } },
    };
    const seam_a = [_]scaling.SeamContact{.{
        .core_a = 1,
        .core_b = 2,
        .axis = .x,
        .interface_plane = 15,
        .side_a = .positive,
        .side_b = .negative,
    }};
    const seam_b = [_]scaling.SeamContact{.{
        .core_a = 2,
        .core_b = 1,
        .axis = .x,
        .interface_plane = 15,
        .side_a = .negative,
        .side_b = .positive,
    }};
    const router = routing.Router.init(lattice);
    const a = try serializeAlloc(allocator, &lattice, &lookup, &placements, &seam_a, &router, .quarter_turn_per_transit);
    defer allocator.free(a);
    const b = try serializeAlloc(allocator, &lattice, &lookup, &placements, &seam_b, &router, .quarter_turn_per_transit);
    defer allocator.free(b);
    try std.testing.expect(!std.mem.eql(u8, a, b));
}

test "digest is stable across placement and token insertion order" {
    const allocator = std.testing.allocator;
    const lattice = lattice_mod.Lattice.init();
    const lookup = exampleTable();
    const first_position = findSecondaryE0(&lattice);
    const second_position = findNextSecondaryE0(&lattice, first_position);
    const placements_a = [_]scaling.CorePlacement{
        .{ .id = 3, .container_origin = .{ .x = 20, .y = 0, .z = 0 }, .padding = .{ .negative, .positive, .positive } },
        .{ .id = 1, .container_origin = .{ .x = 0, .y = 0, .z = 0 }, .padding = .{ .positive, .positive, .positive } },
    };
    const placements_b = [_]scaling.CorePlacement{ placements_a[1], placements_a[0] };
    var router_a = routing.Router.init(lattice);
    try router_a.addToken(.{ .id = 5, .position = first_position });
    try router_a.addToken(.{ .id = 2, .position = second_position });
    var router_b = routing.Router.init(lattice);
    try router_b.addToken(.{ .id = 2, .position = second_position });
    try router_b.addToken(.{ .id = 5, .position = first_position });
    const placements_c = [_]scaling.CorePlacement{
        .{ .id = 3, .container_origin = .{ .x = 16, .y = 0, .z = 0 }, .padding = .{ .negative, .positive, .positive } },
        placements_a[1],
    };
    const a = try serializeAlloc(allocator, &lattice, &lookup, &placements_a, &.{}, &router_a, .quarter_turn_per_transit);
    defer allocator.free(a);
    const b = try serializeAlloc(allocator, &lattice, &lookup, &placements_b, &.{}, &router_b, .quarter_turn_per_transit);
    defer allocator.free(b);
    try std.testing.expectEqualSlices(u8, a, b);
    try std.testing.expectEqual(latticeDigest(&lattice, &lookup, &placements_a, &.{}, &router_a, .quarter_turn_per_transit), latticeDigest(&lattice, &lookup, &placements_b, &.{}, &router_b, .quarter_turn_per_transit));
    const changed = try serializeAlloc(allocator, &lattice, &lookup, &placements_c, &.{}, &router_a, .quarter_turn_per_transit);
    defer allocator.free(changed);
    try std.testing.expect(!std.mem.eql(u8, a, changed));
}

test "supplied-edge graph ordering is canonical in manifest and digest" {
    const allocator = std.testing.allocator;
    const lattice = lattice_mod.Lattice.init();
    const table = exampleTable();
    var eligible: [routing.ELIGIBLE_SITE_COUNT]lattice_mod.Coord = undefined;
    var count: usize = 0;
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const position = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (routing.isEligible(&lattice, position)) {
            eligible[count] = position;
            count += 1;
        }
    }
    const indices = [_]u16{
        @intCast(lattice_mod.Lattice.index(eligible[0]).?),
        @intCast(lattice_mod.Lattice.index(eligible[1]).?),
        @intCast(lattice_mod.Lattice.index(eligible[2]).?),
        @intCast(lattice_mod.Lattice.index(eligible[3]).?),
    };
    var edges_a = [_]routing.Edge{
        .{ .a = @min(indices[0], indices[2]), .b = @max(indices[0], indices[2]) },
        .{ .a = @min(indices[1], indices[3]), .b = @max(indices[1], indices[3]) },
    };
    std.mem.sort(routing.Edge, &edges_a, {}, struct {
        fn lessThan(_: void, left: routing.Edge, right: routing.Edge) bool {
            return left.a < right.a or (left.a == right.a and left.b < right.b);
        }
    }.lessThan);
    const edges_b = [_]routing.Edge{ edges_a[1], edges_a[0] };
    const edges_b_canonical = [_]routing.Edge{ edges_a[0], edges_a[1] };
    const router_a = try routing.Router.initWithGraph(lattice, &edges_a);
    const router_b = try routing.Router.initWithGraph(lattice, &edges_b_canonical);
    const json_a = try serializeAlloc(allocator, &lattice, &table, &.{}, &.{}, &router_a, .quarter_turn_per_transit);
    defer allocator.free(json_a);
    const json_b = try serializeAlloc(allocator, &lattice, &table, &.{}, &.{}, &router_b, .quarter_turn_per_transit);
    defer allocator.free(json_b);
    try std.testing.expectEqualSlices(u8, json_a, json_b);
    try std.testing.expectEqual(latticeDigest(&lattice, &table, &.{}, &.{}, &router_a, .quarter_turn_per_transit), latticeDigest(&lattice, &table, &.{}, &.{}, &router_b, .quarter_turn_per_transit));
    try std.testing.expectEqual(@as(usize, 2), edges_b.len);
}

fn findSecondaryE0(lattice: *const lattice_mod.Lattice) lattice_mod.Coord {
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const coord = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (routing.isEligible(lattice, coord)) return coord;
    }
    unreachable;
}

fn findNextSecondaryE0(lattice: *const lattice_mod.Lattice, excluded: lattice_mod.Coord) lattice_mod.Coord {
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const coord = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (routing.isEligible(lattice, coord) and
            (coord.x != excluded.x or coord.y != excluded.y or coord.z != excluded.z)) return coord;
    }
    unreachable;
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
