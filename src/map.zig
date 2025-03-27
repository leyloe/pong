const rl = @import("raylib");
const app = @import("app.zig");

pub const Map = struct {
    const Self = @This();

    app: *app.App,
    line_start: rl.Vector2,
    line_end: rl.Vector2,

    pub fn init(a: *app.App) Self {
        return Self{
            .app = a,
            .line_start = .{ .x = a.screen.x / 2, .y = 0 },
            .line_end = .{ .x = a.screen.x / 2, .y = a.screen.y },
        };
    }

    pub fn draw(self: *Self) void {
        rl.drawLineV(self.line_start, self.line_end, .white);
    }
};
