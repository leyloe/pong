const rl = @import("raylib");
const app = @import("app.zig");
const ball = @import("ball.zig");
const paddle = @import("paddle.zig");

pub const Shapes = struct {
    const Self = @This();

    app: *app.App,
    ball: ball.Ball,
    player: paddle.Paddle,

    pub fn setup(self: *Self) void {
        self.ball = ball.Ball.init(self.app, self.app.center, 7, 20);
        self.player = paddle.Paddle.init(self.app.center, rl.Vector2{ .x = 50, .y = 50 }, 5);
    }

    pub fn draw(self: *Self) void {
        self.ball.draw();
        self.player.draw();
    }

    pub fn update(self: *Self) void {
        self.ball.update();
    }
};
