const std = @import("std");
const rl = @import("raylib");
const clap = @import("clap");
const util = @import("util.zig");
const multiplayer = @import("multiplayer.zig");
const singleplayer = @import("singleplayer.zig");

const AppMode = union(enum) {
    Singleplayer,
    Host: u16,
    Client: util.Address,
};

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

const screen = rl.Vector2{
    .x = @as(f32, @floatFromInt(screenWidth)),
    .y = @as(f32, @floatFromInt(screenHeight)),
};

const center = rl.Vector2{
    .x = screen.x / 2,
    .y = screen.y / 2,
};

const player_size = rl.Vector2{ .x = 25, .y = 120 };
const player_position = rl.Vector2{ .x = screen.x - player_size.x - 10, .y = center.y - player_size.y / 2 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var app_mode: AppMode = .Singleplayer;

    const params = comptime clap.parseParamsComptime(
        \\-h,    --help             List all commands
        \\-c,    --connect <str>    Address:Port
        \\-s,    --serve <u16>      Port
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});

    if (res.args.connect) |arg| {
        const addr = util.parse_connect_arg(arg, gpa.allocator()) catch |err| {
            std.debug.print("Invalid address format, run with --help for more information\n", .{});
            return err;
        };

        app_mode = .{ .Client = addr };
    }

    if (res.args.serve) |port|
        app_mode = .{ .Host = port };

    switch (app_mode) {
        .Host => |port| {
            try multiplayer.create_host(
                port,
                player_size,
                player_position,
                screenWidth,
                screenHeight,
                screen,
                center,
                windowTitle,
                targetFPS,
            );
        },
        .Client => |client| {
            try multiplayer.connect_to_host(
                client.ip,
                client.port,
                player_size,
                player_position,
                screenWidth,
                screenHeight,
                screen,
                center,
                windowTitle,
                targetFPS,
            );
        },
        .Singleplayer => {
            singleplayer.singleplayer(
                player_size,
                player_position,
                screenWidth,
                screenHeight,
                screen,
                center,
                windowTitle,
                targetFPS,
            );
        },
    }
}
