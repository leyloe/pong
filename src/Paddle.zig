const rl = @import("raylib");
const Ball = @import("Ball.zig");

const Self = @This();

const Mode = enum {
    Player,
    Cpu,
    Peer,
};

position: rl.Vector2,
size: rl.Vector2,
speed: f32,
mode: Mode,

pub fn init(
    position: rl.Vector2,
    size: rl.Vector2,
    speed: f32,
    mode: Mode,
) Self {
    return .{
        .position = position,
        .size = size,
        .speed = speed,
        .mode = mode,
    };
}

pub fn draw(self: *Self) void {
    rl.drawRectangleV(self.position, self.size, .white);
}

pub fn update(self: *Self, ball: *Ball, screen: *const rl.Vector2) void {
    switch (self.mode) {
        Mode.Player => self.update_player(),
        Mode.Cpu => self.update_cpu(ball),
        Mode.Peer => {},
    }

    self.limit_movement(screen);
    self.handle_collision(ball);
}

fn update_player(self: *Self) void {
    if (rl.isKeyDown(.up))
        self.position.y -= self.speed;

    if (rl.isKeyDown(.down))
        self.position.y += self.speed;
}

fn update_cpu(self: *Self, ball: *Ball) void {
    if ((self.position.y + self.size.y / 2) > (ball.position.y))
        self.position.y -= self.speed;

    if ((self.position.y + self.size.y / 2) <= (ball.position.y))
        self.position.y += self.speed;
}

fn limit_movement(self: *Self, screen: *const rl.Vector2) void {
    if (self.position.y <= 0)
        self.position.y = 0;

    if (self.position.y + self.size.y >= screen.y)
        self.position.y = screen.y - self.size.y;
}

fn handle_collision(self: *Self, ball: *Ball) void {
    if (rl.checkCollisionCircleRec(ball.position, ball.radius, rl.Rectangle{ .x = self.position.x, .y = self.position.y, .width = self.size.x, .height = self.size.y }))
        ball.speed.x *= -1;
}
