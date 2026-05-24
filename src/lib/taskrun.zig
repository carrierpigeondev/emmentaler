const std = @import("std");

const TaskRun = *const fn () callconv(.c) void;

pub fn callTaskRun(io: std.Io, allocator: std.mem.Allocator, path: []const u8) !void {
    try std.Io.Dir.cwd().access(io, path, .{});

    const abs_path = try std.Io.Dir.cwd().realPathFileAlloc(io, path, allocator);
    defer allocator.free(abs_path);

    std.debug.print("{s}\n", .{abs_path});

    var task_lib = try std.DynLib.open(abs_path);
    defer task_lib.close();

    const run = task_lib.lookup(TaskRun, "run") orelse return error.MissingRunFunction;
    run();
}
