const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("github_sdk_for_zig", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    const compile_check = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/compile_check.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const check_step = b.step("check", "Compile every generated operation");
    check_step.dependOn(&compile_check.step);
}
