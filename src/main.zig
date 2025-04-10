const std = @import("std");
const rl = @import("raylib");
const clap = @import("clap");

const Ball = @import("Ball.zig");
const Paddle = @import("Paddle.zig");
const Score = @import("Score.zig");
const NetClient = @import("NetClient.zig");

const GameMode = enum {
    Singleplayer,
    Host,
    Client,
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

fn parse_connect_arg(arg: []const u8, allocator: std.mem.Allocator) !struct { ip: [:0]const u8, port: u16 } {
    var parts = std.mem.splitSequence(u8, arg, ":");

    var buffer = std.ArrayList([]const u8).init(allocator);
    defer buffer.deinit();

    while (parts.next()) |part| {
        try buffer.append(part);
    }

    if (buffer.items.len != 2) {
        return error.InvalidArgument;
    }

    const port = try std.fmt.parseInt(u16, buffer.items[1], 10);
    const address = try std.fmt.allocPrintZ(allocator, "{s}", .{buffer.items[0]});

    return .{ .ip = address, .port = port };
}

pub fn connect_to_host(ip: [:0]const u8, port: u16) !void {
    var client = try NetClient.init(ip, port);
    defer client.deinit();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h,    --help                   List all commands
        \\-c,    --connect <str>    Address:Port
        \\-s,    --serve <u16>            Port
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
        const connect = parse_connect_arg(arg, gpa.allocator()) catch |err| {
            std.debug.print("Invalid address format, run with --help for more information\n", .{});
            return err;
        };

        try connect_to_host(connect.ip, connect.port);
    }

    _ = Ball.init(center, 7, 20);
    _ = Paddle.init(player_position, player_size, 7, .Player);
    _ = Score.init();

    rl.initWindow(screenWidth, screenHeight, windowTitle);
    defer rl.closeWindow();

    rl.setTargetFPS(targetFPS);
}
