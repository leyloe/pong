const rl = @import("raylib");
const s2s = @import("s2s");

const Score = @import("Score.zig");

pub const HostPacket = union(enum) {
    const Self = @This();

    Positions: Positions,
    Score: Score,

    pub fn serialize(self: Self, stream: anytype) !void {
        try s2s.serialize(stream, Self, self);
    }

    pub fn deserialize(self: *Self, stream: anytype) !void {
        try s2s.deserialize(stream, Self, self);
    }
};

pub const ClientPacket = Positions;

pub const Positions = struct {
    paddle: ?rl.Vector2,
    ball: ?rl.Vector2,
};
