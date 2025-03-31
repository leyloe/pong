const en = @cImport({
    @cInclude("enet.h");
});

pub const ClientError = error{
    InitFailed,
    ClientNull,
};

pub const Client = struct {
    const Self = @This();

    client: [*c]en.ENetHost,
    address: en.ENetAddress,
    event: en.ENetEvent,

    pub fn init() Self {
        return Self{
            .client = undefined,
            .address = undefined,
            .event = undefined,
        };
    }

    pub fn setup(self: *Self) ClientError!void {
        if (en.enet_initialize() != en.EXIT_SUCCESS) {
            return ClientError.InitFailed;
        }

        self.client = en.enet_host_create(null, 1, 1, 0, 0);

        if (self.client == null) {
            return ClientError.ClientNull;
        }
    }

    pub fn deinit(_: Self) void {
        defer en.enet_deinitialize();
    }
};
