const rl = @import("raylib");
const s2s = @import("s2s");

const Score = @import("Score.zig");

pub const HostPacket = union(enum) {
    const Self = @This();

    Positions: Positions,
    Score: ?Score,

    pub fn serialize(self: *Self, stream: anytype) !void {
        try s2s.serialize(stream, Self, self);
    }

    pub fn deserialize(stream: anytype) !Self {
        return try s2s.deserialize(stream, Self);
    }
};

pub const ClientPacket = union(enum) {
    const Self = @This();

    Positions: Positions,

    pub fn serialize(self: *Self, stream: anytype) !void {
        try s2s.serialize(stream, Self, self);
    }

    pub fn deserialize(stream: anytype) !Self {
        return try s2s.deserialize(stream, Self);
    }
};

pub const Positions = struct {
    paddle: ?rl.Vector2,
    ball: ?rl.Vector2,
};
