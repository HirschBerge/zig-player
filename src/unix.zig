const std = @import("std");

pub fn play_video(url: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const process_to_check = "mpv";
    const is_running = try isMPVRunning(allocator, process_to_check);

    if (is_running) {
        std.debug.print("✅ {s} is running, adding video to queue.\n", .{process_to_check});
        try sendMpvCommand(gpa.allocator(), url);
    } else {
        std.debug.print("❌ {s} isn't running, playing video.\n", .{process_to_check});
        const argv = [4][]const u8{
            "mpv",
            url,
            "--no-terminal",
            "--input-ipc-server=/tmp/mpvsocket",
        };
        var child = std.process.Child.init(&argv, std.heap.page_allocator);
        try child.spawn();
    }
}

// HACK: I was using `echo '{ "command": [ "loadfile", "'$url'", "append-play" ] }' | socat - /tmp/mpvsocket > /d ev/null 2>&1 &`
// as my method to interact with the currently running MPV instance to add a video to the queue.
// I'm sure there's a better way that doesn't involve socat and I can just write directly to the socket, but this works for now
pub fn sendMpvCommand(allocator: std.mem.Allocator, url: []const u8) !void {
    const socat_path = "/nix/store/jw6gsbn20550r42arpiph6v6jhh0cq7w-socat-1.8.0.3/bin/socat";
    const argv = [_][]const u8{
        socat_path,
        "-",
        "/tmp/mpvsocket",
    };
    const json_command = try std.fmt.allocPrint(allocator,
        \\{{ "command": [ "loadfile", "{s}", "append-play" ] }}
    , .{url});
    defer allocator.free(json_command);
    // NOTE: Writes the url to be added to queue to the MPV socket file.
    var child = std.process.Child.init(&argv, allocator);
    child.stdin_behavior = .Pipe;
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;
    try child.spawn();
    const stdin_handle = child.stdin orelse {
        return error.Unexpected;
    };
    try stdin_handle.writeAll(json_command);
    stdin_handle.close();
}

pub fn isMPVRunning(allocator: std.mem.Allocator, process_name: []const u8) !bool {
    const argv = [_][]const u8{ "pgrep", process_name };
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &argv,
    });
    // NOTE: Check the process termination code.
    return switch (result.term) {
        .Exited => |exit_code| exit_code == 0,
        else => false,
    };
}
