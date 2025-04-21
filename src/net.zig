const std = @import("std");
const frame = @import("frame.zig");

pub const Server = struct {
    const Self = @This();

    frame: frame.Frame(std.net.Stream),
    server: std.net.Server,

    pub fn init(
        port: u16,
    ) !Self {
        const loopback = try std.net.Ip4Address.parse("0.0.0.0", port);

        const localhost = std.net.Address{
            .in = loopback,
        };

        const server = try localhost.listen(.{
            .reuse_address = true,
        });

        const connection = try server.accept();

        return Self{
            .frame = frame.Frame(std.net.Stream).init(connection.stream),
        };
    }

    pub fn send(self: *Self, allocator: std.mem.Allocator, buffer: []const u8) !void {
        try self.frame.writePacket(allocator, buffer);
    }

    pub fn receive(self: *Self, allocator: std.mem.Allocator) ![]u8 {
        return try self.frame.readPacket(allocator);
    }

    pub fn deinit(self: *Self) void {
        defer self.server.deinit();
    }
};

pub const Client = struct {
    const Self = @This();

    stream: std.net.Stream,
    frame: frame.Frame(std.net.Stream),

    pub fn init(
        ip: []const u8,
        port: u16,
    ) !Self {
        const peer = try std.net.Address.parseIp4(ip, port);

        const stream = try std.net.tcpConnectToAddress(peer);

        return Self{
            .frame = frame.Frame(std.net.Stream).init(stream),
        };
    }

    pub fn send(self: *Self, allocator: std.mem.Allocator, buffer: []const u8) !void {
        try self.frame.writePacket(allocator, buffer);
    }

    pub fn receive(self: *Self, allocator: std.mem.Allocator) ![]u8 {
        return try self.frame.readPacket(allocator);
    }

    pub fn deinit(self: *Self) void {
        self.stream.close();
    }
};
