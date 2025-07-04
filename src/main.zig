pub fn main() !void {
    const clip_contents = try clip_utils.read();
    var dbase = try databses.init_db();
    const valid_clip: bool = filter_clipboard(clip_contents);
    if (!valid_clip) {
        std.log.err("Clipboard does not contain a url {}", .{error.URLNotFound});
        std.process.exit(1);
    }
    switch (builtin.os.tag) {
        .windows => try win.play_video(clip_contents),
        .linux, .freebsd, .openbsd, .macos, .netbsd, .dragonfly => try unix.play_video(clip_contents),
        else => @compileError("platform not currently supported"),
    }
    const meta = try ytdlp.ytdlp_meta(clip_contents);
    const parsed_meta = try ytdlp.parse_json(meta);
    try databses.insert_data(&dbase, parsed_meta);
    std.debug.print("Channel: {s} Duration: {s} Title: {s} Url: {s}\n", .{
        parsed_meta.channel,
        parsed_meta.duration,
        parsed_meta.title,
        parsed_meta.url,
    });
    try databses.read_db(&dbase);
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



test "valid url" {
    const input = "https://www.youtube.com/watch?v=3pdkMH52Wls";
    const result = filter_clipboard(input);
    std.debug.assert(result == true);
}

test "parse meta" {
    const expected = ytdlp.Metadata{
        .channel = "Jonkero",
        .url = "https://www.youtube.com/watch?v=3pdkMH52Wls",
        .title = "Code Your Own Web Server BackEnd REST API with Rust lang",
        .duration = "00:24:38",
    };
    const input = "https://www.youtube.com/watch?v=3pdkMH52Wls";
    const result = try ytdlp.parse_json(try ytdlp.ytdlp_meta(input));
    std.debug.assert(result.eql(expected));
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
const sqlite = @import("sqlite");
const databses = @import("database.zig");
const ytdlp = @import("ytdlp.zig");
const builtin = @import("builtin");
const unix = @import("unix.zig");
const win = @import("windows.zig");
