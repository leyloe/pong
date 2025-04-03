const std = @import("std");

fn add_enet(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    exe: *std.Build.Step.Compile,
) void {
    const en_dep = b.dependency("en", .{
        .target = target,
        .optimize = optimize,
    });

    const en_src_path = en_dep.path("");
    const en_src = en_src_path.getPath(b);

    const library_src_file = b.pathJoin(&.{ en_src, "test", "library.c" });
    const en_include_dir = b.pathJoin(&.{ en_src, "include" });

    exe.addCSourceFile(.{ .file = .{ .cwd_relative = library_src_file } });
    exe.addIncludePath(.{ .cwd_relative = en_include_dir });

    if (target.query.os_tag == .windows)
        exe.linkSystemLibrary("ws2_32");
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    var link_mode: std.builtin.LinkMode = .dynamic;
    if (target.query.abi == .msvc)
        link_mode = .static;

    const exe = b.addExecutable(.{
        .name = "pong",
        .root_module = exe_mod,
        .linkage = link_mode,
    });

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    add_enet(b, target, optimize, exe);

    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
