const net = @import("net.zig");
const game = @import("../game.zig");
const app = @import("../app.zig");

const rl = @import("raylib");

pub const Host = struct {
    const Self = @This();

    game: *game.Game,
};

pub const App = struct {
    const Self = @This();

    app: app.App,
};
