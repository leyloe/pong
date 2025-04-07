const en = @cImport({
    @cInclude("enet.h");
});

pub const ServerError = error{
    InitFailure,
    ServerNull,
    PollFailure,
};

pub const Server = struct {
    const Self = @This();

    port: u16,
    server: [*c]en.ENetHost,
    address: en.ENetAddress,

    pub fn init(port: u16) Self {
        return Self{
            .port = port,
            .server = undefined,
            .address = undefined,
        };
    }

    pub fn bind(self: *Self) ServerError!void {
        if (en.enet_initialize() != en.EXIT_SUCCESS) {
            return ServerError.InitFailure;
        }

        self.address.host = en.in6addr_any;
        self.address.port = self.port;

        self.server = en.enet_host_create(&self.address, 1, 1, 0, 0);
        if (self.server == null) {
            return ServerError.ServerNull;
        }
    }

    pub fn poll(self: *Self, event: [*c]en.ENetEvent) !void {
        if (en.enet_host_service(self.server, event, 0) < 0) {
            return ServerError.PollFailure;
        }
    }

    pub fn poll_timeout(self: *Self, event: [*c]en.ENetEvent, timeout: u32) !void {
        if (en.enet_host_service(self.server, event, timeout) < 0) {
            return ServerError.PollFailure;
        }
    }

    pub fn deinit(self: Self) void {
        defer en.enet_deinitialize();
        defer en.enet_host_destroy(self.server);
    }
};
