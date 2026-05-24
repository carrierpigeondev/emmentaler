const std = @import("std");

const TaskRun = *const fn () callconv(.c) void;

pub fn callTaskRun(path: []const u8) !void {
    var task_lib = try std.DynLib.open(path);
    defer task_lib.close();

    const run = task_lib.lookup(TaskRun, "run") orelse return error.MissingRunFunction;
    run();
}
