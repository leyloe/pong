const rl = @import("raylib");
const app = @import("app.zig");
const ball = @import("ball.zig");
const paddle = @import("paddle.zig");
const score = @import("score.zig");
const map = @import("map.zig");

pub const Game = struct {
    const Self = @This();

    app: *const app.App,
    ball: ball.Ball,
    player: paddle.Paddle,
    cpu: paddle.CpuPaddle,
    score: score.Score,
    map: map.Map,

    pub fn setup(self: *Self) void {
        const player_size = rl.Vector2{ .x = 25, .y = 120 };
        const player_position = rl.Vector2{ .x = self.app.screen.x - player_size.x - 10, .y = self.app.center.y - player_size.y / 2 };

        const cpu_size = player_size;
        const cpu_position = rl.Vector2{ .x = 10, .y = self.app.screen.y / 2 - cpu_size.y - 2 };

        self.ball = ball.Ball.init(self.app, self.app.center, 7, 20);
        self.player = paddle.Paddle.init(self.app, player_position, player_size, 6);
        self.cpu = paddle.CpuPaddle.init(self.app, cpu_position, cpu_size, 6);
        self.score = score.Score.init(self.app);
        self.map = map.Map.init(self.app);
    }

    pub fn draw(self: *Self) void {
        self.map.draw();
        self.ball.draw();
        self.player.draw();
        self.cpu.draw();
        self.score.draw();
    }

    pub fn update(self: *Self) void {
        self.ball.update(self);
        self.player.update(self);
        self.cpu.update(self);
    }
};
