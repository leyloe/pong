const rl = @import("raylib");
const Ball = @import("Ball.zig");

pub const Paddle = struct {
    const Self = @This();

    position: rl.Vector2,
    size: rl.Vector2,
    speed: f32,

    pub fn init(
        position: rl.Vector2,
        size: rl.Vector2,
        speed: f32,
    ) Self {
        return Self{ .position = position, .size = size, .speed = speed };
    }

    pub fn draw(self: *Self) void {
        rl.drawRectangleV(self.position, self.size, .white);
    }

    pub fn update(self: *Self, ball: *Ball) void {
        if (rl.isKeyDown(.up))
            self.position.y -= self.speed;

        if (rl.isKeyDown(.down))
            self.position.y += self.speed;

        self.limit_movement();
        self.handle_collision(ball);
    }

    fn limit_movement(self: *Self) void {
        if (self.position.y <= 0)
            self.position.y = 0;

        if (self.position.y + self.size.y >= self.app.screen.y)
            self.position.y = self.app.screen.y - self.size.y;
    }

    fn handle_collision(self: *Self, ball: *Ball) void {
        if (rl.checkCollisionCircleRec(ball.position, ball.radius, rl.Rectangle{ .x = self.position.x, .y = self.position.y, .width = self.size.x, .height = self.size.y }))
            ball.speed.x *= -1;
    }
};

pub const CpuPaddle = struct {
    const Self = @This();

    paddle: Paddle,

    pub fn init(
        position: rl.Vector2,
        size: rl.Vector2,
        speed: f32,
    ) Self {
        return Self{ .paddle = Paddle.init(position, size, speed) };
    }

    pub fn draw(self: *Self) void {
        self.paddle.draw();
    }

    pub fn update(self: *Self, ball: *Ball) void {
        if ((self.paddle.position.y + self.paddle.size.y / 2) > (ball.position.y))
            self.paddle.position.y -= self.paddle.speed;

        if ((self.paddle.position.y + self.paddle.size.y / 2) <= (ball.position.y))
            self.paddle.position.y += self.paddle.speed;

        self.paddle.limit_movement();
        self.paddle.handle_collision(ball);
    }
};

pub const PeerPaddle = struct {
    const Self = @This();

    paddle: Paddle,

    pub fn init(
        position: rl.Vector2,
        size: rl.Vector2,
        speed: f32,
    ) Self {
        return Self{ .paddle = Paddle.init(position, size, speed) };
    }

    pub fn draw(self: *Self) void {
        self.paddle.draw();
    }

    pub fn update(self: *Self, ball: *Ball, new_pos: rl.Vector2) void {
        self.paddle.position = new_pos;

        self.paddle.limit_movement();
        self.paddle.handle_collision(ball);
    }
};
