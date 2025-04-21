const std = @import("std");

const HEADER_SIZE = 4;

pub fn Frame(comptime S: type) type {
    return struct {
        const Self = @This();

        inner: S,

        pub fn init(stream: S) Self {
            return Self{ .inner = stream };
        }

        pub fn writePacket(self: *Self, allocator: std.mem.Allocator, buffer: []const u8) !void {
            const len: u32 = @intCast(buffer.len);
            var len_bytes: [HEADER_SIZE]u8 = undefined;

            std.mem.writeInt(u32, &len_bytes, len, .big);

            var buf = try allocator.alloc(u8, buffer.len + HEADER_SIZE);
            defer allocator.free(buf);

            @memcpy(buf[0..HEADER_SIZE], len_bytes[0..HEADER_SIZE]);
            @memcpy(buf[HEADER_SIZE..], buffer);

            try self.inner.writeAll(buf);
        }

        pub fn readPacket(self: *Self, allocator: std.mem.Allocator) ![]u8 {
            var len: [4]u8 = undefined;

            var bytes_read = try self.inner.readAll(len[0..HEADER_SIZE]);
            if (bytes_read != HEADER_SIZE) {
                return error.ReadError;
            }

            const packet_len = std.mem.readInt(u32, &len, .big);

            var buf = try allocator.alloc(u8, packet_len);

            bytes_read = try self.inner.readAll(buf[0..packet_len]);
            if (bytes_read != packet_len) {
                return error.ReadError;
            }

            return buf;
        }
    };
}
