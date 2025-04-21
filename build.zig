const std = @import("std");

fn add_clap(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const s2s_dep = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("clap", s2s_dep.module("clap"));
}

fn add_zimq(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const zimq_dep = b.dependency("zimq", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zimq", zimq_dep.module("zimq"));
}

fn add_s2s(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const s2s_dep = b.dependency("s2s", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("s2s", s2s_dep.module("s2s"));
}

fn add_raylib(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib_artifact = raylib_dep.artifact("raylib");

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib_dep.module("raylib"));
    exe.root_module.addImport("raygui", raylib_dep.module("raygui"));
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
        .link_libcpp = true,
    };

    switch (optimize) {
        .Debug => {},
        .ReleaseSafe => {},
        else => {
            options.strip = true;
            options.error_tracing = false;
            options.pic = true;
        },
    }

    return options;
}

fn add_exe(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
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

    return exe;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = add_exe(b, target, optimize);

    add_raylib(b, exe);
    add_s2s(b, exe);
    add_clap(b, exe);
    add_zimq(b, exe);

    b.installArtifact(exe);

    add_run_step(b, exe);
}
