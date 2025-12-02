const std = @import("std");

fn getCommandVersion(
    allocator: std.mem.Allocator,
    args: []const []const u8,
) ![]const u8 {
    var child = std.process.Child.init(args, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Ignore;

    try child.spawn();

    const stdout = try child.stdout.?.readToEndAlloc(allocator, 1024);
    errdefer allocator.free(stdout);

    const term = try child.wait();
    if (term != .Exited or term.Exited != 0) {
        return allocator.dupe(u8, "unknown");
    }

    return std.mem.trim(u8, stdout, " \r\n\t");
}

pub fn cmdVersion(allocator: std.mem.Allocator) !void {
    _ = allocator;
    std.log.info("{s}", .{"0.1.0"});
}

pub fn cmdVersions(allocator: std.mem.Allocator) !void {
    std.log.info("Running rig version", .{});

    const roc_version = blk: {
        const result = getCommandVersion(allocator, &.{ "roc", "version" }) catch |err| switch (err) {
            error.FileNotFound => break :blk try allocator.dupe(u8, "not installed"),
            else => break :blk try allocator.dupe(u8, "unknown"),
        };
        break :blk result;
    };
    // defer allocator.free(roc_version);

    const zig_version = blk: {
        const result = getCommandVersion(allocator, &.{ "zig", "version" }) catch |err| switch (err) {
            error.FileNotFound => break :blk try allocator.dupe(u8, "not installed"),
            else => break :blk try allocator.dupe(u8, "unknown"),
        };
        break :blk result;
    };
    // defer allocator.free(zig_version);

    std.log.info(
        \\
        \\rig {s}
        \\├─ zig {s}
        \\└─ roc {s}
    , .{
        "0.1.0",
        zig_version,
        roc_version,
    });
}
