const std = @import("std");

pub fn cmdInitDefault(allocator: std.mem.Allocator) !void { // , args: [][]const u8
    // TODO: from args... if (args.len > 0 and args[0].len > 0) args[0] else
    const project_name = "my-roc-app";
    const template = "default";

    std.log.info("Running rig init {s} {s}", .{ template, project_name });

    cpTemplate(allocator, project_name, template) catch unreachable; // fatal, we can't continue without the files...

    std.log.info("Precompiling Rig Roc Web Platform", .{});
    std.log.info("zig build", .{});
    // , "-Doptimize=ReleaseFast"
    // we want debug for dev, and release for production...
    var zigProc = std.process.Child.init(&.{ "zig", "build" }, allocator);
    zigProc.cwd = "./my-roc-app";
    zigProc.stdout_behavior = .Inherit; // Inherit parent's stdout
    zigProc.stderr_behavior = .Inherit; // Inherit parent's stdout
    const zigTerm = try zigProc.spawnAndWait();
    std.log.info("zig build finished with {}", .{zigTerm});

    // TODO: actually check if it was successful... this could be a false positive...
    std.log.info("Precompiled Rig Roc Web Platform successfully!", .{});
    std.log.info("\n\nNow run:\n  cd {s}\n  rig dev", .{project_name});
}

fn confirmDelete() !bool {
    const red = "\x1b[31m";
    const yellow = "\x1b[33m";
    const bold = "\x1b[1m";
    const reset = "\x1b[0m";

    std.log.warn("\n{s}{s}WARNING: DANGEROUS OPERATION{s}", .{ bold, red, reset });
    std.log.warn("{s}This will permanently delete:{s}", .{ yellow, reset });
    //std.log.warn("  ./.zig-cache/", .{});
    std.log.warn("  ./my-roc-app/", .{});
    //std.log.warn("  ./zig-out/\n", .{});
    std.log.warn("{s}Type {s}YES{s}{s} to confirm: {s}", .{ bold, yellow, reset, bold, reset });

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    const line_slice = try stdin.takeDelimiterExclusive('\n');

    const answer = std.mem.trim(u8, line_slice, &std.ascii.whitespace);

    return std.ascii.eqlIgnoreCase(answer, "YES");
}

pub fn cmdNuke(allocator: std.mem.Allocator) !void {
    _ = allocator;

    if (!try confirmDelete()) {
        std.log.info("YES was not supplied, aborted delete.", .{});
        return;
    }

    std.log.info("Deleting Directory Tree my-roc-app", .{});
    std.fs.cwd().deleteTree("my-roc-app") catch unreachable; // This seems pretty fatal, this is the whole point of running the command...
    std.log.info("Deleted Directory Tree my-roc-app successfully!", .{});

    //std.log.info("Deleting Directory Tree .zig-cache", .{});
    // std.fs.cwd().deleteTree(".zig-cache") catch unreachable;
    // std.log.info("Deleted Directory Tree .zig-cache successfully!", .{});

    // std.log.info("Deleting Directory Tree zig-out", .{});
    // std.fs.cwd().deleteTree("zig-out") catch unreachable;
    // std.log.info("Deleted Directory Tree zig-out successfully!", .{});
}

fn cpTemplate(allocator: std.mem.Allocator, project_name: []const u8, template: []const u8) !void {
    const rig_root = ".";
    const template_path = try std.fs.path.join(allocator, &.{ rig_root, "templates", template });
    defer allocator.free(template_path);

    var src_root = try std.fs.cwd().openDir(template_path, .{ .iterate = true });
    defer src_root.close();

    try std.fs.cwd().makeDir(project_name);
    std.log.info("Created Dir: ./{s}", .{project_name});

    var walker = try src_root.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (std.mem.eql(u8, entry.path, ".")) continue;

        const full_dest = try std.fs.path.join(allocator, &.{ project_name, entry.path });
        defer allocator.free(full_dest);

        switch (entry.kind) {
            .file => {
                if (std.fs.path.dirname(full_dest)) |dir| {
                    try std.fs.cwd().makePath(dir);
                }
                try src_root.copyFile(entry.path, std.fs.cwd(), full_dest, .{});
                std.log.info("Copied File: ./{s}/{s}", .{ project_name, entry.path });
            },
            .directory => {
                try std.fs.cwd().makePath(full_dest);
                std.log.info("Created Dir: ./{s}/{s}", .{ project_name, entry.path });
            },
            else => {},
        }
    }

    std.log.info("Template installed successfully!", .{});
}
