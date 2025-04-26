const std = @import("std");
const frame = @import("frame.zig");

pub const Server = struct {
    const Self = @This();

    frame: frame.Frame(std.net.Stream),
    server: std.net.Server,

    pub fn init(
        port: u16,
        allocator: std.mem.Allocator,
    ) !Self {
        const loopback = try std.net.Ip4Address.parse("0.0.0.0", port);

        const localhost = std.net.Address{
            .in = loopback,
        };

        var server = try localhost.listen(.{
            .reuse_address = true,
        });

        const connection = try server.accept();

        return .{
            .server = server,
            .frame = try frame.Frame(std.net.Stream).init(connection.stream, allocator),
        };
    }

    pub fn send(self: *Self, buffer: []const u8) !void {
        try self.frame.writePacket(buffer);
    }

    pub fn receive(self: *Self) ![]u8 {
        return try self.frame.readPacket();
    }

    pub fn deinit(self: *Self) void {
        defer self.server.deinit();
        defer self.frame.deinit();
    }
};

pub const Client = struct {
    const Self = @This();

    stream: std.net.Stream,
    frame: frame.Frame(std.net.Stream),

    pub fn init(
        ip: []const u8,
        port: u16,
        allocator: std.mem.Allocator,
    ) !Self {
        const peer = try std.net.Address.parseIp4(ip, port);

        const stream = try std.net.tcpConnectToAddress(peer);

        return .{
            .stream = stream,
            .frame = try frame.Frame(std.net.Stream).init(stream, allocator),
        };
    }

    pub fn send(self: *Self, buffer: []const u8) !void {
        try self.frame.writePacket(buffer);
    }

    pub fn receive(self: *Self) ![]u8 {
        return try self.frame.readPacket();
    }

    pub fn deinit(self: *Self) void {
        defer self.stream.close();
        defer self.frame.deinit();
    }
};
