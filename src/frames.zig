const std = @import("std");
const lattice_mod = @import("lattice.zig");

pub const Frame = struct {
    layer: lattice_mod.Layer,
    labels: [lattice_mod.SLICE_NODE_COUNT]u3,

    pub fn digest(self: *const Frame) [32]u8 {
        var result: [32]u8 = undefined;
        var hash = std.crypto.hash.sha2.Sha256.init(.{});
        hash.update(std.mem.asBytes(&self.layer.index));
        hash.update(std.mem.asBytes(&self.layer.z));
        hash.update(std.mem.asBytes(&self.layer.pivot));
        hash.update(std.mem.asBytes(&self.layer.mirror_index));
        hash.update(&.{@intFromBool(self.layer.is_central)});
        for (self.labels) |label| hash.update(&.{label});
        hash.final(&result);
        return result;
    }
};

pub const FrameSet = [lattice_mod.LAYERS]Frame;

pub fn extract(lattice: *const lattice_mod.Lattice) FrameSet {
    var frames: FrameSet = undefined;
    for (0..lattice_mod.LAYERS) |z| {
        frames[z].layer = lattice.layer(z).?;
        for (0..lattice_mod.SLICE_NODE_COUNT) |cell| {
            frames[z].labels[cell] = lattice.labels[z * lattice_mod.SLICE_NODE_COUNT + cell];
        }
    }
    return frames;
}

pub fn reassemble(frames: *const FrameSet) ?lattice_mod.Lattice {
    var lattice: lattice_mod.Lattice = .{ .labels = undefined };
    const expected = lattice_mod.Lattice.init();
    for (frames.*, 0..) |frame, z| {
        const expected_layer: u4 = @intCast(z);
        if (frame.layer.index != expected_layer or frame.layer.z != @as(i8, @intCast(@as(i16, @intCast(z)) - 7))) return null;
        if (frame.layer.mirror_index != 14 - expected_layer or frame.layer.is_central != (z == 7)) return null;
        if (frame.layer.pivot != expected.layer(z).?.pivot) return null;
        @memcpy(lattice.labels[z * lattice_mod.SLICE_NODE_COUNT ..][0..lattice_mod.SLICE_NODE_COUNT], &frame.labels);
    }
    return lattice;
}

test "15 optical frames reassemble all lattice labels exactly" {
    const lattice = lattice_mod.Lattice.init();
    const frames = extract(&lattice);
    const recovered = reassemble(&frames) orelse return error.InvalidFrameSet;
    try std.testing.expectEqualSlices(u3, &lattice.labels, &recovered.labels);
    try std.testing.expect(frames[7].layer.is_central);
}

test "frame digests are deterministic" {
    const lattice = lattice_mod.Lattice.init();
    const frames = extract(&lattice);
    for (frames) |frame| {
        const first = frame.digest();
        const second = frame.digest();
        try std.testing.expectEqualSlices(u8, &first, &second);
    }
}

test "frame reassembly rejects altered layer metadata" {
    const lattice = lattice_mod.Lattice.init();
    var frames = extract(&lattice);
    frames[2].layer.index = 3;
    try std.testing.expect(reassemble(&frames) == null);
}

test "frame digest changes when metadata changes" {
    const lattice = lattice_mod.Lattice.init();
    var frames = extract(&lattice);
    const before = frames[0].digest();
    frames[0].layer.pivot = @intCast((@as(u4, frames[0].layer.pivot) + 1) % 8);
    const after = frames[0].digest();
    try std.testing.expect(!std.mem.eql(u8, &before, &after));
}
