const rl = @import("raylib");
const app = @import("app.zig");

pub const Map = struct {
    const Self = @This();

    app: *const app.App,
    line_start: rl.Vector2,
    line_end: rl.Vector2,

    pub fn init(appInstance: *const app.App) Self {
        return Self{
            .app = appInstance,
            .line_start = .{ .x = appInstance.screen.x / 2, .y = 0 },
            .line_end = .{ .x = appInstance.screen.x / 2, .y = appInstance.screen.y },
        };
    }

    pub fn draw(self: *Self) void {
        rl.drawLineV(self.line_start, self.line_end, .white);
    }
};
