const std = @import("std");

fn build_gns(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    exe: *std.Build.Step.Compile,
) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const gns_dep = b.dependency("gns", .{
        .target = target,
        .optimize = optimize,
    });

    const gns_src_path = gns_dep.path("");

    const cmake = b.findProgram(&.{"cmake"}, &.{}) catch @panic("CMake not found");

    const cmake_build_type = switch (optimize) {
        .Debug => "-DCMAKE_BUILD_TYPE=Debug",
        .ReleaseSmall => "-DCMAKE_BUILD_TYPE=MinSizeRel",
        else => "-DCMAKE_BUILD_TYPE=Release",
    };

    const gns_build_dir = try b.cache_root.join(arena.allocator(), &.{switch (optimize) {
        .Debug => "gns-debug",
        .ReleaseSmall => "gns-minsizerel",
        else => "gns-release",
    }});

    const cmake_configure = b.addSystemCommand(&.{
        cmake,
        "-DBUILD_SHARED_LIB=OFF",
        "-DBUILD_STATIC_LIB=ON",
        cmake_build_type,
        "-S",
        gns_src_path.getPath(b),
        "-B",
        gns_build_dir,
    });

    const cmake_build = b.addSystemCommand(&.{
        cmake,
        "--build",
        gns_build_dir,
    });
    cmake_build.step.dependOn(&cmake_configure.step);

    const gns_include_dir = try gns_src_path.join(arena.allocator(), "include");
    const gns_lib_path = b.pathJoin(&.{ gns_build_dir, "src" });

    const gnd_object_file_path = b.pathJoin(&.{ gns_lib_path, "libGameNetworkingSockets_s.a" });

    exe.addIncludePath(gns_include_dir);
    exe.addObjectFile(.{ .cwd_relative = gnd_object_file_path });

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

    try build_gns(b, target, optimize, exe);

    exe.linkLibC();
    exe.linkLibCpp();

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
