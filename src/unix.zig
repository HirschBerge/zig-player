const std = @import("std");

pub fn play_video(url: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const process_to_check = "mpv";
    const is_running = try isMPVRunning(allocator, process_to_check);

    if (is_running) {
        // INFO: If we catch an MPV process, *assume* we created it in the past and has an ipc socket
        // See below for the flag we provided
        // Instead of launching MPV, instead write the needed data to the socket to add to queue.
        std.debug.print("✅ {s} is running, adding video to queue.\n", .{process_to_check});
        try sendMpvCommand(gpa.allocator(), url);
    } else {
        // INFO: If no MPV process is running, we want to start a new one.
        // The --input-ipc-sever allows us to interact with the instance via socket. See above
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
// I got fed up trying to recreate using `socat` and found out that 'socet programming' at least for my usecase
// is easier than I thought it would be. Had some help from the sloppers,but it seems to be working now
pub fn sendMpvCommand(allocator: std.mem.Allocator, url: []const u8) !void {
    //HACK: Use the socket we told mpv to use in the else-case above
    const socket_path = "/tmp/mpvsocket";
    //NOTE: MPV commands to add video to end of queue
    const json_command = try std.fmt.allocPrint(allocator,
        \\{{ "command": [ "loadfile", "{s}", "append-play" ] }}
    , .{url});
    defer allocator.free(json_command);

    // NOTE: Simply open and write data to socket.
    var stream = try std.net.connectUnixSocket(socket_path);
    defer stream.close(); // Ensure the connection is closed when the function exits.
    try stream.writeAll(json_command);
    try stream.writeAll("\n");
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
