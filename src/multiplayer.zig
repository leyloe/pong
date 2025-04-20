const std = @import("std");
const rl = @import("raylib");
const Ball = @import("Ball.zig");
const Paddle = @import("Paddle.zig");
const Score = @import("Score.zig");
const packet = @import("packet.zig");
const zimq = @import("zimq");

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
    var packets = std.ArrayList(packet.HostPacket).init(std.heap.page_allocator);
    defer packets.deinit();

    var mutex = std.Thread.Mutex{};

    var context = try zimq.Context.init();
    defer context.deinit();

    var socket = try zimq.Socket.init(context, .push);
    defer socket.deinit();

    const addr = try std.fmt.allocPrintZ(std.heap.page_allocator, "udp://{s}:{d}", .{ ip, port });
    try socket.connect(addr);

    try client_loop(socket, &packets, &mutex);

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
        if (mutex.tryLock()) {
            defer mutex.unlock();

            const msg = packets.pop();

            if (msg) |host_packet| {
                ball.position = host_packet.positions.ball;
                peer.position.y = host_packet.positions.paddle_y;
                score = host_packet.score;
            }
        }

        player.update(&ball, &screen);
        peer.update(&ball, &screen);

        // send the client packet
        var client_packet = packet.ClientPacket{
            .paddle_y = player.position.y,
        };
        try client_packet.serialize(buffer.writer());
        try socket.sendSlice(buffer.items, .{});

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
    var packets = std.ArrayList(packet.ClientPacket).init(std.heap.page_allocator);
    defer packets.deinit();

    var mutex = std.Thread.Mutex{};

    var context = try zimq.Context.init();
    defer context.deinit();

    var socket = try zimq.Socket.init(context, .pull);
    defer socket.deinit();

    const addr = try std.fmt.allocPrintZ(std.heap.page_allocator, "udp://0.0.0.0:{d}", .{port});
    try socket.bind(addr);

    try server_loop(socket, &packets, &mutex);

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
        if (mutex.tryLock()) {
            defer mutex.unlock();

            const msg = packets.pop();

            if (msg) |client_packet| {
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
        try socket.sendSlice(buffer.items, .{});

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
    socket: *zimq.Socket,
    packets: *std.ArrayList(packet.HostPacket),
    mutex: *std.Thread.Mutex,
) !void {
    while (true) {
        var buffer = zimq.Message.empty();
        defer buffer.deinit();
        _ = try socket.recvMsg(&buffer, .{});

        if (buffer.slice() == null) {
            continue;
        }

        var stream = std.io.fixedBufferStream(buffer.slice().?);
        const host_packet = packet.HostPacket.deserialize(stream.reader()) catch {
            continue;
        };

        mutex.lock();
        defer mutex.unlock();

        try packets.append(host_packet);
    }
}

pub fn server_loop(
    socket: *zimq.Socket,
    packets: *std.ArrayList(packet.ClientPacket),
    mutex: *std.Thread.Mutex,
) !void {
    while (true) {
        var buffer = zimq.Message.empty();
        defer buffer.deinit();
        _ = try socket.recvMsg(&buffer, .{});

        if (buffer.slice() == null) {
            continue;
        }

        var stream = std.io.fixedBufferStream(buffer.slice().?);
        const client_packet = packet.ClientPacket.deserialize(stream.reader()) catch {
            continue;
        };

        mutex.lock();
        defer mutex.unlock();

        try packets.append(client_packet);
    }
}
