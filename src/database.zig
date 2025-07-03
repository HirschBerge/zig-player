const std = @import("std");
const sqlite = @import("sqlite");
const time_helper = @import("time.zig");

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

pub fn insert_data(dbase: *sqlite.Db) !void {
    const query =
        \\INSERT INTO history(time, url, channel, length, title) VALUES(?, ?, ?, ?, ?)
    ; // 5 placeholders

    var stmt = try dbase.prepare(query);
    defer stmt.deinit();

    const time = try time_helper.get_current_time();

    // const allocator = std.heap.page_allocator; // Get an allocator for the options
    try stmt.exec(.{}, .{
        .time = time,
        .url = "https:/yt.be/text",
        .channel = "DokiBird",
        .length = "1:43:49",
        .title = "She did WHAT!?!?",
    });

    std.debug.print("Data inserted.\n", .{});
}

pub fn init_db() !sqlite.Db {
    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = "./mydata.db" },
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .MultiThread,
    });
    try db.exec("CREATE TABLE IF NOT EXISTS history(time text primary key, url text, channel text, length text, title text)", .{}, .{});
    return db;
}
