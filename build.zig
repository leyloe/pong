const std = @import("std");

fn build_gns(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    dependency: *std.Build.Dependency,
) !*std.Build.Module {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const gns_src_path = dependency.path("");

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

    const gns_include_dir = try gns_src_path.join(arena.allocator(), "include/steam");
    const gns_lib_path = b.pathJoin(&.{ gns_build_dir, "bin" });

    const gns = dependency.module("gns");

    const gnd_object_file_path = b.pathJoin(&.{ gns_lib_path, "libGameNetworkingSockets_s.a" });

    gns.addIncludePath(gns_include_dir);
    gns.addObjectFile(.{ .cwd_relative = gnd_object_file_path });

    return gns;
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

    exe.linkLibC();
    exe.linkLibCpp();

    const gns_dep = b.dependency("gns", .{
        .target = target,
        .optimize = optimize,
    });

    const gns = try build_gns(b, optimize, gns_dep);
    const gns_artifact = gns_dep.artifact("gns");

    exe.linkLibrary(gns_artifact);
    exe.root_module.addImport("gns", gns);

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
