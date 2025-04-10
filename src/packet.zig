const rl = @import("raylib");

const Score = @import("Score.zig");

pub const HostPacket = union(enum) {
    Positions: Positions,
    Score: Score,
};

pub const ClientPacket = Positions;

pub const Positions = struct {
    paddle: ?rl.Vector2,
    ball: ?rl.Vector2,
};
