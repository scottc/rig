const std = @import("std");
const fzwatch = @import("fzwatch");

// Watcher thread: Start the watcher, then loop + check flag
pub fn watcherThread(watcher: *fzwatch.Watcher) void {
    std.log.info("[Watcher Thread] File watcher starting....", .{});

    // Start watching (latency=1.0s default for event coalescing; adjust as needed)
    watcher.start(.{ .latency = 1.0 }) catch |err| {
        std.log.err("[Watcher Thread] Watcher start error: {}", .{err});
        return;
    };

    std.log.info("[Watcher Thread] File watcher stopped.", .{});
}
