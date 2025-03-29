const std = @import("std");

fn build_gns(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void // *std.Build.Module
{
    const gns_dep = b.dependency("gns", .{
        .target = target,
        .optimize = optimize,
    });

    const gns_src_path = gns_dep.path("");

    std.debug.print("gns_src_path: {s}\n", .{gns_src_path.getPath(b)});

    const cmake = b.findProgram(&.{"cmake"}, &.{}) catch @panic("CMake not found");

    const cmake_build_type = switch (optimize) {
        .Debug => "-DCMAKE_BUILD_TYPE=Debug",
        .ReleaseSmall => "-DCMAKE_BUILD_TYPE=MinSizeRel",
        else => "-DCMAKE_BUILD_TYPE=Release",
    };

    const cmake_configure = b.addSystemCommand(&.{
        cmake,
        "-DBUILD_SHARED_LIBS=OFF",
        cmake_build_type,
        "-S",
    });
    cmake_configure.addDirectoryArg(gns_src_path);
    cmake_configure.addArg("-B");
    const gns_build_dir = cmake_configure.addOutputDirectoryArg("gns_build");

    const cmake_build = b.addSystemCommand(&.{ cmake, "--build" });
    cmake_build.addDirectoryArg(gns_build_dir);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "pong",
        .root_module = exe_mod,
    });

    // Deps start

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

    exe.linkLibC();

    const gns_lib = build_gns(b, target, optimize);
    _ = gns_lib;

    // Deps end

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
