const clipboard = @import("clipboard");
const std = @import("std");
const builtin = @import("builtin");

// Pending my pull to the clipboard crate to be merged. Rulling my own in the meantime https://github.com/dgv/clipboard/pull/2
pub fn read() ![]u8 {
    const read_cmd = "wl-paste";
    const result = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            read_cmd,
        },
    });
    return result.stdout;
}

pub fn get_clipboard() ![]const u8 {
    switch (builtin.os.tag) {
        .windows => return try clipboard.read(),
        .macos => return try clipboard.read(),
        .linux, .freebsd, .openbsd, .netbsd, .dragonfly => return try read(),
        else => @compileError("platform not currently supported"),
    }
}
