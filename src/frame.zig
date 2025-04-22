const std = @import("std");

const HEADER_SIZE = 4;

pub fn Frame(comptime S: type) type {
    return struct {
        const Self = @This();

        inner: S,
        buffer: std.ArrayList(u8),

        pub fn init(stream: S, allocator: std.mem.Allocator) !Self {
            return Self{
                .inner = stream,
                .buffer = std.ArrayList(u8).init(allocator),
            };
        }

        pub fn writePacket(self: *Self, buffer: []const u8) !void {
            const len: u32 = @intCast(buffer.len);
            var len_bytes: [HEADER_SIZE]u8 = undefined;

            std.mem.writeInt(u32, &len_bytes, len, .big);

            self.buffer.clearRetainingCapacity();
            try self.buffer.ensureTotalCapacityPrecise(HEADER_SIZE + buffer.len);

            self.buffer.appendSliceAssumeCapacity(len_bytes[0..HEADER_SIZE]);
            self.buffer.appendSliceAssumeCapacity(buffer[0..buffer.len]);

            try self.inner.writeAll(self.buffer.items);
        }

        pub fn readPacket(self: *Self) ![]u8 {
            var len: [4]u8 = undefined;

            var bytes_read = try self.inner.readAll(len[0..HEADER_SIZE]);
            if (bytes_read != HEADER_SIZE) {
                return error.ReadError;
            }

            const packet_len = std.mem.readInt(u32, &len, .big);

            try self.buffer.resize(packet_len);

            bytes_read = try self.inner.readAll(self.buffer.items[0..packet_len]);
            if (bytes_read != packet_len) {
                return error.ReadError;
            }

            return self.buffer.items[0..packet_len];
        }

        pub fn deinit(self: *Self) void {
            defer self.buffer.deinit();
        }
    };
}
