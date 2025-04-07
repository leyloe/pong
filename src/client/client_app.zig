const net = @import("net.zig");
const app = @import("../app.zig");

pub const ClientApp = struct {
    const Self = @This();

    app: app.App,
};
