const std = @import("std");
const toml_external = @import("toml");

pub const ItemTable = struct {
    items: []Item,
};

pub const Item = struct {
    uiid: []const u8, // unique item identifier
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
