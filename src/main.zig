const game = @import("game.zig");

pub fn main() void {
    const interface = game.GameInterface{
        .game = game.Game.init(),
    };

    run_game(interface);
}

fn run_game(g: game.GameInterface) void {
    g.draw();
    g.update();
}
