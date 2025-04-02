const app = @import("app.zig");
const server = @import("server.zig");

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

pub fn main() !void {
    var serverInstance = server.Server.init(19999);
    defer serverInstance.deinit();

    try serverInstance.bind();

    var appInstance = app.App.init(screenWidth, screenHeight, targetFPS, windowTitle);
    defer appInstance.deinit();

    appInstance.run();
}
