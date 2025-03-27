const rl = @import("raylib");
const app = @import("app.zig");

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
};
