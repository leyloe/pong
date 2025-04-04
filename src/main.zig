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
        \\-h,    --help              List all commands
        \\-c,    --connect <str>     Address:Port
        \\-s,    --serve <u16>       Port
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

    if (res.args.connect) |a| {
        var parts = std.mem.splitSequence(u8, a, ":");

        var buffer = std.ArrayList([]const u8).init(gpa.allocator());
        defer buffer.deinit();

        while (parts.next()) |part| {
            try buffer.append(part);
        }

        if (buffer.items.len != 2) {
            std.debug.print("Invalid address format\n", .{});
            return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
        }

        return;
    }

    if (res.args.serve) |p| {
        std.debug.print("Server port: {}\n", .{p});
        return;
    }

    singleplayer();
}
