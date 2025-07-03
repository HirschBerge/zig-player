const clipboard = @import("clipboard");
const std = @import("std");
const builtin = @import("builtin");

// Pending my pull to the clipboard crate to be merged. Rulling my own in the meantime https://github.com/dgv/clipboard/pull/2

pub fn get_clipboard() ![]const u8 {
    switch (builtin.os.tag) {
        .windows => return try clipboard.read(),
        .macos => return try clipboard.read(),
        .linux, .freebsd, .openbsd, .netbsd, .dragonfly => return try clipboard.read(),
        else => @compileError("platform not currently supported"),
    }
}
