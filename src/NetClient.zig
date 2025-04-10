const en = @cImport({
    @cInclude("enet.h");
});

pub const ClientError = error{
    InitFailure,
    ClientNull,
    SetHostFailure,
    PeerNull,
    ConnectionFailure,
    PacketCreationFailure,
    PacketSendFailure,
    PollFailure,
};

const Self = @This();

host: [*c]en.ENetHost,
address: en.ENetAddress,
peer: [*c]en.ENetPeer,

pub fn init(ip: [*c]const u8, port: u16) ClientError!Self {
    var self: Self = undefined;

    if (en.enet_initialize() != en.EXIT_SUCCESS) {
        return ClientError.InitFailure;
    }

    self.host = en.enet_host_create(null, 1, 1, 0, 0);
    if (self.host == null) {
        return ClientError.ClientNull;
    }

    if (en.enet_address_set_host(&self.address, ip) != en.EXIT_SUCCESS) {
        return ClientError.SetHostFailure;
    }
    self.address.port = port;

    self.peer = en.enet_host_connect(self.host, &self.address, 1, 0);
    if (self.peer == null) {
        return ClientError.PeerNull;
    }

    var event: en.ENetEvent = undefined;
    if (!(en.enet_host_service(self.host, &event, 5000) > 0 and event.type == en.ENET_EVENT_TYPE_CONNECT)) {
        en.enet_peer_reset(self.peer);
        return ClientError.ConnectionFailure;
    }

    return self;
}

pub fn send(self: *Self, data: ?*const anyopaque, length: usize) ClientError!void {
    const packet = en.enet_packet_create(data, length, en.ENET_PACKET_FLAG_RELIABLE);
    defer en.enet_packet_destroy(packet);
    if (packet == null) {
        return ClientError.PacketCreationFailure;
    }

    if (en.enet_peer_send(self.peer, 0, packet) < 0) {
        return ClientError.PacketSendFailure;
    }
}

pub fn poll(self: *Self, event: [*c]en.ENetEvent) !void {
    if (en.enet_host_service(self.host, event, 0) < 0) {
        return ClientError.PollFailure;
    }
}

pub fn poll_timeout(self: *Self, event: [*c]en.ENetEvent, timeout: u32) !void {
    if (en.enet_host_service(self.host, event, timeout) < 0) {
        return ClientError.PollFailure;
    }
}

pub fn deinit(self: Self) void {
    defer en.enet_deinitialize();
    defer en.enet_host_destroy(self.host);
    defer en.enet_peer_disconnect(self.peer, 0);
    defer {
        var event: en.ENetEvent = undefined;
        while (en.enet_host_service(self.host, &event, 3000) > 0) {
            switch (event.type) {
                en.ENET_EVENT_TYPE_RECEIVE => {
                    en.enet_packet_destroy(event.packet);
                    break;
                },
                else => {
                    break;
                },
            }
        }
    }
}
