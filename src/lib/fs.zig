const std = @import("std");

/// The return value of `![]const u8` must be freed by the `allocator: std.mem.Allocator` manually
/// outside the scope of this function.
///
/// For example:
/// ```
/// const content_buffer = try readFile(init.io, init.gpa, file);  // call of function
/// ... // use the content_buffer
/// init.gpa.free(content_buffer);  // free content_buffer using the same allocator
/// ```
pub fn readFile(io: std.Io, allocator: std.mem.Allocator, file: std.Io.File) ![]const u8 {
    var reader_buffer: [1024]u8 = undefined;
    var reader = file.reader(io, &reader_buffer);
    var reader_interface = &reader.interface;

    const file_len = try file.length(io);
    const content_buffer = try allocator.alloc(u8, file_len);
    try reader_interface.readSliceAll(content_buffer);

    return content_buffer;
}

/// The return value of `![]const u8` must be freed by the `allocator: std.mem.Allocator` manually
/// outside the scope of this function.
///
/// For example:
/// ```
/// const directory_content_buffer = try getDirectoryContents(init.io, init.gpa, &.{ "config", "net.d" })  // call of function
/// ... // use the directory_content_buffer
/// init.gpa.free(directory_content_buffer);  // free directory_content_buffer using the same allocator
/// ```
pub fn getDirectoryContents(io: std.Io, allocator: std.mem.Allocator, dir_parts: []const []const u8) ![]const u8 {
    const dir_path = try std.fs.path.join(allocator, dir_parts);
    defer allocator.free(dir_path);

    var dir = try std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true });
    defer dir.close(io);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var directory_content_buffer: std.ArrayList(u8) = .empty;
    errdefer directory_content_buffer.deinit(allocator);

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) {
            continue;
        }

        const file = try dir.openFile(io, entry.path, .{});
        defer file.close(io);

        const content_buffer = try readFile(io, allocator, file);
        defer allocator.free(content_buffer);

        try directory_content_buffer.appendSlice(allocator, content_buffer);
    }

    return try directory_content_buffer.toOwnedSlice(allocator);
}

pub fn compileTasksInDirectory(io: std.Io, allocator: std.mem.Allocator, dir_parts: []const []const u8) !void {
    const dir_path = try std.fs.path.join(allocator, dir_parts);
    defer allocator.free(dir_path);

    var dir = try std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true });
    defer dir.close(io);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) {
            continue;
        }

        const idx = std.mem.lastIndexOfScalar(u8, entry.basename, '.') orelse entry.basename.len;

        const extension = if (idx == entry.basename.len) "" else entry.basename[idx + 1 ..];
        if (!std.mem.eql(u8, extension, "zig")) {
            continue;
        }

        const task_name = entry.basename[0..idx];
        const task_file_parts = &[_][]const u8{ task_name, ".so" };
        const task_file = try std.mem.concat(allocator, u8, task_file_parts);
        defer allocator.free(task_file);

        const output_path_parts = &[_][]const u8{ dir_path, task_file };
        const output_path = try std.fs.path.join(allocator, output_path_parts);
        defer allocator.free(output_path);

        const femitbin_arg_parts = &[_][]const u8{ "-femit-bin=", output_path };
        const femitbin_arg = try std.mem.concat(allocator, u8, femitbin_arg_parts);
        defer allocator.free(femitbin_arg);

        const argv = &[_][]const u8{ "zig", "build-lib", entry.path, "-dynamic", femitbin_arg };

        const res = try std.process.run(allocator, io, .{ .argv = argv });
        defer allocator.free(res.stdout);
        defer allocator.free(res.stderr);

        std.debug.print("{s}\n\n {s}\n\n {any}\n\n", .{ res.stdout, res.stdout, res.term });
    }
}
