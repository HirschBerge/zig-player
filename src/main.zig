//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

pub fn main() !void {
    const clip_contents = try clip_utils.read();
    const valid_clip: bool = filter_clipboard(clip_contents);
    if (valid_clip) {
        try play_video(clip_contents);
    } else {
        // std.debug.print("Not playing {s}", "video");
    }
}

fn filter_clipboard(clip: []const u8) bool {
    const url = "http";
    if (std.mem.indexOf(u8, clip, url) != null) {
        std.debug.print("Attempting to play '{s}'\n", .{clip});
        return true;
    } else {
        std.debug.print("'{s}' is NOT a URL\n", .{clip});
        return false;
    }
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

test "valid url" {
    const input = "https://www.youtube.com/watch?v=3pdkMH52Wls";
    const result = filter_clipboard(input);
    std.debug.assert(result == true);
}

test "invalid url" {
    const input = "Single goth women in my zip code";
    const result = filter_clipboard(input);
    std.debug.assert(result == false);
}

const std = @import("std");
/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
// const lib = @import("zig_player_lib");
const clip_utils = @import("clipboard");
