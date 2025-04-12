const std = @import("std");
const rl = @import("raylib");
const Ball = @import("Ball.zig");
const Paddle = @import("Paddle.zig");
const Score = @import("Score.zig");
const packet = @import("packet.zig");
const Socket = @import("Socket.zig");
const Frame = @import("Frame.zig");

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
    const addr = try std.net.Address.parseIp(ip, port);
    var sock = try Socket.init(addr);
    defer sock.deinit();

    try sock.connect();

    var frame = Frame.init(sock);

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
        const server_packet = try frame.readDeserialize(packet.HostPacket, std.heap.page_allocator);
        ball.position = server_packet.positions.ball;
        peer.position.y = server_packet.positions.paddle_y;
        score = server_packet.score;

        player.update(&ball, &screen);
        peer.update(&ball, &screen);

        // send the client packet
        const client_packet = packet.ClientPacket{
            .paddle_y = player.position.y,
        };
        try frame.writeSerialize(packet.ClientPacket, client_packet, std.heap.page_allocator);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        ball.draw();
        player.draw();
        peer.draw();
        score.draw(screenWidth);
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
    const addr = try std.net.Address.parseIp("0.0.0.0", port);
    var sock = try Socket.init(addr);
    defer sock.deinit();

    try sock.bind();

    var frame = Frame.init(sock);

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
        const client_packet = try frame.readDeserialize(packet.ClientPacket, std.heap.page_allocator);
        peer.position.y = client_packet.paddle_y;

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
        try frame.writeSerialize(packet.HostPacket, server_packet, std.heap.page_allocator);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        ball.draw();
        player.draw();
        peer.draw();
        score.draw(screenWidth);
    }
}
