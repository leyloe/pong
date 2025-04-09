const rl = @import("raylib");

const Self = @This();

player: u32,
opponent: u32,

pub fn init() Self {
    return Self{ .player_score = 0, .opponent_score = 0 };
}

pub fn draw(self: *Self, screenWidth: i32) void {
    rl.drawText(rl.textFormat("%i", .{self.cpu_score}), @divTrunc(screenWidth, 4) - 20, 20, 80, .white);
    rl.drawText(rl.textFormat("%i", .{self.player_score}), 3 * @divTrunc(screenWidth, 4) - 20, 20, 80, .white);
}
