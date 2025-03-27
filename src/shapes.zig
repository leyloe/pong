const rl = @import("raylib");
const app = @import("app.zig");
const ball = @import("ball.zig");

pub const Shapes = struct {
    const Self = @This();

    app: *app.App,
    ball: ball.Ball,

    pub fn setup(self: *Self) void {
        self.ball = ball.Ball.init(self.app, self.app.center, 7, 20);
    }

    pub fn draw(self: *Self) void {
        self.ball.draw();
    }

    pub fn update(self: *Self) void {
        self.ball.update();
    }
};
