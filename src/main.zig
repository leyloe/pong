const app = @import("app.zig");

const std = @import("std");
const c = @cImport({
    @cInclude("enet.h");
});

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

pub fn main() void {
    if (c.enet_initialize() != 0) {
        std.debug.print("An error occurred while initializing ENet\n", .{});
        return;
    }
    defer c.enet_deinitialize();

    var appInstance = app.App.init(screenWidth, screenHeight, targetFPS, windowTitle);
    defer appInstance.deinit();

    appInstance.run();
}
