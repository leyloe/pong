const app = @import("app.zig");

const net = @import("net.zig");

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

pub fn main() !void {
    var appInstance = app.App.init(screenWidth, screenHeight, targetFPS, windowTitle);
    defer appInstance.deinit();

    var netInstance = try net.Net.init();

    defer netInstance.deinit();

    appInstance.run();
}
