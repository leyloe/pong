const net = @import("net.zig");
const app = @import("../app.zig");

pub const HostApp = struct {
    const Self = @This();

    app: app.App,
};
