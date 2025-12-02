const std = @import("std");

pub fn cmdHelp(allocator: std.mem.Allocator) !void {
    _ = allocator;

    std.log.info("Rig", .{});
    std.log.info("", .{});
    std.log.info("rig help         # Prints help", .{});
    std.log.info("rig version      # Prints the version", .{});
    std.log.info("rig versions     # Prints the versions", .{});
    std.log.info("rig init default # Creates a new project", .{});
    std.log.info("rig dev          # HMR Server", .{});
    std.log.info("rig nuke         # Deletes ./my-roc-app/", .{});
}
