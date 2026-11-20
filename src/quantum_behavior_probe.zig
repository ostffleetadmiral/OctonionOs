const std = @import("std");
const quantum = @import("quantum_model.zig");
const interference = @import("interference.zig");
const observer = @import("observer.zig");

fn printShots(label: []const u8, counts: quantum.ShotCounts) void {
    std.debug.print("{s}: shots={d} outcomes=[{d},{d},{d},{d}]\n", .{
        label,
        counts.shots,
        counts.counts[0],
        counts.counts[1],
        counts.counts[2],
        counts.counts[3],
    });
}

pub fn main() !void {
    var plus = try quantum.State.init(1);
    try plus.applyHadamard(0);
    printShots("H|0> seed=42", try plus.runShots(100_000, 42));

    var bell = try quantum.State.init(2);
    try bell.applyHadamard(0);
    try bell.applyCnot(0, 1);
    std.debug.print("Bell concurrence_q32={d}\n", .{try bell.concurrence()});
    printShots("Bell seed=42", try bell.runShots(100_000, 42));

    var product = try quantum.State.init(2);
    try product.applyHadamard(0);
    try product.applyHadamard(1);
    std.debug.print("Product control concurrence_q32={d}\n", .{try product.concurrence()});
    printShots("Product control seed=42", try product.runShots(100_000, 42));

    for (0..8) |phase| {
        const paths = [_]interference.Path{
            .{ .amplitude = interference.SCALE / 2, .phase_eighth_turns = 0 },
            .{ .amplitude = interference.SCALE / 2, .phase_eighth_turns = @intCast(phase) },
        };
        const result = try interference.combine(&paths);
        std.debug.print("fringe relative_phase={d}: intensity_q32={d}\n", .{ phase, result.intensity });
    }

    var state = try quantum.State.init(1);
    try state.applyHadamard(0);
    const before = observer.Snapshot.fromState(state).digest();
    var monitor = observer.Observer{};
    const first_read = try monitor.observe(observer.Snapshot.fromState(state), 0);
    const second_read = try monitor.observe(observer.Snapshot.fromState(state), quantum.SELECTOR_MAX - 1);
    const after = observer.Snapshot.fromState(state).digest();
    std.debug.print("Passive observer: reads=[{d},{d}] samples={d} digest_unchanged={}\n", .{
        first_read,
        second_read,
        monitor.samples,
        std.mem.eql(u8, &before, &after),
    });
}
