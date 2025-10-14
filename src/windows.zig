const std = @import("std");

// NOTE: Boring Windows.
pub fn play_video(url: []const u8) !void {
    const argv = [3][]const u8{
        "mpv",
        url,
        "--no-terminal",
    };
    var child = std.process.Child.init(&argv, std.heap.page_allocator);
    try child.spawn();
}

// TODO: Look into the windows socket compatability with MPV and windows as a whole. Might be able to bring more features to windows.
