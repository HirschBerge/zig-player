const zeit = @import("zeit");
const std = @import("std");

pub fn get_current_time() ![]u8 {
    const allocator = std.heap.page_allocator;
    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    const now = try zeit.instant(.{});
    const our_tz = try zeit.local(allocator, &env);
    const localized_time = now.in(&our_tz);
    const dt = localized_time.time();
    var buffer: [50]u8 = undefined;
    const formatted = try dt.bufPrint(&buffer, .rfc3339);
    return allocator.dupe(u8, formatted);
}
