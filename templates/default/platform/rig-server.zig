// const std = @import("std");

// const fzwatch = @import("fzwatch");
// const zap = @import("zap");
// const watcher = @import("watcher.zig");
// const server = @import("server.zig");

// // const builtins = @import("builtins"); // roc builtins...

// // Global atomic shutdown flag (thread-safe)
// var shutdown_flag = std.atomic.Value(bool).init(false);

// // Signal handler: Sets the shutdown flag on SIGINT
// fn signalHandler(sig: c_int) callconv(.c) void {
//     _ = sig;
//     shutdown_flag.store(true, .release);
//     std.log.info("[Main Thread] SIGINT received. Initiating graceful shutdown...", .{});
// }

// pub fn cmdOld(allocator: std.mem.Allocator) !void {

//     // TODO: old stuff... move into the roc platform web host... the cli is just for watching, and spawning... and notifying file changes...

//     server.GlobalContextManager = server.ContextManager.init(allocator, "chatroom", "user-");
//     defer server.GlobalContextManager.deinit();

//     const sigint_action = std.os.linux.Sigaction{
//         .handler = .{ .handler = signalHandler },
//         .mask = std.mem.zeroes(std.os.linux.sigset_t),
//         .flags = 0,
//     };

//     // apparently this returns 0 = success, and -1 for failure?
//     const rc: usize = std.os.linux.sigaction(std.os.linux.SIG.INT, &sigint_action, null); // Returns usize (syscall)

//     std.log.info("SIGINT sigaction(): rc = '{}'.", .{rc});

//     std.log.info("SIGINT handler installed. Press Ctrl+C to shutdown gracefully.", .{});

//     // setup listener
//     var listener = zap.HttpListener.init(
//         .{
//             .port = 3010,
//             .on_request = server.on_request,
//             .on_upgrade = server.on_upgrade,
//             .max_clients = 1000,
//             .max_body_size = 1 * 1024,
//             // .public_folder = "public",
//             .log = true,
//         },
//     );

//     //if (server.HotReload.getInheritedFd()) |fd| {
//     //std.log.info("HOT RELOAD SUCCESS — reusing socket fd {}", .{fd});
//     // DO NOT call listener.listen() — zap will auto-use the inherited socket
//     //} else {
//     std.log.info("Fresh start — binding to port 3010", .{});
//     listener.listen() catch |err| switch (err) {
//         error.ListenError => {
//             std.log.info("Got error.ListenError, something is probably already listening on the same port that we want to bind to... ignoring it...", .{});
//         },
//         error.NoSpaceLeft => {
//             std.log.info("Got error.NoSpaceLeft, ignoring it...", .{});
//         },
//     };
//     //server.HotReload.saveListeningFd(); // Remember FD for next reload
//     //}

//     std.log.info("", .{});
//     //const maybe_fd = zap.getListeningFd();
//     //if (maybe_fd) |fd| {
//     //std.log.info("[Main Thread] Hot-reloaded process — reusing inherited socket fd {}", .{fd});
//     //try listener.listenOnFd(fd);
//     //} else {
//     //std.log.info("[Main Thread] Fresh process — binding to port 3010", .{});
//     //try listener.listen();
//     //}

//     std.log.info("", .{});
//     std.log.info("[Main Thread] Connect with browser to http://localhost:3010.", .{});
//     std.log.info("[Main Thread] Connect to websocket on ws://localhost:3010.", .{});
//     std.log.info("[Main Thread] Terminate with CTRL+C", .{});

//     // this blocks the thread...

//     const server_thread = try std.Thread.spawn(.{}, server.serverThread, .{});

//     var watcher_instance = try fzwatch.Watcher.init(allocator);
//     defer watcher_instance.deinit();

//     try watcher_instance.addFile("/home/anon/Projects/rig/src/main.zig");
//     watcher_instance.setCallback(callbackv2, null);

//     const watcher_thread = try std.Thread.spawn(.{}, watcher.watcherThread, .{&watcher_instance});

//     // Main thread: Loop until shutdown flag
//     var i: usize = 0;
//     while (!shutdown_flag.load(.acquire)) : (i += 1) { // Snake_case: .acquire
//         std.Thread.sleep(100 * std.time.ns_per_ms); // 100ms; tune for responsiveness vs CPU
//     }

//     std.log.info("[Main Thread] exiting. Stopping server...", .{});
//     zap.stop();
//     watcher_instance.stop();

//     server_thread.join();
//     watcher_thread.join();

//     std.log.info("[Main Thread] All threads joined. Exiting.", .{});
// }

// pub fn callbackv2(context: ?*anyopaque, event: fzwatch.Event) void {
//     _ = context;

//     std.log.info("[Watcher Thread] Event recieved... '{}'", .{event});

//     if (event != .modified) return;

//     std.log.info("[Watcher Thread] Source changed — rebuilding...", .{});

//     // 1. Rebuild the project
//     const result = std.process.Child.run(.{
//         .allocator = std.heap.page_allocator,
//         .argv = &[_][]const u8{ "zig", "build" }, // , "-Doptimize=ReleaseFast"
//         // .cwd = std.fs.cwd(),
//     }) catch |err| {
//         std.log.err("[Watcher Thread] Build failed: {}", .{err});
//         server.WebsocketHandler.publish(.{ .channel = "chatroom", .message =
//             \\{"type":"build_error","error":"Build failed"}
//         });
//         return;
//     };
//     defer std.heap.page_allocator.free(result.stdout);
//     defer std.heap.page_allocator.free(result.stderr);

//     if (result.term != .Exited or result.term.Exited != 0) {
//         std.log.err("[Watcher Thread] Build failed with exit code: {}", .{result.term});
//         server.WebsocketHandler.publish(.{ .channel = "chatroom", .message =
//             \\{"type":"build_error","error":"Compilation failed"}
//         });
//         return;
//     } else {
//         std.log.info("Zig stdout:\n{s}", .{result.stdout});
//         std.log.info("Zig stderr:\n{s}", .{result.stderr});
//     }

//     const mes1 = std.fmt.allocPrint(std.heap.page_allocator,
//         \\{{
//         \\  "type": "hot_reload",
//         \\  "cmd": "zig build",
//         \\  "exit_code": "{d}",
//         \\  "stdout": "{s}",
//         \\  "stderr": "{s}",
//         \\  "files": ["/main.wasm" /* placeholder, not real */],
//         \\}}
//     , .{
//         result.term.Exited,
//         result.stdout,
//         result.stderr,
//     }) catch unreachable;

//     server.WebsocketHandler.publish(.{ .channel = "chatroom", .message = mes1 });

//     std.log.info("Spawning roc: ./roc ./my-roc-app/app.roc", .{});

//     const result2 = std.process.Child.run(.{
//         .allocator = std.heap.page_allocator,
//         .argv = &[_][]const u8{
//             "roc", "./my-roc-app/app.roc", //
//             // "--output", "public/main.wasm", //
//             // "--target", "wasm", //
//             // "--no-link", //
//         },
//     }) catch |err| {
//         std.log.err("Failed to spawn roc: {}", .{err});
//         return;
//     };
//     defer {
//         std.heap.page_allocator.free(result2.stdout);
//         std.heap.page_allocator.free(result2.stderr);
//     }

//     if (result2.term != .Exited or result2.term.Exited != 0) {
//         std.log.err("[Watcher Thread] Build failed with exit code: {}", .{result2.term});
//         server.WebsocketHandler.publish(.{ .channel = "chatroom", .message =
//             \\{"type":"build_error","error":"Compilation failed"}
//         });
//         return;
//     } else {
//         std.log.info("Roc stdout:\n{s}", .{result2.stdout});
//         std.log.info("Roc stderr:\n{s}", .{result2.stderr});
//     }

//     std.log.info("[Watcher Thread] Build succeeded — swapping binary...", .{});

//     const mes2 = std.fmt.allocPrint(std.heap.page_allocator,
//         \\{{
//         \\  "type": "hot_reload",
//         \\  "cmd": "roc ./my-roc-app/app.roc",
//         \\  "exit_code": "{d}",
//         \\  "stdout": "{s}",
//         \\  "stderr": "{s}",
//         \\  "files": ["/main.wasm" /* placeholder, not real */],
//         \\}}
//     , .{
//         result2.term.Exited,
//         result2.stdout,
//         result2.stderr,
//     }) catch unreachable;

//     server.WebsocketHandler.publish(.{ .channel = "chatroom", .message = mes2 });

//     // 3. Wait a tiny bit for message to flush
//     // std.time.sleep(100 * std.time.ns_per_ms);

//     // 4. EXECVE INTO THE NEW BINARY — THIS REPLACES THE CURRENT PROCESS
//     const new_binary = "./zig-out/bin/rig"; // or "./zig-out/bin/rig" depending on your build.zig

//     std.log.info("[Watcher Thread] Executing new binary: {s}", .{new_binary});

//     //
//     // TODO: Implement execve, without dropping connections... it currently drops...
//     //

//     // Before execve, make sure the env var is preserved!
//     //const argv: [*:null]const ?[*:0]const u8 = @ptrCast(std.os.argv.ptr);
//     //const envp: [*:null]const ?[*:0]const u8 = @ptrCast(std.c.environ);

//     //_ = std.posix.execveZ("./zig-out/bin/rig", argv, envp) catch {}; //  catch |err| switch (err) {};
//     //unreachable;
// }
