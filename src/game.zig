pub const Game = struct {
    const Self = @This();

    draw: fn () void,
    update: fn () void,
};
