const rl = @import("raylib");
const s2s = @import("s2s");

const Score = @import("Score.zig");

pub const HostPacket = struct {
    const Self = @This();

    positions: Positions,
    score: Score,

    pub fn serialize(self: *Self, stream: anytype) !void {
        try s2s.serialize(stream, Self, self.*);
    }

    pub fn deserialize(stream: anytype) !Self {
        return try s2s.deserialize(stream, Self);
    }
};

pub const ClientPacket = struct {
    const Self = @This();

    paddle_y: f32,

    pub fn serialize(self: *Self, stream: anytype) !void {
        try s2s.serialize(stream, Self, self.*);
    }

    pub fn deserialize(stream: anytype) !Self {
        return try s2s.deserialize(stream, Self);
    }
};

pub const Positions = struct {
    paddle_y: f32,
    ball: rl.Vector2,
};
