const en = @cImport({
    @cInclude("enet.h");
});

pub const ClientError = error{
    InitFailure,
    ClientNull,
    SetHostFailure,
    PeerNull,
    ConnectionFailure,
};

pub const Client = struct {
    const Self = @This();

    ip: [*c]const u8,
    port: u16,
    client: [*c]en.ENetHost,
    address: en.ENetAddress,
    event: en.ENetEvent,
    peer: [*c]en.ENetPeer,

    pub fn init(ip: [*c]const u8, port: u16) Self {
        return Self{
            .ip = ip,
            .port = port,
            .client = undefined,
            .address = undefined,
            .event = undefined,
            .peer = undefined,
        };
    }

    pub fn connect(self: *Self) ClientError!void {
        if (en.enet_initialize() != en.EXIT_SUCCESS) {
            return ClientError.InitFailure;
        }

        self.client = en.enet_host_create(null, 1, 1, 0, 0);
        if (self.client == null) {
            return ClientError.ClientNull;
        }

        if (en.enet_address_set_host(&self.address, self.ip) != en.EXIT_SUCCESS) {
            return ClientError.SetHostFailure;
        }
        self.address.port = self.port;

        self.peer = en.enet_host_connect(self.client, &self.address, 1, 0);
        if (self.peer == null) {
            return ClientError.PeerNull;
        }

        if (!(en.enet_host_service(self.client, &self.event, 5000) > 0 and self.event.type == en.ENET_EVENT_TYPE_CONNECT)) {
            en.enet_peer_reset(self.peer);
            return ClientError.ConnectionFailure;
        }
    }

    pub fn deinit(self: Self) void {
        defer en.enet_deinitialize();
        defer en.enet_peer_disconnect(self.peer, 0);
    }
};
