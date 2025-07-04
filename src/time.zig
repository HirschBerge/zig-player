const zeit = @import("zeit");
const std = @import("std");

pub fn get_current_time() ![]u8 {
    const allocator = std.heap.page_allocator;
    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    // Get an instant in time. The default gets "now" in UTC
    const now = try zeit.instant(.{});

    // Load our local timezone. This needs an allocator. Optionally pass in a
    // *const std.process.EnvMap to support TZ and TZDIR environment variables
    const local = try zeit.local(allocator, &env);

    // Convert our instant to a new timezone
    const now_local = now.in(&local);

    // Generate date/time info for this instant
    const dt = now_local.time();
    var buffer: [50]u8 = undefined;
    const formatted = try dt.bufPrint(&buffer, .rfc3339);
    return allocator.dupe(u8, formatted);
}
