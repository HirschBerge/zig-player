//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

pub fn main() !void {
    const clip_contents = try clip_utils.read();
    try play_video(clip_contents);
}

fn play_video(url: []const u8) !void {
    const argv = [3][]const u8{
        "mpv",
        url,
        "--no-terminal",
    };
    var child = std.process.Child.init(&argv, std.heap.page_allocator);
    try child.spawn();
    // const exit_code = child.wait();
    // try std.testing.expectEqual(exit_code, std.process.Child.Term{ .Exited = 0 });
}


const std = @import("std");
/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
// const lib = @import("zig_player_lib");
const clip_utils = @import("clipboard");
