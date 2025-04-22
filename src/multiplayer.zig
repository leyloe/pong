const std = @import("std");
const rl = @import("raylib");
const Ball = @import("Ball.zig");
const Paddle = @import("Paddle.zig");
const Score = @import("Score.zig");
const packet = @import("packet.zig");
const net = @import("net.zig");

pub fn connect_to_host(
    ip: []const u8,
    port: u16,
    player_size: rl.Vector2,
    player_position: rl.Vector2,
    screenWidth: i32,
    screenHeight: i32,
    screen: rl.Vector2,
    center: rl.Vector2,
    windowTitle: [:0]const u8,
    targetFPS: i32,
) !void {
    var latest_packet = packet.PacketMutex(packet.HostPacket).init();

    var client = try net.Client.init(ip, port);
    defer client.deinit();

    _ = try std.Thread.spawn(.{}, client_loop, .{
        &client,
        &latest_packet,
        std.heap.page_allocator,
    });

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
    defer buffer.deinit();

    while (!rl.windowShouldClose()) {
        defer buffer.clearRetainingCapacity();

        // receive the server packet
        {
            latest_packet.lock();
            defer latest_packet.unlock();

            if (latest_packet.inner) |host_packet| {
                defer latest_packet.inner = null;

                ball.position = host_packet.positions.ball;
                peer.position.y = host_packet.positions.paddle_y;
                score = host_packet.score;

                ball.position.x = screen.x - ball.position.x;
            }
        }

        player.update(&ball, &screen);
        peer.update(&ball, &screen);

        // send the client packet
        var client_packet = packet.ClientPacket{
            .paddle_y = player.position.y,
        };
        try client_packet.serialize(buffer.writer());
        try client.send(std.heap.page_allocator, buffer.items);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        ball.draw();
        player.draw();
        peer.draw();
        score.draw_flipped(screenWidth);
    }
}

pub fn create_host(
    port: u16,
    player_size: rl.Vector2,
    player_position: rl.Vector2,
    screenWidth: i32,
    screenHeight: i32,
    screen: rl.Vector2,
    center: rl.Vector2,
    windowTitle: [:0]const u8,
    targetFPS: i32,
) !void {
    var latest_packet = packet.PacketMutex(packet.ClientPacket).init();

    var server = try net.Server.init(port);
    defer server.deinit();

    _ =
        try std.Thread.spawn(.{}, server_loop, .{
            &server,
            &latest_packet,
            std.heap.page_allocator,
        });

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
    defer buffer.deinit();

    while (!rl.windowShouldClose()) {
        defer buffer.clearRetainingCapacity();

        // receive the client packet
        {
            latest_packet.lock();
            defer latest_packet.unlock();

            if (latest_packet.inner) |client_packet| {
                defer latest_packet.inner = null;
                peer.position.y = client_packet.paddle_y;
            }
        }

        ball.update(&screen, &center, &score);
        player.update(&ball, &screen);
        peer.update(&ball, &screen);

        // send the server packet
        var server_packet = packet.HostPacket{
            .positions = packet.Positions{
                .paddle_y = player.position.y,
                .ball = ball.position,
            },
            .score = score,
        };
        try server_packet.serialize(buffer.writer());
        try server.send(std.heap.page_allocator, buffer.items);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        ball.draw();
        player.draw();
        peer.draw();
        score.draw(screenWidth);
    }
}

pub fn client_loop(
    client: *net.Client,
    latest_packet: *packet.PacketMutex(packet.HostPacket),
    allocator: std.mem.Allocator,
) !void {
    while (true) {
        const buffer = try client.receive(allocator);
        defer allocator.free(buffer);

        var stream = std.io.fixedBufferStream(buffer);
        const host_packet = packet.HostPacket.deserialize(stream.reader()) catch {
            continue;
        };

        latest_packet.lock();
        defer latest_packet.unlock();

        latest_packet.inner = host_packet;
    }
}

pub fn server_loop(
    server: *net.Server,
    latest_packet: *packet.PacketMutex(packet.ClientPacket),
    allocator: std.mem.Allocator,
) !void {
    while (true) {
        const buffer = try server.receive(allocator);
        defer allocator.free(buffer);

        var stream = std.io.fixedBufferStream(buffer);
        const client_packet = packet.ClientPacket.deserialize(stream.reader()) catch {
            continue;
        };

        latest_packet.lock();
        defer latest_packet.unlock();

        latest_packet.inner = client_packet;
    }
}
