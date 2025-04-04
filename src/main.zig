const app = @import("app.zig");

const std = @import("std");
const clap = @import("clap");

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

pub fn singleplayer() void {
    var appInstance = app.App.init(screenWidth, screenHeight, targetFPS, windowTitle);
    defer appInstance.deinit();

    appInstance.run();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h,    --help              List of commands.
        \\-c,    --connect <str>     Connect to a game.
        \\-s,    --serve <u16>       Host a game on a specified port.
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});

    singleplayer();
}
