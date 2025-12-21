const std = @import("std");

pub const Metadata = struct {
    channel: []const u8,
    duration: []const u8,
    title: []const u8,
    url: []const u8,
    pub fn eql(self: Metadata, other: Metadata) bool {
        // NOTE: Compare each field. For slices (like strings), use std.mem.eql
        if (!std.mem.eql(u8, self.channel, other.channel)) return false;
        if (!std.mem.eql(u8, self.url, other.url)) return false;
        if (!std.mem.eql(u8, self.title, other.title)) return false;
        if (!std.mem.eql(u8, self.duration, other.duration)) return false;
        return true;
    }
};

// HACK: YTDLP output can be jank as hell since YT doesn't expect third parties to be doing this.
pub fn clean_ytdlp_json(input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var result_list = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer result_list.deinit(allocator); // Ensure the ArrayList's buffer is freed

    var i: usize = 0;
    while (i < input.len) {
        // Check if the current position starts with '""'
        if (i + 1 < input.len and input[i] == '"' and input[i + 1] == '"') {
            // If it's '""', skip the first
            try result_list.append(allocator, input[i]);
            i += 2;
        } else if (i + 1 < input.len and input[i] == '\\' and input[i + 1] == '"') {
            try result_list.append(allocator, '\'');
            i += 2;
        } else {
            // Otherwise, append the current character to the result
            try result_list.append(allocator, input[i]);
            i += 1;
        }
    }

    return result_list.toOwnedSlice(allocator);
}
pub fn parse_json(data: []const u8) !Metadata {
    const clean_json = try clean_ytdlp_json(data, std.heap.page_allocator);
    const parsed = try std.json.parseFromSlice(
        Metadata,
        std.heap.page_allocator,
        clean_json,
        .{},
    );
    defer parsed.deinit();
    return parsed.value;
}

pub fn ytdlp_meta(url: []const u8) ![]const u8 {
    const allocator = std.heap.page_allocator; // Allocator for the child's output
    const argv = [5][]const u8{
        "yt-dlp",
        url,
        "--profile=low-latency",
        "--print",
        "{ \"channel\": \"%(channel)s\", \"duration\": \"%(duration>%H:%M:%S)s\", \"title\": \"%(title)j\", \"url\": \"%(webpage_url)s\"}",
    };
    const result = try std.process.Child.run(.{
        .argv = &argv,
        .allocator = allocator,
    });

    // Check the exit code of the child process
    if (result.term != .Exited) {
        std.debug.print("yt-dlp process terminated unexpectedly: {any}\n", .{result.term});
        // Print stderr if available for debugging
        if (result.stderr.len > 0) {
            std.debug.print("yt-dlp stderr:\n{s}\n", .{result.stderr});
        }
        return error.ChildProcessFailed;
    }
    if (result.term.Exited != 0) {
        std.debug.print("yt-dlp exited with error code: {d}\n", .{result.term.Exited});
        // Print stderr for debugging
        if (result.stderr.len > 0) {
            std.debug.print("yt-dlp stderr:\n{s}\n", .{result.stderr});
        }
        return error.YtDlpError;
    }

    return result.stdout;
}
