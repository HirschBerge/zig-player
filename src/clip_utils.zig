const clipboard = @import("clipboard");
const std = @import("std");
const builtin = @import("builtin");

// NOTE: Switches on the OS type to do basically nothing unique.
// I don't really remember why I wrote it this way initially. i think I had  PR in to fix something.
pub fn get_clipboard() ![]const u8 {
    switch (builtin.os.tag) {
        .windows => return try clipboard.read(),
        .macos => return try clipboard.read(),
        .linux, .freebsd, .openbsd, .netbsd, .dragonfly => return try clipboard.read(),
        else => @compileError("platform not currently supported"),
    }
}
