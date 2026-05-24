const std = @import("std");
const toml_external = @import("toml");

pub const ItemTable = struct {
    items: []Item,
};

pub const Item = struct {
    uiid: []const u8, // unique item identifier
    tasks: ?[]Task = null,
};

/// `path` must match to a .so file (.zig of the same name after compilation by
/// executing Emmentaler).
///
/// `type` is optional, default to `once`. Dictates when the task is run.
/// Options are: `once`, and `loop`
pub const Task = struct {
    path: []const u8, // matches to a .so file containing the task code
    type: ?[]const u8 = "once",
};

pub fn parseIntoItemTable(io: std.Io, allocator: std.mem.Allocator, input: []const u8) !ItemTable {
    var err: toml_external.ErrorInfo = .{};
    const item_table = toml_external.parseInto(ItemTable, allocator, input, &err) catch |e| {
        const fmt_err = try std.fmt.allocPrint(allocator, "parse error {d}:{d}: {s}", .{ err.line, err.col, err.message() });
        defer allocator.free(fmt_err);
        try std.Io.File.stderr().writeStreamingAll(io, fmt_err);
        return e;
    };

    return item_table;
}

fn lessThan(_: void, a: Item, b: Item) bool {
    return std.mem.order(u8, a.uiid, b.uiid) == .lt;
}

pub fn sortItemTable(item_table: ItemTable) void {
    std.mem.sort(Item, item_table.items, {}, lessThan);
}
