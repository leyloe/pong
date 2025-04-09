pub const Game = struct {
    const Self = @This();

    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        init: *const fn (*anyopaque) *anyopaque,
        draw: *const fn (*anyopaque) void,
        update: *const fn (*anyopaque) void,
    };
};
