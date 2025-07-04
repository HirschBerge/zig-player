const std = @import("std");

pub fn play_video(url: []const u8) !void {
    const argv = [4][]const u8{
        "mpv",
        url,
        "--no-terminal",
        "--input-ipc-server=/tmp/mpvsocket",
    };
    var child = std.process.Child.init(&argv, std.heap.page_allocator);
    try child.spawn();
}
