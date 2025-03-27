const app = @import("app.zig");

const screenWidth = 800;
const screenHeight = 450;
const targetFPS = 60;
const windowTitle = "Raylib app";

pub fn main() void {
    var a = app.App.init(screenWidth, screenHeight, targetFPS, windowTitle);
    defer a.deinit();
}
