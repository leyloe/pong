const rl = @import("raylib");

const Self = @This();

player: u32,
opponent: u32,

pub fn init() Self {
    return .{ .player = 0, .opponent = 0 };
}

pub fn draw(self: *Self, screenWidth: i32) void {
    rl.drawText(rl.textFormat("%i", .{self.opponent}), @divTrunc(screenWidth, 4) - 20, 20, 80, .white);
    rl.drawText(rl.textFormat("%i", .{self.player}), 3 * @divTrunc(screenWidth, 4) - 20, 20, 80, .white);
}

pub fn draw_flipped(self: *Self, screenWidth: i32) void {
    rl.drawText(rl.textFormat("%i", .{self.player}), @divTrunc(screenWidth, 4) - 20, 20, 80, .white);
    rl.drawText(rl.textFormat("%i", .{self.opponent}), 3 * @divTrunc(screenWidth, 4) - 20, 20, 80, .white);
}
