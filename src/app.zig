pub const App = union(enum) {
    const Self = @This();

    init: fn () Self,
    update: fn (self: *Self) void,
    render: fn (self: *Self) void,
    game_loop: fn (self: *Self) void,
};
