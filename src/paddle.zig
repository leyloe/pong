const rl = @import("raylib");
const app = @import("app.zig");
const ball = @import("ball.zig");

pub const Paddle = struct {
    const Self = @This();

    app: *app.App,
    position: rl.Vector2,
    size: rl.Vector2,
    speed: f32,

    pub fn init(
        a: *app.App,
        position: rl.Vector2,
        size: rl.Vector2,
        speed: f32,
    ) Self {
        return Self{ .app = a, .position = position, .size = size, .speed = speed };
    }

    pub fn draw(self: *Self) void {
        rl.drawRectangleV(self.position, self.size, .white);
    }

    pub fn update(self: *Self) void {
        if (rl.isKeyDown(.up))
            self.position.y -= self.speed;

        if (rl.isKeyDown(.down))
            self.position.y += self.speed;

        self.limit_movement();
    }

    fn limit_movement(self: *Self) void {
        if (self.position.y <= 0)
            self.position.y = 0;

        if (self.position.y + self.size.y >= self.app.screen.y)
            self.position.y = self.app.screen.y - self.size.y;
    }

    pub fn handle_collision(self: *Self, b: *ball.Ball) void {
        if (rl.checkCollisionCircleRec(b.position, b.radius, rl.Rectangle{ .x = self.position.x, .y = self.position.y, .width = self.size.x, .height = self.size.y }))
            b.speed.x *= -1;
    }
};

pub const CpuPaddle = struct {
    const Self = @This();

    paddle: Paddle,

    pub fn init(
        a: *app.App,
        position: rl.Vector2,
        size: rl.Vector2,
        speed: f32,
    ) Self {
        return Self{ .paddle = Paddle.init(a, position, size, speed) };
    }

    pub fn draw(self: *Self) void {
        self.paddle.draw();
    }

    pub fn update(self: *Self, ball_position: rl.Vector2) void {
        if ((self.paddle.position.y + self.paddle.size.y / 2) > (ball_position.y))
            self.paddle.position.y -= self.paddle.speed;

        if ((self.paddle.position.y + self.paddle.size.y / 2) <= (ball_position.y))
            self.paddle.position.y += self.paddle.speed;

        self.paddle.limit_movement();
    }

    pub fn handle_collision(self: *Self, b: *ball.Ball) void {
        self.paddle.handle_collision(b);
    }
};
