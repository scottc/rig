const std = @import("std");

pub fn cmdDev(allocator: std.mem.Allocator) !void {
    // Find rig.toml or default to src/app.roc
    const entrypoint = findEntrypoint(allocator) catch |err| {
        std.log.err("No entrypoint found. Run 'rig init' first. {}", .{err});
        return;
    };
    defer allocator.free(entrypoint);

    std.log.info("Running rig dev", .{});

    while (true) {
        std.log.info("./my-roc-app: roc main.roc", .{});

        // Spawn platform child
        var child = std.process.Child.init(&.{ "roc", "main.roc" }, allocator);
        child.cwd = "./my-roc-app";
        // catch |err| {
        //     std.log.err("Failed to spawn roc to compile and run the app...", .{err});
        //    return;
        //};
        child.stdin_behavior = .Inherit;
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;

        const term = child.spawnAndWait() catch |err| {
            std.log.err("Child process failed: {}", .{err});
            return;
        };

        if (term == .Exited and term.Exited != 0) {
            std.log.err("Platform exited with code {}", .{term.Exited});
        }
    }
}

pub fn findEntrypoint(allocator: std.mem.Allocator) ![]u8 {
    _ = allocator;
    if (true) {
        return "";
    } else {
        return error.NotFound;
    }
}
