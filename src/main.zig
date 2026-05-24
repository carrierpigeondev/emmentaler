const std = @import("std");

const toml = @import("toml");

const fs = @import("lib/fs.zig");
const taskrun = @import("lib/taskrun.zig");
const toml_internal = @import("lib/toml/toml.zig");

const rl = @import("raylib");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    const arena = init.arena;

    try fs.compileTasksInDirectory(io, gpa, &.{ "gamedata", "tasks" });

    const directory_contents_buffer = try fs.getDirectoryContents(io, gpa, &.{ "gamedata", "items" });
    defer gpa.free(directory_contents_buffer);

    const item_table = try toml_internal.structs.parseIntoItemTable(io, arena.allocator(), directory_contents_buffer);

    for (item_table.items) |item| {
        std.debug.print("Unique Item Identifer found! :: {s}\n", .{item.uiid});

        if (item.tasks) |tasks| {
            for (tasks) |task| {
                std.debug.print("  task: {s} :: ", .{task.path});

                const task_file_parts = &[_][]const u8{ task.path, ".so" };
                const task_file = try std.mem.concat(gpa, u8, task_file_parts);
                defer gpa.free(task_file);

                const path_parts = &[_][]const u8{ "gamedata", "tasks", task_file };
                const path = try std.fs.path.join(gpa, path_parts);
                defer gpa.free(path);

                std.debug.print("{s}\n", .{path});

                try taskrun.callTaskRun(io, gpa, path);
            }
        }
    }
}
