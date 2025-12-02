const std = @import("std");

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn greet(name: [*]const u8, len: usize) void {
    const slice = name[0..len];
    std.log.info("Hello from WASM, {s}!", .{slice});
}

// Optional: panic handler
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = msg;
    unreachable;
}
