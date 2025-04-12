const std = @import("std");
const network = @import("network");
const s2s = @import("s2s");

const Self = @This();

socket: network.Socket,

pub fn init(socket: network.Socket) Self {
    return Self{
        .socket = socket,
    };
}

pub fn writePacket(self: *Self, allocator: std.mem.Allocator, buffer: []const u8) !void {
    const len: u32 = @intCast(buffer.len);
    var len_bytes: [4]u8 = undefined;
    std.mem.writeInt(u32, &len_bytes, len, .big);

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    try buf.appendSlice(len_bytes[0..4]);
    try buf.appendSlice(buffer[0..buffer.len]);

    _ = try self.socket.writer().write(buf.items);
}

pub fn readPacket(self: *Self, allocator: std.mem.Allocator) !std.ArrayList(u8) {
    var buf = std.ArrayList(u8).init(allocator);

    var len: [4]u8 = undefined;

    _ = try self.socket.reader().read(len[0..4]);
    const packet_len = std.mem.readInt(u32, &len, .big);

    _ = try self.socket.reader().read(buf.items[0..packet_len]);

    return buf;
}

pub fn writeSerialize(self: *Self, comptime T: type, value: anytype, allocator: std.mem.Allocator) !void {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    try s2s.serialize(buf.writer(), T, value);

    try self.writePacket(allocator, buf.items);
}

pub fn readDeserialize(self: *Self, comptime T: type, allocator: std.mem.Allocator) !T {
    const buf = try self.readPacket(allocator);
    defer buf.deinit();
    var stream = std.io.fixedBufferStream(buf.items);
    return try s2s.deserialize(stream.reader(), T);
}
