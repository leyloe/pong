const rl = @import("raylib");
const app = @import("app.zig");

pub const Ball = struct {
    const Self = @This();

    position: rl.Vector2,
    speed: rl.Vector2,
    radius: f32,
    app: *app.App,

    pub fn init(a: *app.App, position: rl.Vector2, speed: f32, radius: f32) Self {
        return Self{
            .app = a,
            .position = position,
            .radius = radius,
            .speed = rl.Vector2{ .x = speed, .y = speed },
        };
    }

    pub fn draw(self: *Self) void {
        rl.drawCircleV(self.position, self.radius, .white);
    }

    pub fn update(self: *Self) void {
        self.position = self.position.add(self.speed);

        if ((self.position.y + self.radius >= self.app.screen.y) or (self.position.y - self.radius <= 0))
            self.speed.y *= -1;

        if ((self.position.x + self.radius >= self.app.screen.x) or (self.position.x - self.radius <= 0))
            self.speed.x *= -1;
    }
};
