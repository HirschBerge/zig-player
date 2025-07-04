const std = @import("std");
const sqlite = @import("sqlite");
const time_helper = @import("time.zig");
const builtin = @import("builtin");

pub fn read_db(dbase: *sqlite.Db) !void {
    const query =
        \\SELECT * FROM history
    ;

    var stmt = try dbase.prepare(query);
    defer stmt.deinit();
    const allocator = std.heap.page_allocator;
    const HistoryRow = struct {
        time: []const u8, // Using []const u8 as it's read-only data
        url: []const u8,
        channel: []const u8,
        length: []const u8,
        title: []const u8,
    };
    const rows = try stmt.all(HistoryRow, // 1. The type of each row (your struct)
        allocator, // 2. The allocator for the `[]HistoryRow` array
        .{}, .{});
    defer allocator.free(rows);
    std.debug.print("Number of rows: {d}\n", .{rows.len});
    if (rows.len == 0) {
        std.log.debug("No rows found in history table.", .{});
    } else {
        std.log.debug("Found {d} rows in history:", .{rows.len});
        for (rows) |row| { // Iterate through the slice of rows
            std.log.debug("time: {s}, url: {s}, channel: {s}, length: {s}, title: {s}", .{
                row.time,
                row.url,
                row.channel,
                row.length,
                row.title,
            });
        }
    }
}

const Metadata = @import("ytdlp.zig").Metadata;
pub fn insert_data(
    dbase: *sqlite.Db,
    meta: Metadata,
) !void {
    const query =
        \\INSERT INTO history(time, url, channel, length, title) VALUES(?, ?, ?, ?, ?)
    ; // 5 placeholders

    var stmt = try dbase.prepare(query);
    defer stmt.deinit();

    const time = try time_helper.get_current_time();

    // const allocator = std.heap.page_allocator; // Get an allocator for the options
    try stmt.exec(.{}, .{
        .time = time,
        .url = meta.url,
        .channel = meta.channel,
        .length = meta.duration,
        .title = meta.title,
    });
}

pub fn get_cache_location(allocator: std.mem.Allocator) ![]const u8 {
    switch (builtin.os.tag) {
        .windows => {
            const envvar = "LocalAppData";
            const value = std.process.getEnvVarOwned(allocator, envvar) catch |err| {
                switch (err) {
                    error.EnvironmentVariableNotFound => {
                        // On Windows, if LocalAppData is not found, what's the fallback?
                        // Often it's %USERPROFILE%\AppData\Local.
                        // For simplicity, let's just return an error if not found.
                        std.debug.print("Error: Environment variable '{s}' not found on Windows.\n", .{envvar});
                        return error.CacheLocationNotFound; // Define a new error or use a general one
                    },
                    else => return err, // Propagate other errors (e.g., OutOfMemory)
                }
            };
            return value;
        },
        .linux, .macos => {
            const xdg_cache_home_envvar = "XDG_CACHE_HOME";
            const xdg_cache_home = std.process.getEnvVarOwned(allocator, xdg_cache_home_envvar) catch |err| {
                switch (err) {
                    error.EnvironmentVariableNotFound => {
                        std.debug.print("Info: Environment variable '{s}' not found. Falling back to default cache location.\n", .{xdg_cache_home_envvar});
                        // Fallback: $HOME/.cache
                        const home_envvar = "HOME";
                        const home_dir = std.process.getEnvVarOwned(allocator, home_envvar) catch |home_err| {
                            switch (home_err) {
                                error.EnvironmentVariableNotFound => {
                                    std.debug.print("Error: Environment variable '{s}' not found. Cannot determine fallback cache location.\n", .{home_envvar});
                                    // If HOME is also not found, we cannot determine a standard cache location.
                                    return error.CacheLocationNotFound; // New error or propagate
                                },
                                else => return home_err, // Propagate other errors
                            }
                        };
                        // home_dir is now owned by 'allocator', remember to defer free it
                        defer allocator.free(home_dir);

                        // Construct the default path: home_dir + "/.cache"
                        var default_cache_path = std.ArrayList(u8).init(allocator);
                        defer default_cache_path.deinit(); // Deinit the ArrayList itself
                        try default_cache_path.appendSlice(home_dir);
                        try default_cache_path.appendSlice(std.fs.path.sep_str); // Add platform-specific separator
                        try default_cache_path.appendSlice(".cache"); // The XDG default cache subdir
                        // Return the owned slice from the ArrayList
                        return default_cache_path.toOwnedSlice();
                    },
                    else => return err, // Propagate other errors (e.g., OutOfMemory)
                }
            };
            return xdg_cache_home;
        },
        // For other OS tags, throw a compile error.
        else => @compileError("Platform '" ++ @tagName(builtin.os.tag) ++ "' not currently supported for cache location detection."),
    }
}

pub fn init_db() !sqlite.Db {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const db_dirname = try get_cache_location(allocator);
    defer allocator.free(db_dirname);
    var db_loc = std.ArrayList(u8).init(allocator);
    // Defer deiniting the ArrayList structure itself.
    // The memory it held will be transferred to 'final_db_path_c_string' by toOwnedSliceSentinel().
    defer db_loc.deinit();

    try db_loc.appendSlice(db_dirname);
    try db_loc.appendSlice(std.fs.path.sep_str); // Add platform-specific separator
    try db_loc.appendSlice("zig_player"); // program path
    try db_loc.appendSlice(std.fs.path.sep_str); // Add platform-specific separator
    try db_loc.appendSlice("history.db");
    // NOTE: Must be a c-string for whatever reason
    try db_loc.append(0);
    const cstring_path: [:0]const u8 = try db_loc.toOwnedSliceSentinel(0);
    const base_name = std.fs.path.dirname(cstring_path).?;
    std.debug.print("Attempting to create application cache directory: '{s}'\n", .{base_name});
    std.fs.makeDirAbsolute(base_name) catch |dir_err| {
        if (dir_err == error.PathAlreadyExists) {} else {
            // Handle other errors (e.g., permissions, invalid path segments)
            std.debug.print("Failed to create application cache directory '{s}': {any}\n", .{ base_name, dir_err });
            return dir_err; // Propagate the error if directory couldn't be created
        }
    };
    std.debug.print("Attempting to open database at: '{s}'\n", .{cstring_path}); // <-- ADD THIS
    defer allocator.free(cstring_path);

    std.debug.print("Database location: {s}\n", .{cstring_path});

    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = cstring_path }, // Pass the [:0]const u8 type here
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .MultiThread,
    });
    try db.exec("CREATE TABLE IF NOT EXISTS history(time text primary key, url text, channel text, length text, title text)", .{}, .{});
    return db;
}
