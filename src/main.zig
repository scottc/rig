const std = @import("std");

const version = @import("version.zig");
const init = @import("init.zig");
const dev = @import("dev.zig");
const help = @import("help.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // const zigVersion = std.process.Child.run(.{
    //     .allocator = std.heap.page_allocator,
    //     .argv = &[_][]const u8{ "zig", "version" },
    // }) catch unreachable; // we depend on zig existing in the $PATH, this is a fatal error... TODO: print friendly error, then panic.
    // defer std.heap.page_allocator.free(zigVersion.stdout);
    // defer std.heap.page_allocator.free(zigVersion.stderr);

    // const rocVersion = std.process.Child.run(.{
    //     .allocator = std.heap.page_allocator,
    //     .argv = &[_][]const u8{ "roc", "version" },
    // }) catch unreachable; // we depend on roc existing in the $PATH, this is a fatal error... TODO: print friendly error, then panic.
    // defer std.heap.page_allocator.free(rocVersion.stdout);
    // defer std.heap.page_allocator.free(rocVersion.stderr);

    if (args.len >= 2) {
        if (std.mem.eql(u8, args[1], "init") and std.mem.eql(u8, args[2], "default")) {
            return init.cmdInitDefault(allocator); //, args[2..]);
        } else if (std.mem.eql(u8, args[1], "init") and std.mem.eql(u8, args[2], "luke")) {
            return init.cmdInitLuke(allocator); //, args[2..]);
        } else if (std.mem.eql(u8, args[1], "nuke")) {
            return init.cmdNuke(allocator);
        } else if (std.mem.eql(u8, args[1], "version")) {
            return version.cmdVersion(allocator); //, args[2..]);
        } else if (std.mem.eql(u8, args[1], "versions")) {
            return version.cmdVersions(allocator); //, args[2..]);
        } else if (std.mem.eql(u8, args[1], "dev")) {
            return try dev.cmdDev(allocator);
        } else if (std.mem.eql(u8, args[1], "old")) {
            return dev.cmdOld(allocator);
        } else if (std.mem.eql(u8, args[1], "help")) {
            return help.cmdHelp(allocator);
        } else {
            return help.cmdHelp(allocator);
        }
    } else {
        return help.cmdHelp(allocator);
    }
}
