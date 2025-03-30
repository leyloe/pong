const std = @import("std");

fn build_enet(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    exe: *std.Build.Step.Compile,
) !void {
    const en_dep = b.dependency("en", .{
        .target = target,
        .optimize = optimize,
    });

    const en_src_path = en_dep.path("");

    const cmake = b.findProgram(&.{"cmake"}, &.{}) catch @panic("CMake not found");

    const cmake_build_type = switch (optimize) {
        .Debug => "-DCMAKE_BUILD_TYPE=Debug",
        .ReleaseSmall => "-DCMAKE_BUILD_TYPE=MinSizeRel",
        else => "-DCMAKE_BUILD_TYPE=Release",
    };

    const en_build_dir = b.pathJoin(&.{ b.cache_root.path.?, switch (optimize) {
        .Debug => "en-debug",
        .ReleaseSmall => "en-minsizerel",
        else => "en-release",
    } });

    const cmake_configure = b.addSystemCommand(&.{
        cmake,
        "-DENET_STATIC=1",
        cmake_build_type,
        "-S",
        en_src_path.getPath(b),
        "-B",
        en_build_dir,
    });

    const cmake_build = b.addSystemCommand(&.{
        cmake,
        "--build",
        en_build_dir,
    });
    cmake_build.step.dependOn(&cmake_configure.step);

    const en_include_dir = b.pathJoin(&.{ en_src_path.getPath(b), "include" });
    const en_lib_path = en_build_dir;

    exe.addIncludePath(.{ .cwd_relative = en_include_dir });
    exe.addLibraryPath(.{ .cwd_relative = en_lib_path });

    exe.linkSystemLibrary("enet");

    exe.step.dependOn(&cmake_build.step);
}

pub fn build(b: *std.Build) !void {
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

    try build_enet(b, target, optimize, exe);

    exe.linkLibC();

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
