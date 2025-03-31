const en = @cImport({
    @cInclude("enet.h");
});

const NetError = error{
    InitFailed,
};

pub const Net = struct {
    const Self = @This();

    pub fn init() NetError!Self {
        if (en.enet_initialize() != 0) {
            return NetError.InitFailed;
        }

        return Self{};
    }

    pub fn deinit(_: Self) void {
        defer en.enet_deinitialize();
    }
};
