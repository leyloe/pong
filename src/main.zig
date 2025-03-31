const app = @import("app.zig");
const client = @import("client.zig");

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

pub fn main() !void {
    var clientInstance = client.Client.init("127.0.0.1", 13333);
    defer clientInstance.deinit();

    try clientInstance.setup();

    var appInstance = app.App.init(screenWidth, screenHeight, targetFPS, windowTitle);
    defer appInstance.deinit();

    appInstance.run();
}
