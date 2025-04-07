const net = @import("net.zig");
const game = @import("../game.zig");
const app = @import("../app.zig");

const rl = @import("raylib");

pub const Client = struct {
    const Self = @This();

    game: *game.Game,
};

pub const App = struct {
    const Self = @This();

    app: app.App,

    pub fn init(
        width: i32,
        height: i32,
        fps: i32,
        title: [:0]const u8,
    ) Self {
        const appInstance = app.App.init(width, height, fps, title);

        return Self{ .app = appInstance };
    }

    pub fn run(self: *Self) void {
        self.app.run();
    }

    pub fn deinit(self: *Self) void {
        defer self.app.deinit();
    }
};
