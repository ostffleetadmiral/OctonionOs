const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const core_tests = b.addTest(.{
        .root_source_file = b.path("src/all_tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_core_tests = b.addRunArtifact(core_tests);
    const core_step = b.step("test-core", "Run integer core tests");
    core_step.dependOn(&run_core_tests.step);

    const sidecar_tests = b.addTest(.{
        .root_source_file = b.path("sidecar/all_tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_sidecar_tests = b.addRunArtifact(sidecar_tests);
    const sidecar_step = b.step("test-sidecar", "Run f64 sidecar tests");
    sidecar_step.dependOn(&run_sidecar_tests.step);

    const test_step = b.step("test", "Run core and sidecar tests");
    test_step.dependOn(core_step);
    test_step.dependOn(sidecar_step);
}
