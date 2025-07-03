const std = @import("std");

pub const Metadata = struct {
    channel: []const u8,
    duration: []const u8,
    title: []const u8,
    url: []const u8,
};

pub fn parse_json(data: []const u8) !Metadata {
    const parsed = try std.json.parseFromSlice(
        Metadata,
        std.heap.page_allocator,
        data,
        .{},
    );
    defer parsed.deinit();
    return parsed.value;
}

pub fn ytdlp_meta(url: []const u8) ![]const u8 {
    const allocator = std.heap.page_allocator; // Allocator for the child's output
    const argv = [6][]const u8{
        "yt-dlp",
        url,
        "--cookies-from-browser",
        "firefox",
        "--print",
        "{ \"channel\": \"%(channel)s\", \"duration\": \"%(duration>%H:%M:%S)s\", \"title\": \"%(title)s\", \"url\": \"%(webpage_url)s\"}",
    };
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

    // `result.stdout` contains the captured output as a `[]const u8` slice.
    // This slice is owned by the `allocator` you passed to `Child.run`.
    // The caller is now responsible for freeing it.
    return result.stdout;
}
