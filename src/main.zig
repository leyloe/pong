const app = @import("app.zig");
const c = @cImport(@cInclude("steamtypes.h"));

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

pub fn main() void {
    const steam_call: c.steamtypes = undefined;
    _ = steam_call;

    var appInstance = app.App.init(screenWidth, screenHeight, targetFPS, windowTitle);
    defer appInstance.deinit();

    appInstance.run();
}
