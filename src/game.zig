pub const Game = union(enum) {
    const Self = @This();

    init: fn () Self,
    draw: fn (self: *Self) void,
    update: fn (self: *Self) void,
};
