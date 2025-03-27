const rl = @import("raylib");
const app = @import("app.zig");

pub const Score = struct {
    const Self = @This();

    app: *app.App,
    player_score: u32,
    cpu_score: u32,

    pub fn init(a: *app.App) Self {
        return Self{ .app = a, .player_score = 0, .cpu_score = 0 };
    }

    pub fn draw(self: *Self) void {
        rl.drawText(rl.textFormat("%i", .{self.cpu_score}), @divTrunc(self.app.screenWidth, 4) - 20, 20, 80, .white);
        rl.drawText(rl.textFormat("%i", .{self.player_score}), 3 * @divTrunc(self.app.screenWidth, 4) - 20, 20, 80, .white);
    }
};
