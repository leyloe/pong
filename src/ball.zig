const rl = @import("raylib");
const app = @import("app.zig");
const game = @import("game.zig");

pub const Ball = struct {
    const Self = @This();

    app: *app.App,
    position: rl.Vector2,
    speed: rl.Vector2,
    radius: f32,

    pub fn init(
        appInstance: *app.App,
        position: rl.Vector2,
        speed: f32,
        radius: f32,
    ) Self {
        return Self{
            .app = appInstance,
            .position = position,
            .radius = radius,
            .speed = rl.Vector2{ .x = speed, .y = speed },
        };
    }

    pub fn draw(self: *Self) void {
        rl.drawCircleV(self.position, self.radius, .white);
    }

    pub fn update(self: *Self, gameInstance: *game.Game) void {
        self.position = self.position.add(self.speed);

        if ((self.position.y + self.radius >= self.app.screen.y) or (self.position.y - self.radius <= 0))
            self.speed.y *= -1;

        if (self.position.x + self.radius >= self.app.screen.x) {
            gameInstance.score.cpu_score += 1;
            self.reset_ball();
        }

        if (self.position.x - self.radius <= 0) {
            gameInstance.score.player_score += 1;
            self.reset_ball();
        }
    }

    fn reset_ball(self: *Self) void {
        self.position = self.app.center;

        const speed_choices = [_]f32{ -1, 1 };
        self.speed.x *= speed_choices[@intCast(rl.getRandomValue(0, 1))];
        self.speed.y *= speed_choices[@intCast(rl.getRandomValue(0, 1))];
    }
};
