const rl = @import("raylib");
const Score = @import("Score.zig");

const Self = @This();

position: rl.Vector2,
speed: rl.Vector2,
radius: f32,

pub fn init(
    position: rl.Vector2,
    speed: f32,
    radius: f32,
) Self {
    return .{
        .position = position,
        .radius = radius,
        .speed = rl.Vector2{ .x = speed, .y = speed },
    };
}

pub fn draw(self: *Self) void {
    rl.drawCircleV(self.position, self.radius, .white);
}

pub fn update(self: *Self, screen: *const rl.Vector2, center: *const rl.Vector2, score: *Score) void {
    self.position = self.position.add(self.speed);

    if ((self.position.y + self.radius >= screen.y) or (self.position.y - self.radius <= 0))
        self.speed.y *= -1;

    if (self.position.x + self.radius >= screen.x) {
        score.opponent += 1;
        self.reset_ball(center);
    }

    if (self.position.x - self.radius <= 0) {
        score.player += 1;
        self.reset_ball(center);
    }
}

fn reset_ball(self: *Self, center_pos: *const rl.Vector2) void {
    self.position = center_pos.*;

    const speed_choices = [_]f32{ -1, 1 };
    self.speed.x *= speed_choices[@intCast(rl.getRandomValue(0, 1))];
    self.speed.y *= speed_choices[@intCast(rl.getRandomValue(0, 1))];
}
