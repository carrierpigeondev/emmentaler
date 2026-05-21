const std = @import("std");

pub fn build(b: *std.Build) void {
    // ----------------------------------------------------
    // Standard Build Setup
    // ----------------------------------------------------
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

    // ----------------------------------------------------
    // Dependencies
    // ----------------------------------------------------

    // https://github.com/eneskemalergin/z-toml
    //
    const z_toml = b.dependency("z_toml", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("toml", z_toml.module("toml"));

    // https://github.com/raylib-zig/raylib-zig
    //
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library
    exe.root_module.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    // ----------------------------------------------------
    // installArtifact & Build Steps
    // ----------------------------------------------------

    b.installArtifact(exe);

    // `zig build run`
    //
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
