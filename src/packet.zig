const rl = @import("raylib");
const s2s = @import("s2s");

const Score = @import("Score.zig");

pub const HostPacket = union(enum) {
    const Self = @This();

    Positions: Positions,
    Score: Score,

    pub fn serialize(self: Self) []const u8 {
        return s2s.serialize(TODO, Self, self);
    }
};

pub const ClientPacket = Positions;

pub const Positions = struct {
    paddle: ?rl.Vector2,
    ball: ?rl.Vector2,
};
