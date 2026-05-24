const std = @import("std");

pub export fn run() callconv(.c) void {
    std.debug.print("Hello, Emmentaler!\n", .{});
}
