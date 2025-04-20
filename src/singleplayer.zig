const rl = @import("raylib");

const Ball = @import("Ball.zig");
const Paddle = @import("Paddle.zig");
const Score = @import("Score.zig");

pub fn singleplayer(
    player_size: rl.Vector2,
    player_position: rl.Vector2,
    screenWidth: i32,
    screenHeight: i32,
    screen: rl.Vector2,
    center: rl.Vector2,
    windowTitle: [:0]const u8,
    targetFPS: i32,
) void {
    const cpu_size = player_size;
    const cpu_position = rl.Vector2{ .x = 10, .y = screen.y / 2 - cpu_size.y - 2 };

    var ball = Ball.init(center, 7, 20);
    var player = Paddle.init(player_position, player_size, 7, .Player);
    var cpu = Paddle.init(cpu_position, cpu_size, 6, .Cpu);
    var score = Score.init();

    rl.initWindow(screenWidth, screenHeight, windowTitle);
    defer rl.closeWindow();

    rl.setTargetFPS(targetFPS);

    while (!rl.windowShouldClose()) {
        ball.update(&screen, &center, &score);
        player.update(&ball, &screen);
        cpu.update(&ball, &screen);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        ball.draw();
        player.draw();
        cpu.draw();
        score.draw(screenWidth);
    }
}
