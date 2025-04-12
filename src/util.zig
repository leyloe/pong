const std = @import("std");

pub const Address = struct {
    ip: []const u8,
    port: u16,
};

pub fn parse_connect_arg(arg: []const u8, allocator: std.mem.Allocator) !Address {
    var parts = std.mem.splitSequence(u8, arg, ":");

    var buffer = std.ArrayList([]const u8).init(allocator);
    defer buffer.deinit();

    while (parts.next()) |part| {
        try buffer.append(part);
    }

    if (buffer.items.len != 2) {
        return error.InvalidArgument;
    }

    const port = try std.fmt.parseInt(u16, buffer.items[1], 10);

    return .{ .ip = buffer.items[0], .port = port };
}
