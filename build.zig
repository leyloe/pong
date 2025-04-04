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

fn add_raylib(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    exe: *std.Build.Step.Compile,
) void {
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
}

fn add_run_step(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
) void {
    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn create_build_options(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) std.Build.Module.CreateOptions {
    var options = std.Build.Module.CreateOptions{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    };

    switch (optimize) {
        .Debug => {},
        .ReleaseSafe => {},
        else => {
            options.strip = true;
            options.single_threaded = true;
            options.error_tracing = false;
            options.pic = true;
        },
    }

    return options;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const options = create_build_options(b, target, optimize);

    const exe_mod = b.createModule(options);

    var link_mode: ?std.builtin.LinkMode = null;
    if (target.query.abi == .msvc)
        link_mode = .static;

    const exe = b.addExecutable(.{
        .name = "pong",
        .root_module = exe_mod,
        .linkage = link_mode,
    });

    add_raylib(b, target, optimize, exe);
    add_enet(b, target, optimize, exe);

    b.installArtifact(exe);

    add_run_step(b, exe);
}
