const rl = @import("raylib");
const s2s = @import("s2s");
const std = @import("std");

const Score = @import("Score.zig");

pub fn PacketMutex(comptime T: type) type {
    return struct {
        const Self = @This();

        mutex: std.Thread.Mutex,
        inner: ?T,

        pub fn init() Self {
            return Self{
                .inner = null,
                .mutex = .{},
            };
        }

        pub fn lock(self: *Self) void {
            self.mutex.lock();
        }

        pub fn unlock(self: *Self) void {
            self.mutex.unlock();
        }
    };
}

pub fn PacketQueueMutex(comptime T: type) type {
    return struct {
        const Self = @This();

        queue: std.ArrayList(T),
        mutex: std.Thread.Mutex,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .queue = std.ArrayList(T).init(allocator),
                .mutex = .{},
            };
        }

        pub fn deinit(self: *Self) void {
            self.queue.deinit();
        }
    };
}

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
