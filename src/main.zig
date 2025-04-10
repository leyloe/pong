const std = @import("std");
const rl = @import("raylib");
const clap = @import("clap");

const Ball = @import("Ball.zig");
const Paddle = @import("Paddle.zig");
const Score = @import("Score.zig");
const NetClient = @import("NetClient.zig");
const NetServer = @import("NetServer.zig");
const packet = @import("packet.zig");

const en = @cImport({
    @cInclude("enet.h");
});

const Address = struct {
    ip: [:0]const u8,
    port: u16,
};

const AppMode = union(enum) {
    Singleplayer,
    Host: u16,
    Client: Address,
};

const screenWidth = 1280;
const screenHeight = 800;
const targetFPS = 60;
const windowTitle = "Pong";

const screen = rl.Vector2{
    .x = @as(f32, @floatFromInt(screenWidth)),
    .y = @as(f32, @floatFromInt(screenHeight)),
};

const center = rl.Vector2{
    .x = screen.x / 2,
    .y = screen.y / 2,
};

const player_size = rl.Vector2{ .x = 25, .y = 120 };
const player_position = rl.Vector2{ .x = screen.x - player_size.x - 10, .y = center.y - player_size.y / 2 };

fn parse_connect_arg(arg: []const u8, allocator: std.mem.Allocator) !Address {
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
    const address = try std.fmt.allocPrintZ(allocator, "{s}", .{buffer.items[0]});

    return .{ .ip = address, .port = port };
}

pub fn connect_to_host(ip: [:0]const u8, port: u16) !void {
    var client = try NetClient.init(ip, port);
    defer client.deinit();

    const peer_size = player_size;
    const peer_position = rl.Vector2{ .x = 10, .y = screen.y / 2 - peer_size.y - 2 };

    var ball = Ball.init(center, 7, 20);
    var player = Paddle.init(player_position, player_size, 7, .Player);
    var peer = Paddle.init(peer_position, peer_size, 7, .Peer);
    var score = Score.init();

    rl.initWindow(screenWidth, screenHeight, windowTitle);
    defer rl.closeWindow();

    rl.setTargetFPS(targetFPS);

    var buffer = std.ArrayList(u8).init(std.heap.page_allocator);

    while (!rl.windowShouldClose()) {
        defer buffer.clearRetainingCapacity();

        // receive the server packet
        var event: en.ENetEvent = undefined;
        try client.poll(&event);
        switch (event.type) {
            en.ENET_EVENT_TYPE_RECEIVE => {
                const slice = event.packet.*.data[0..event.packet.*.dataLength];
                var stream = std.io.fixedBufferStream(slice);
                const server_packet = try packet.HostPacket.deserialize(stream.reader());

                peer.position.y = server_packet.positions.paddle_y;
                ball.position = server_packet.positions.ball;
                score = server_packet.score;

                en.enet_packet_destroy(event.packet);
            },
            else => {},
        }

        player.update(&ball, &screen);
        peer.update(&ball, &screen);

        // send the client packet
        var obj = packet.ClientPacket{
            .paddle_y = player.position.y,
        };
        try obj.serialize(buffer.writer());
        const client_packet = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}", .{buffer.items});
        try client.send(client_packet, client_packet.len);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        ball.draw();
        player.draw();
        peer.draw();
        score.draw(screenWidth);
    }
}

pub fn create_host(port: u16) !void {
    var server = try NetServer.init(port);
    defer server.deinit();

    var client_peer: [*c]en.ENetPeer = undefined;
    while (true) {
        var event: en.ENetEvent = undefined;
        try server.poll_timeout(&event, 1000);

        switch (event.type) {
            en.ENET_EVENT_TYPE_CONNECT => {
                client_peer = event.peer;
                break;
            },
            else => {},
        }
    }

    const peer_size = player_size;
    const peer_position = rl.Vector2{ .x = 10, .y = screen.y / 2 - peer_size.y - 2 };

    var ball = Ball.init(center, 7, 20);
    var player = Paddle.init(player_position, player_size, 7, .Player);
    var peer = Paddle.init(peer_position, peer_size, 7, .Peer);
    var score = Score.init();

    rl.initWindow(screenWidth, screenHeight, windowTitle);
    defer rl.closeWindow();

    rl.setTargetFPS(targetFPS);

    var buffer = std.ArrayList(u8).init(std.heap.page_allocator);

    while (!rl.windowShouldClose()) {
        defer buffer.clearRetainingCapacity();

        // receive the client packet
        var event: en.ENetEvent = undefined;
        try server.poll(&event);
        switch (event.type) {
            en.ENET_EVENT_TYPE_RECEIVE => {
                const slice = event.packet.*.data[0..event.packet.*.dataLength];
                var stream = std.io.fixedBufferStream(slice);
                const client_packet = try packet.ClientPacket.deserialize(stream.reader());

                peer.position.y = client_packet.paddle_y;

                en.enet_packet_destroy(event.packet);
            },
            else => {},
        }

        ball.update(&screen, &center, &score);
        player.update(&ball, &screen);
        peer.update(&ball, &screen);

        // send the server packet
        var obj = packet.HostPacket{
            .positions = packet.Positions{
                .paddle_y = player.position.y,
                .ball = ball.position,
            },
            .score = score,
        };
        try obj.serialize(buffer.writer());
        const server_packet = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}", .{buffer.items});
        try server.send(client_peer, server_packet, server_packet.len);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        ball.draw();
        player.draw();
        peer.draw();
        score.draw(screenWidth);
    }
}

pub fn singleplayer() void {
    const cpu_size = player_size;
    const cpu_position = rl.Vector2{ .x = 10, .y = screen.y / 2 - cpu_size.y - 2 };

    var ball = Ball.init(center, 7, 20);
    var player = Paddle.init(player_position, player_size, 7, .Player);
    var cpu = Paddle.init(cpu_position, cpu_size, 6, .Cpu);
    var score = Score.init();

    rl.initWindow(screenWidth, screenHeight, windowTitle);
    defer rl.closeWindow();

    rl.setTargetFPS(targetFPS);

    while (!rl.windowShouldClose()) {
        ball.update(&screen, &center, &score);
        player.update(&ball, &screen);
        cpu.update(&ball, &screen);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        ball.draw();
        player.draw();
        cpu.draw();
        score.draw(screenWidth);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var app_mode: AppMode = .Singleplayer;

    const params = comptime clap.parseParamsComptime(
        \\-h,    --help             List all commands
        \\-c,    --connect <str>    Address:Port
        \\-s,    --serve <u16>      Port
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});

    if (res.args.connect) |arg| {
        const addr = parse_connect_arg(arg, gpa.allocator()) catch |err| {
            std.debug.print("Invalid address format, run with --help for more information\n", .{});
            return err;
        };

        app_mode = .{ .Client = addr };
    }

    if (res.args.serve) |port|
        app_mode = .{ .Host = port };

    switch (app_mode) {
        .Host => |port| {
            try create_host(port);
        },
        .Client => |client| {
            try connect_to_host(client.ip, client.port);
        },
        .Singleplayer => {
            singleplayer();
        },
    }
}
