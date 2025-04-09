const std = @import("std");

pub const GameInterface = union(enum) {
    const Self = @This();

    game: Game,

    pub fn draw(self: Self) void {
        switch (self) {
            inline else => |s| s.draw(),
        }
    }
    pub fn update(self: Self) void {
        switch (self) {
            inline else => |s| s.update(),
        }
    }
};

pub const Game = struct {
    const Self = @This();

    pub fn init() Self {
        return Self{};
    }

    pub fn draw(self: Self) void {
        _ = self;
        std.debug.print("I'm drawing...\n", .{});
    }

    pub fn update(self: Self) void {
        _ = self;
        std.debug.print("I'm updating...\n", .{});
    }
};
