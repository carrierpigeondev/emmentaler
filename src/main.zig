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
                std.debug.print("  task: {s}\n", .{task.path});
                try taskrun.callTaskRun(task.path);
            }
        }
    }

    // rl.initWindow(800, 450, "emmentaler");
    // defer rl.closeWindow();

    // while (!rl.windowShouldClose()) {
    //     rl.beginDrawing();
    //     defer rl.endDrawing();

    //     rl.clearBackground(.black);

    //     for (item_table.items) |item| {
    //         rl.drawRectangle(item.position.x, item.position.y, 5, 5, .red);
    //     }
    // }
}
