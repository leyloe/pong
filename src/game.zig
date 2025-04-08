pub const Game = struct {
    const Self = @This();

    init: fn () Self,
    draw: fn (self: *Self) void,
    update: fn (self: *Self) void,
};
