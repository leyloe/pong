const en = @cImport({
    @cInclude("enet.h");
});

pub const ServerError = error{
    InitFailure,
    ServerNull,
    PollFailure,
};

const Self = @This();

host: [*c]en.ENetHost,
address: en.ENetAddress,

pub fn init(port: u16) ServerError!Self {
    var self: Self = undefined;

    if (en.enet_initialize() != en.EXIT_SUCCESS) {
        return ServerError.InitFailure;
    }

    self.address.host = en.in6addr_any;
    self.address.port = port;

    self.host = en.enet_host_create(&self.address, 1, 1, 0, 0);
    if (self.host == null) {
        return ServerError.ServerNull;
    }
}

pub fn poll(self: *Self, event: [*c]en.ENetEvent) !void {
    if (en.enet_host_service(self.host, event, 0) < 0) {
        return ServerError.PollFailure;
    }
}

pub fn poll_timeout(self: *Self, event: [*c]en.ENetEvent, timeout: u32) !void {
    if (en.enet_host_service(self.host, event, timeout) < 0) {
        return ServerError.PollFailure;
    }
}

pub fn deinit(self: Self) void {
    defer en.enet_deinitialize();
    defer en.enet_host_destroy(self.host);
}
