const app = @import("app.zig");
const net = @import("net.zig");

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

pub fn main() !void {
    var netInstance = net.Net.init();
    try netInstance.setup();
    defer netInstance.deinit();

    var appInstance = app.App.init(screenWidth, screenHeight, targetFPS, windowTitle);
    defer appInstance.deinit();

    appInstance.run();
}
