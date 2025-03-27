const rl = @import("raylib");
const game = @import("game.zig");

pub const App = struct {
    const Self = @This();

    screenWidth: i32,
    screenHeight: i32,
    targetFPS: i32,
    screen: rl.Vector2,
    center: rl.Vector2,
    windowTitle: [:0]const u8,
    game: game.Game,

    pub fn init(
        width: i32,
        height: i32,
        fps: i32,
        title: [:0]const u8,
    ) Self {
        const screen = rl.Vector2{
            .x = @as(f32, @floatFromInt(width)),
            .y = @as(f32, @floatFromInt(height)),
        };

        const self = Self{
            .screenWidth = width,
            .screenHeight = height,
            .targetFPS = fps,
            .screen = screen,
            .center = rl.Vector2{
                .x = screen.x / 2.0,
                .y = screen.y / 2.0,
            },
            .windowTitle = title,
            .game = undefined,
        };

        return self;
    }

    pub fn run(self: *Self) void {
        self.setup();
        self.game_loop();
    }

    fn setup(self: *Self) void {
        self.game.app = self;
        self.game.setup();

        rl.initWindow(self.screenWidth, self.screenHeight, self.windowTitle);
        rl.setTargetFPS(self.targetFPS);
    }

    fn update(self: *Self) void {
        self.game.update();
    }

    fn render(self: *Self) void {
        rl.clearBackground(.black);
        self.game.draw();
    }

    fn game_loop(self: *Self) void {
        while (!rl.windowShouldClose()) {
            self.update();

            rl.beginDrawing();
            defer rl.endDrawing();

            self.render();
        }
    }

    pub fn deinit(self: *Self) void {
        _ = self;
        defer rl.closeWindow();
    }
};
