const en = @cImport({
    @cInclude("enet.h");
});

pub const NetError = error{
    InitFailed,
    ClientNull,
};

pub const Net = struct {
    const Self = @This();

    client: [*c]en.ENetHost,
    address: en.ENetAddress,
    event: en.ENetEvent,

    pub fn init() Self {
        return Self{ .client = undefined };
    }

    pub fn setup(self: *Self) NetError!void {
        if (en.enet_initialize() != en.EXIT_SUCCESS) {
            return NetError.InitFailed;
        }

        self.client = en.enet_host_create(null, 1, 1, 0, 0);

        if (self.client == null) {
            return NetError.ClientNull;
        }
    }

    pub fn deinit(_: Self) void {
        defer en.enet_deinitialize();
    }
};
