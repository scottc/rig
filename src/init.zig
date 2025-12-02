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

pub fn cmdInitLuke(allocator: std.mem.Allocator) !void { // , args: [][]const u8
    _ = allocator;

    std.log.info("Starting Project Scaffold...", .{});

    const project_name =
        //if (args.len > 0 and args[0].len > 0) args[0] else
        "my-roc-app";

    std.log.info("Creating new Roc app: {s}", .{project_name});

    try std.fs.cwd().makeDir(project_name);
    var dir = try std.fs.cwd().openDir(project_name, .{});
    defer dir.close();

    //std.log.info("git clone https://github.com/lukewilliamboswell/roc-platform-template-zig.git#2b673585e3aef445d1665d7c2c3ff8d35a15ae84 ./my-roc-app", .{});
    //const result = std.process.Child.run(.{
    //    .allocator = std.heap.page_allocator,
    //    .argv = &[_][]const u8{ "git", "clone", "https://github.com/lukewilliamboswell/roc-platform-template-zig.git", "./my-roc-app" }, // , "-Doptimize=ReleaseFast"
    //    //.cwd = "./platform",
    //}) catch |err| {
    //    std.log.err("Git clone failed: {}", .{err});
    //    return;
    //};
    //defer std.heap.page_allocator.free(result.stdout);
    //defer std.heap.page_allocator.free(result.stderr);

    //std.log.info(
    //    \\Exit Code: "{b}"
    //    \\Stdout: "{s}"
    //    \\Stderr: "{s}"
    //, .{
    //    result.term.Exited,
    //    result.stdout,
    //    result.stderr,
    //});

    // std.log.info("Patching ./build.zig.zon to static roc version...\ncommit-id:1048ddeae90176e7dd92f9a3932837a248d94638\nzig-hash:roc-0.0.0-NAC9wzW5egD54uShMyfx5D5CP2_ZHwNfmW0AGZHkDE_f", .{});

    // try dir.deleteFile("build.zig.zon");
    // const zonFile = try dir.createFile(
    //    "build.zig.zon",
    //    .{ .read = true },
    //);
    //defer zonFile.close();
    //try zonFile.writeAll(
    //    \\.{
    //    \\    .name = .roc_platform_template_zig,
    //    \\    .version = "0.1.0",
    //    \\    .minimum_zig_version = "0.15.2",
    //    \\    .dependencies = .{
    //    \\        .roc = .{
    //    \\            .url = "git+https://github.com/roc-lang/roc#1048ddeae90176e7dd92f9a3932837a248d94638",
    //    \\            .hash = "roc-0.0.0-NAC9wzW5egD54uShMyfx5D5CP2_ZHwNfmW0AGZHkDE_f",
    //    \\        },
    //    \\    },
    //    \\    .fingerprint = 0xb91745a94628a7e0,
    //    \\    .paths = .{
    //    \\        "build.zig",
    //    \\        "build.zig.zon",
    //    \\        "platform",
    //    \\    },
    //    \\}
    //);

    // Create directories
    //try dir.makeDir("src");
    //try dir.makeDir("public");
    //try dir.makeDir("platform"); // handled by git clone...

    // Write src/app.roc
    //const rocMainAppFile = try dir.createFile(
    //    "src/main.roc",
    //    .{ .read = true },
    //);
    //defer rocMainAppFile.close();
    //try rocMainAppFile.writeAll(
    //    //\\# app [main!] { pf: platform "../platform/3UcxdhtriBxudh4C2DB9VhPF5ahx1q4z3DSNTwqohZZk.tar.zst" }
    //    \\app [main!] { pf: platform "../platform/main.roc" }
    //    \\
    //    \\import pf.Stdout
    //    \\
    //    \\main! : List(Str) => Try({}, [Exit(I32)])
    //    \\main! = |args| {
    //    \\    Stdout.line!("Hello Roc!")
    //    \\
    //    \\    args_str = Str.join_with(args, ", ")
    //    \\    Stdout.line!("Args: ${args_str}")
    //    \\
    //    \\    Ok({})
    //   \\}
    //);

    //const indexFile = try dir.createFile(
    //    "public/index.html",
    //    .{ .read = true },
    //);
    //defer indexFile.close();
    //try indexFile.writeAll(
    //    \\<!DOCTYPE html>
    //    \\<html><head><meta charset="utf-8"><title>Roc App</title>
    //    \\<style>body{font-family:system-ui;margin:40px;background:#0d1117;color:#c9d1d9}</style>
    //    \\</head><body>
    //    \\<h1>Roc app running...<pre id="out"></pre>
    //    \\<script type="module">
    //    \\  const ws = new WebSocket("ws://localhost:3010/ws");
    //    \\  ws.onmessage = (e) => {
    //    \\    try { const d = JSON.parse(e.data);
    //    \\      if (d.type === "roc_output") {
    //    \\        const pre = document.getElementById("out");
    //    \\        pre.innerHTML = "";
    //    \\        for (const line of d.stdout) pre.innerHTML += line + "<br>";
    //    \\        for (const line of d.stderr) pre.innerHTML += "<span style='color:#f85149'>" + line + "</span><br>";
    //    \\      }
    //    \\    } catch (_) { document.getElementById("out").innerHTML += e.data + "<br>"; }
    //    \\  };
    //    \\</script>
    //    \\</body></html>
    //);

    std.log.info("cp -a ./templates/luke/. ./my-roc-app", .{});
    const result1 = std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        // the -a flag, is recursive, and keep attributes and preserve symlinks... and the trailing ".", preserves hidden files too...
        .argv = &[_][]const u8{ "cp", "-a", "./templates/luke/.", "./my-roc-app/" }, // , "-Doptimize=ReleaseFast"
    }) catch |err| {
        std.log.err("cp failed: {}", .{err});
        return;
    };
    defer std.heap.page_allocator.free(result1.stdout);
    defer std.heap.page_allocator.free(result1.stderr);

    std.log.info(
        \\Exit Code: "{b}"
        \\Stdout: "{s}"
        \\Stderr: "{s}"
    , .{
        result1.term.Exited,
        result1.stdout,
        result1.stderr,
    });

    std.log.info("zig build", .{});
    const result2 = std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{ "zig", "build" }, // , "-Doptimize=ReleaseFast"
        .cwd = "./my-roc-app",
    }) catch |err| {
        std.log.err("zig build failed: {}", .{err});
        return;
    };
    defer std.heap.page_allocator.free(result2.stdout);
    defer std.heap.page_allocator.free(result2.stderr);

    std.log.info(
        \\Exit Code: "{b}"
        \\Stdout: "{s}"
        \\Stderr: "{s}"
    , .{
        result2.term.Exited,
        result2.stdout,
        result2.stderr,
    });

    std.log.info("./my-roc-app/bundle.sh", .{});
    const result3 = std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{"./bundle.sh"}, // , "-Doptimize=ReleaseFast"
        .cwd = "./my-roc-app",
    }) catch |err| {
        std.log.err("bundle.sh failed: {}", .{err});
        return;
    };
    defer std.heap.page_allocator.free(result3.stdout);
    defer std.heap.page_allocator.free(result3.stderr);

    std.log.info(
        \\Exit Code: "{d}"
        \\Stdout: "{s}"
        \\Stderr: "{s}"
    , .{
        result3.term.Exited,
        result3.stdout,
        result3.stderr,
    });

    // std.log.info("roc ./my-roc-app/src/main.roc", .{});
    // const result4 = std.process.Child.run(.{
    //     .allocator = std.heap.page_allocator,
    //     .argv = &[_][]const u8{ "roc", "./src/main.roc" }, // , "-Doptimize=ReleaseFast"
    //     .cwd = "./my-roc-app",
    // }) catch |err| {
    //     std.log.err("roc failed: {}", .{err});
    //     return;
    // };
    // defer std.heap.page_allocator.free(result4.stdout);
    // defer std.heap.page_allocator.free(result4.stderr);

    // std.log.info(
    //     \\Exit Code: "{d}"
    //     \\Stdout: "{s}"
    //     \\Stderr: "{s}"
    // , .{
    //     result4.term.Exited,
    //     result4.stdout,
    //     result4.stderr,
    // });

    std.log.info("Project created!", .{});

    // TODO: list files...

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
