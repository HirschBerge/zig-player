const std = @import("std");

pub const Metadata = struct {
    channel: []const u8,
    duration: []const u8,
    title: []const u8,
    url: []const u8,
    pub fn eql(self: Metadata, other: Metadata) bool {
        // Compare each field. For slices (like strings), use std.mem.eql
        if (!std.mem.eql(u8, self.channel, other.channel)) return false;
        if (!std.mem.eql(u8, self.url, other.url)) return false;
        if (!std.mem.eql(u8, self.title, other.title)) return false;
        if (!std.mem.eql(u8, self.duration, other.duration)) return false;

        // If all fields are equal, then the structs are equal
        return true;
    }
};

pub fn handles_quote_literals(input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var result_list = std.ArrayList(u8).init(allocator);
    defer result_list.deinit(); // Ensure the ArrayList's buffer is freed

    var i: usize = 0;
    while (i < input.len) {
        // Check if the current position starts with '""'
        if (i + 1 < input.len and input[i] == '"' and input[i + 1] == '"') {
            // If it's '""', skip the first
            try result_list.append(input[i]);
            i += 2;
        } else if (i + 1 < input.len and input[i] == '\\' and input[i + 1] == '"') {
            try result_list.append('\'');
            i += 2;
        } else {
            // Otherwise, append the current character to the result
            try result_list.append(input[i]);
            i += 1;
        }
    }

    return result_list.toOwnedSlice();
}
pub fn parse_json(data: []const u8) !Metadata {
    const clean_json = try handles_quote_literals(data, std.heap.page_allocator);
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
    const argv = [6][]const u8{ "yt-dlp", url, "--cookies-from-browser", "firefox", "--print", "{ \"channel\": \"%(channel)s\", \"duration\": \"%(duration>%H:%M:%S)s\", \"title\": \"%(title)j\", \"url\": \"%(webpage_url)s\"}", };
    const result = try std.process.Child.run(.{
        .argv = &argv, // Pass a pointer to the argv array
        .allocator = allocator, // The allocator used to store captured stdout/stderr
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
