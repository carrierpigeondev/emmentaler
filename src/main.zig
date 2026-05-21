const std = @import("std");

const toml = @import("toml");

const fs = @import("lib/fs.zig");
const toml_internal = @import("lib/toml/toml.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    const arena = init.arena;

    const directory_contents_buffer = try fs.getDirectoryContents(io, gpa, &.{"data.d"});
    defer gpa.free(directory_contents_buffer);

    const item_table = try toml_internal.structs.parseIntoItemTable(io, arena.allocator(), directory_contents_buffer);

    for (item_table.items) |item| {
        std.debug.print("Unique Item Identifer found! :: {s}\n", .{item.uiid});
    }
}
