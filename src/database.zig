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
        time: []const u8,
        url: []const u8,
        channel: []const u8,
        length: []const u8,
        title: []const u8,
    };
    const rows = try stmt.all(HistoryRow, allocator, .{}, .{});
    // NOTE: provide user some info about their history state.
    defer allocator.free(rows);
    std.debug.print("Number of rows: {d}\n", .{rows.len});
    if (rows.len == 0) {
        std.log.debug("No rows found in history table.", .{});
    } else {
        std.log.debug("Found {d} rows in history:", .{rows.len});
    }
}

// NOTE: Info about video provided and parsed from yt-dlp.
const Metadata = @import("ytdlp.zig").Metadata;
pub fn insert_data(
    dbase: *sqlite.Db,
    meta: Metadata,
) !void {
    const query =
        \\INSERT INTO history(time, url, channel, length, title) VALUES(?, ?, ?, ?, ?)
    ; // 5 placeholders

    var history_records = try dbase.prepare(query);
    defer history_records.deinit();
    const time = try time_helper.get_current_time();
    try history_records.exec(.{}, .{
        .time = time,
        .url = meta.url,
        .channel = meta.channel,
        .length = meta.duration,
        .title = meta.title,
    });
}

// HACK: Housekeeping stuff for file storage/location
pub fn get_cache_location(allocator: std.mem.Allocator) ![]const u8 {
    switch (builtin.os.tag) {
        .windows => {
            const envvar = "LocalAppData";
            const value = std.process.getEnvVarOwned(allocator, envvar) catch |err| {
                switch (err) {
                    error.EnvironmentVariableNotFound => {
                        std.debug.print("Error: Environment variable '{s}' not found on Windows.\n", .{envvar});
                        return error.CacheLocationNotFound;
                    },
                    else => return err,
                }
            };
            return value;
        },
        .linux, .macos => {
            const xdg_cache_home_envvar = "XDG_CACHE_HOME";
            if (std.process.getEnvVarOwned(allocator, xdg_cache_home_envvar)) |path| {
                return path;
            } else |err| switch (err) {
                error.EnvironmentVariableNotFound => {}, // NOTE: Do nothing
                else => return err,
            }

            // Fallback: $HOME/.cache
            const home_envvar = "HOME";
            const home_dir = std.process.getEnvVarOwned(allocator, home_envvar) catch |home_err| {
                switch (home_err) {
                    error.EnvironmentVariableNotFound => {
                        std.debug.print("Error: Environment variable '{s}' not found. Cannot determine fallback cache location.\n", .{home_envvar});
                        return error.CacheLocationNotFound;
                    },
                    else => return home_err,
                }
            };
            defer allocator.free(home_dir);

            return std.fs.path.join(allocator, &.{ home_dir, ".cache" });
        },
        else => @compileError("Platform '" ++ @tagName(builtin.os.tag) ++ "' not currently supported for cache location detection."),
    }
}

// NOTE: Reads, or starts up our hist db if none exists
pub fn init_db() !sqlite.Db {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const db_dirname = try get_cache_location(allocator);
    defer allocator.free(db_dirname);
    var db_loc = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer db_loc.deinit(allocator);
    try db_loc.appendSlice(allocator, db_dirname);
    try db_loc.appendSlice(allocator, std.fs.path.sep_str); // Add platform-specific separator
    try db_loc.appendSlice(allocator, "zig_player"); // program path
    try db_loc.appendSlice(allocator, std.fs.path.sep_str); // Add platform-specific separator
    try db_loc.appendSlice(allocator, "history.db");

    // NOTE: Must be a c-string for whatever reason
    try db_loc.append(allocator, 0);
    const cstring_path: [:0]const u8 = try db_loc.toOwnedSliceSentinel(allocator, 0);
    const base_name = std.fs.path.dirname(cstring_path).?;
    std.debug.print("Attempting to create application cache directory: '{s}'\n", .{base_name});
    // NOTE: We don't care if the path already exists, in fact, that's a success, so if there's an error and it's not PathAlreadyExists, print out error
    std.fs.makeDirAbsolute(base_name) catch |dir_err| {
        if (dir_err != error.PathAlreadyExists) {
            std.debug.print("Failed to create application cache directory '{s}': {any}\n", .{ base_name, dir_err });
            return dir_err;
        }
    };

    std.debug.print("Attempting to open database at: '{s}'\n", .{cstring_path});
    std.debug.print("Database location: {s}\n", .{cstring_path}); // Handy for user

    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = cstring_path }, // Pass the [:0]const u8 type here
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .MultiThread,
    });
    defer allocator.free(cstring_path);
    try db.exec("CREATE TABLE IF NOT EXISTS history(time text primary key, url text, channel text, length text, title text)", .{}, .{});
    return db;
}
