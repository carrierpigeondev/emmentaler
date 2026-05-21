const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "Emmentaler",
        .root_module = exe_module,
    });

    const opts = b.addOptions();
    exe.root_module.addOptions("build_options", opts);

    const z_toml = b.dependency("z_toml", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("toml", z_toml.module("toml"));

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
