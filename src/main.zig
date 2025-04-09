const rl = @import("raylib");

const Ball = @import("Ball.zig");
const Paddle = @import("Paddle.zig");
const Score = @import("Score.zig");

pub fn main() void {
    const screenWidth = 1280;
    const screenHeight = 800;
    const targetFPS = 60;
    const windowTitle = "Pong";

    const screen = rl.Vector2{
        .x = @as(f32, @floatFromInt(screenWidth)),
        .y = @as(f32, @floatFromInt(screenHeight)),
    };

    const center = rl.Vector2{
        .x = screen.x / 2,
        .y = screen.y / 2,
    };

    const player_size = rl.Vector2{ .x = 25, .y = 120 };
    const player_position = rl.Vector2{ .x = screen.x - player_size.x - 10, .y = center.y - player_size.y / 2 };

    const ball = Ball.init(center, 7, 20);
    const player = Paddle.init(player_position, player_size, 7, Paddle.Mode.Player);
    const score = Score.init();

    rl.initWindow(screenWidth, screenHeight, windowTitle);
    defer rl.closeWindow();

    rl.setTargetFPS(targetFPS);
}
