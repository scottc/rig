const std = @import("std");

// TODO: ...
// pub var request_handler: ?*const fn ([*]const u8, usize, [*]u8, *usize) callconv(.c) void = null;

// We're just returning with a static string, until we figure out how to pass a (Str->Str) => {} function from roc to zig.
pub var placeholder_request_handler: []const u8 = "";

pub fn startDevServer(allocator: std.mem.Allocator) void {
    _ = allocator;

    const stdout: std.fs.File = .stdout();
    stdout.writeAll("startDevServer...\n") catch {};

    const address = std.net.Address.parseIp("127.0.0.1", 3010) catch unreachable;
    var listener = address.listen(.{ .reuse_address = true }) catch |err| {
        std.log.err("Failed to bind: {}", .{err});
        return;
    };
    defer listener.deinit();

    stdout.writeAll("http://127.0.0.1:3010...\n") catch {};

    while (true) {
        stdout.writeAll("while (true) accept() connection...\n") catch {};

        const conn = listener.accept() catch |err| {
            std.log.warn("accept error: {}", .{err});
            continue;
        };

        handleConnection(conn) catch |err| {
            std.log.warn("connection error: {}", .{err});
        };

        stdout.writeAll("closing connection...\n") catch {};
        conn.stream.close();
        stdout.writeAll("connection closed...\n") catch {};
    }
}

fn handleConnection(conn: std.net.Server.Connection) !void {
    const stdout: std.fs.File = .stdout();
    stdout.writeAll("handleConnection...\n") catch {};

    defer conn.stream.close();

    var buf: [8192]u8 = undefined;
    const n = try conn.stream.read(&buf);
    if (n == 0) return; // client disconnected

    // const request = buf[0..n];

    // Prepare response
    // var response: [32768]u8 = undefined;
    // var response_len: usize = 0;

    // if (request_handler) |handler| {
    //     stdout.writeAll("Calling roc app request handler...\n") catch {};
    //     handler(request.ptr, request.len, &response, &response_len);
    // } else {
    //     stdout.writeAll("No request handler supplied...\n") catch {};

    //     const msg = "HTTP/1.1 500 No Handler\r\nContent-Length: 15\r\n\r\nNo handler set";
    //     @memcpy(response[0..msg.len], msg);
    //     response_len = msg.len;
    // }

    const response = placeholder_request_handler;
    const response_len = placeholder_request_handler.len;

    stdout.writeAll("Sending response...\n") catch {};

    // Send response (blocking)
    _ = try conn.stream.writeAll(response[0..response_len]);

    // DO we need to flush?!
}
