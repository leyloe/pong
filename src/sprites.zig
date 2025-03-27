const rl = @import("raylib");
const app = @import("app.zig");
const ball = @import("ball.zig");

pub const Sprites = struct {
    const Self = @This();

    app: *app.App,
    ball: ball.Ball,

    pub fn setup(self: *Self) void {
        self.ball = .{
            .app = self.app,
            .position = self.app.center,
            .radius = 20.0,
            .speed = rl.Vector2{ .x = 7.0, .y = 7.0 },
        };
    }

    pub fn draw(self: *Self) void {
        self.ball.draw();
    }

    pub fn update(self: *Self) void {
        self.ball.update();
    }
};
