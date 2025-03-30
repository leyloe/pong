const app = @import("app.zig");

const c = @cImport(@cInclude("steam/steamnetworkingsockets.h"));

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

pub fn main() void {
    c.GameNetworkingSockets_Kill();

    var appInstance = app.App.init(screenWidth, screenHeight, targetFPS, windowTitle);
    defer appInstance.deinit();

    appInstance.run();
}
