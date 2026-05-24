const std = @import("std");

const toml = @import("toml");

const fs = @import("lib/fs.zig");
const taskrun = @import("lib/taskrun.zig");
const toml_internal = @import("lib/toml.zig");

const rl = @import("raylib");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    const arena = init.arena;

    // Compile tasks in the given directory (configuration not yet implemented)
    // takes all the .zig files and builds .so libs from them to exec as tasks
    try fs.compileTasksInDirectory(io, gpa, &.{ "gamedata", "tasks" });

    // Configuration data is read for the actual items
    const directory_contents_buffer = try fs.getDirectoryContents(io, gpa, &.{ "gamedata", "items" });
    defer gpa.free(directory_contents_buffer);

    const item_table = try toml_internal.parseIntoItemTable(io, arena.allocator(), directory_contents_buffer);

    // TODO: sort the items in the table by unique id so the execution of tasks
    // is deterministic, or at least, more so than it is now -- observed
    // behavior shows consistency when the item files are unchanged, but when
    // changed it seems to differ (no clue why tbh)

    // TODO: after sorted (so sorting only takes place once), need to break
    // into task types (TODO implementation of task types) for execution

    // TODO: execute tasks of type Init (low priority feature)
    //
    // TODO: execute tasks of type Once

    // TODO: enter a loop, inside of loop execute tasks of type EarlyLoop, (low
    // priority feature) then tasks of type Loop

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
