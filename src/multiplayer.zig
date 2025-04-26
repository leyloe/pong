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
    allocator: std.mem.Allocator,
) !void {
    var latest_packet = packet.PacketMutex(packet.HostPacket).init();

    var client = try net.Client.init(ip, port, allocator);
    defer client.deinit();

    var queued_packet = packet.PacketMutex(packet.ClientPacket).init();
    var old_packet: packet.ClientPacket = .{ .paddle_y = player_position.y };

    _ = try std.Thread.spawn(.{}, read_loop, .{
        packet.HostPacket,
        &client,
        &latest_packet,
    });

    _ = try std.Thread.spawn(.{}, write_loop, .{
        packet.ClientPacket,
        &client,
        &queued_packet,
        allocator,
    });

    const peer_size = player_size;
    const peer_position = rl.Vector2{ .x = 10, .y = screen.y / 2 - peer_size.y - 2 };

    var ball = Ball.init(center, 7, 20);
    var player = Paddle.init(player_position, player_size, 7, .Player);
    var peer = Paddle.init(peer_position, peer_size, 7, .Peer);
    var score = Score.init();

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    rl.initWindow(screenWidth, screenHeight, windowTitle);
    defer rl.closeWindow();

    rl.setTargetFPS(targetFPS);

    while (!rl.windowShouldClose()) {
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
        {
            if (client_packet.changed(&old_packet)) {
                queued_packet.mutex.lock();
                defer queued_packet.mutex.unlock();

                queued_packet.inner = client_packet;
                old_packet = client_packet;
            }
        }

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
    allocator: std.mem.Allocator,
) !void {
    var latest_packet = packet.PacketMutex(packet.ClientPacket).init();

    var server = try net.Server.init(port, allocator);
    defer server.deinit();

    var queued_packet = packet.PacketMutex(packet.HostPacket).init();

    _ =
        try std.Thread.spawn(.{}, read_loop, .{
            packet.ClientPacket,
            &server,
            &latest_packet,
        });

    _ = try std.Thread.spawn(.{}, write_loop, .{
        packet.HostPacket,
        &server,
        &queued_packet,
        allocator,
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

    while (!rl.windowShouldClose()) {
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
        const server_packet = packet.HostPacket{
            .positions = packet.Positions{
                .paddle_y = player.position.y,
                .ball = ball.position,
            },
            .score = score,
        };
        {
            queued_packet.mutex.lock();
            defer queued_packet.mutex.unlock();

            queued_packet.inner = server_packet;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        ball.draw();
        player.draw();
        peer.draw();
        score.draw(screenWidth);
    }
}

fn read_loop(
    comptime T: type,
    connection: anytype,
    latest_packet: *packet.PacketMutex(T),
) !void {
    while (true) {
        const buffer = try connection.receive();

        var stream = std.io.fixedBufferStream(buffer);
        const network_packet = T.deserialize(stream.reader()) catch {
            continue;
        };

        latest_packet.lock();
        defer latest_packet.unlock();

        latest_packet.inner = network_packet;
    }
}

fn write_loop(
    comptime T: type,
    connection: anytype,
    queued_packet: *packet.PacketMutex(T),
    allocator: std.mem.Allocator,
) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    while (true) {
        var network_packet: T = undefined;

        {
            queued_packet.mutex.lock();
            defer queued_packet.mutex.unlock();

            network_packet = queued_packet.inner orelse {
                continue;
            };

            queued_packet.inner = null;
        }

        buffer.clearRetainingCapacity();

        try network_packet.serialize(buffer.writer());
        try connection.send(buffer.items);
    }
}
