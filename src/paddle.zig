const rl = @import("raylib");
const app = @import("app.zig");

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

        if (self.position.y <= 0)
            self.position.y = 0;

        if (self.position.y + self.size.y >= self.app.screen.y)
            self.position.y = self.app.screen.y - self.size.y;
    }
};

pub const CpuPaddle = struct {
    const Self = @This();

    paddle: Paddle,
};
