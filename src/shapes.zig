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
        const player_size = rl.Vector2{ .x = 25, .y = 120 };
        const player_position = rl.Vector2{ .x = self.app.screen.x - player_size.x - 10, .y = self.app.center.y - player_size.y / 2 };

        self.ball = ball.Ball.init(self.app, self.app.center, 7, 20);
        self.player = paddle.Paddle.init(player_position, player_size, 6);
    }

    pub fn draw(self: *Self) void {
        self.ball.draw();
        self.player.draw();
    }

    pub fn update(self: *Self) void {
        self.ball.update();
    }
};
