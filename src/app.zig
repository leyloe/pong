const game = @import("game.zig");

pub const App = struct {
    const Self = @This();

    init: fn (g: game.Game) Self,
    update: fn (self: *Self) void,
    render: fn (self: *Self) void,
    game_loop: fn (self: *Self) void,
};
