///! Platform host that tests effectful functions writing to stdout and stderr.
const std = @import("std");
const builtins = @import("builtins");
const layout = @import("layout");

const dev_server = @import("dev_server.zig");

// Use the actual types from builtins
const RocStr = builtins.str.RocStr;
const RocList = builtins.list.RocList;
const RocOps = builtins.host_abi.RocOps;

/// Host environment
const HostEnv = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
};

/// Roc allocation function with size-tracking metadata
fn rocAllocFn(roc_alloc: *builtins.host_abi.RocAlloc, env: *anyopaque) callconv(.c) void {
    const host: *HostEnv = @ptrCast(@alignCast(env));
    const allocator = host.gpa.allocator();

    const align_enum = std.mem.Alignment.fromByteUnits(@as(usize, @intCast(roc_alloc.alignment)));

    // Calculate additional bytes needed to store the size
    const size_storage_bytes = @max(roc_alloc.alignment, @alignOf(usize));
    const total_size = roc_alloc.length + size_storage_bytes;

    // Allocate memory including space for size metadata
    const result = allocator.rawAlloc(total_size, align_enum, @returnAddress());

    const base_ptr = result orelse {
        const stderr: std.fs.File = .stderr();
        stderr.writeAll("\x1b[31mHost error:\x1b[0m allocation failed, out of memory\n") catch {};
        std.process.exit(1);
    };

    // Store the total size (including metadata) right before the user data
    const size_ptr: *usize = @ptrFromInt(@intFromPtr(base_ptr) + size_storage_bytes - @sizeOf(usize));
    size_ptr.* = total_size;

    // Return pointer to the user data (after the size metadata)
    roc_alloc.answer = @ptrFromInt(@intFromPtr(base_ptr) + size_storage_bytes);

    std.log.debug("[ALLOC] ptr=0x{x} size={d} align={d}", .{ @intFromPtr(roc_alloc.answer), roc_alloc.length, roc_alloc.alignment });
}

/// Roc deallocation function with size-tracking metadata
fn rocDeallocFn(roc_dealloc: *builtins.host_abi.RocDealloc, env: *anyopaque) callconv(.c) void {
    std.log.debug("[DEALLOC] ptr=0x{x} align={d}", .{ @intFromPtr(roc_dealloc.ptr), roc_dealloc.alignment });

    const host: *HostEnv = @ptrCast(@alignCast(env));
    const allocator = host.gpa.allocator();

    // Calculate where the size metadata is stored
    const size_storage_bytes = @max(roc_dealloc.alignment, @alignOf(usize));
    const size_ptr: *const usize = @ptrFromInt(@intFromPtr(roc_dealloc.ptr) - @sizeOf(usize));

    // Read the total size from metadata
    const total_size = size_ptr.*;

    // Calculate the base pointer (start of actual allocation)
    const base_ptr: [*]u8 = @ptrFromInt(@intFromPtr(roc_dealloc.ptr) - size_storage_bytes);

    // Calculate alignment
    const log2_align = std.math.log2_int(u32, @intCast(roc_dealloc.alignment));
    const align_enum: std.mem.Alignment = @enumFromInt(log2_align);

    // Free the memory (including the size metadata)
    const slice = @as([*]u8, @ptrCast(base_ptr))[0..total_size];
    allocator.rawFree(slice, align_enum, @returnAddress());
}

/// Roc reallocation function with size-tracking metadata
fn rocReallocFn(roc_realloc: *builtins.host_abi.RocRealloc, env: *anyopaque) callconv(.c) void {
    const host: *HostEnv = @ptrCast(@alignCast(env));
    const allocator = host.gpa.allocator();

    // Calculate where the size metadata is stored for the old allocation
    const size_storage_bytes = @max(roc_realloc.alignment, @alignOf(usize));
    const old_size_ptr: *const usize = @ptrFromInt(@intFromPtr(roc_realloc.answer) - @sizeOf(usize));

    // Read the old total size from metadata
    const old_total_size = old_size_ptr.*;

    // Calculate the old base pointer (start of actual allocation)
    const old_base_ptr: [*]u8 = @ptrFromInt(@intFromPtr(roc_realloc.answer) - size_storage_bytes);

    // Calculate new total size needed
    const new_total_size = roc_realloc.new_length + size_storage_bytes;

    // Perform reallocation
    const old_slice = @as([*]u8, @ptrCast(old_base_ptr))[0..old_total_size];
    const new_slice = allocator.realloc(old_slice, new_total_size) catch {
        const stderr: std.fs.File = .stderr();
        stderr.writeAll("\x1b[31mHost error:\x1b[0m reallocation failed, out of memory\n") catch {};
        std.process.exit(1);
    };

    // Store the new total size in the metadata
    const new_size_ptr: *usize = @ptrFromInt(@intFromPtr(new_slice.ptr) + size_storage_bytes - @sizeOf(usize));
    new_size_ptr.* = new_total_size;

    // Return pointer to the user data (after the size metadata)
    roc_realloc.answer = @ptrFromInt(@intFromPtr(new_slice.ptr) + size_storage_bytes);

    std.log.debug("[REALLOC] old=0x{x} new=0x{x} new_size={d}", .{ @intFromPtr(old_base_ptr) + size_storage_bytes, @intFromPtr(roc_realloc.answer), roc_realloc.new_length });
}

/// Roc debug function
fn rocDbgFn(roc_dbg: *const builtins.host_abi.RocDbg, env: *anyopaque) callconv(.c) void {
    _ = env;
    const message = roc_dbg.utf8_bytes[0..roc_dbg.len];
    std.log.debug("\x1b[33mRoc dbg:\x1b[0m {s}", .{message});
}

/// Roc expect failed function
fn rocExpectFailedFn(roc_expect: *const builtins.host_abi.RocExpectFailed, env: *anyopaque) callconv(.c) void {
    _ = env;
    const source_bytes = roc_expect.utf8_bytes[0..roc_expect.len];
    const trimmed = std.mem.trim(u8, source_bytes, " \t\n\r");
    std.log.debug("\x1b[33mExpect failed:\x1b[0m {s}", .{trimmed});
}

/// Roc crashed function
fn rocCrashedFn(roc_crashed: *const builtins.host_abi.RocCrashed, env: *anyopaque) callconv(.c) noreturn {
    _ = env;
    const message = roc_crashed.utf8_bytes[0..roc_crashed.len];
    const stderr: std.fs.File = .stderr();
    var buf: [256]u8 = undefined;
    var w = stderr.writer(&buf);
    w.interface.print("\n\x1b[31mRoc crashed:\x1b[0m {s}\n", .{message}) catch {};
    w.interface.flush() catch {};
    std.process.exit(1);
}

// External symbols provided by the Roc runtime object file
// Follows RocCall ABI: ops, ret_ptr, then argument pointers
extern fn roc__main_for_host(ops: *builtins.host_abi.RocOps, ret_ptr: *anyopaque, arg_ptr: ?*anyopaque) callconv(.c) void;

// OS-specific entry point handling
comptime {
    // Export main for all platforms
    @export(&main, .{ .name = "main" });

    // Windows MinGW/MSVCRT compatibility: export __main stub
    if (@import("builtin").os.tag == .windows) {
        @export(&__main, .{ .name = "__main" });
    }
}

// Windows MinGW/MSVCRT compatibility stub
// The C runtime on Windows calls __main from main for constructor initialization
fn __main() callconv(.c) void {}

// C compatible main for runtime
fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    return platform_main(@intCast(argc), argv);
}

/// Hosted function: Stderr.line! (index 0 - sorted alphabetically)
/// Follows RocCall ABI: (ops, ret_ptr, args_ptr)
/// Returns {} and takes Str as argument
fn hostedStderrLine(ops: *builtins.host_abi.RocOps, ret_ptr: *anyopaque, args_ptr: *anyopaque) callconv(.c) void {
    _ = ops;
    _ = ret_ptr; // Return value is {} which is zero-sized

    // Arguments struct for single Str parameter
    const Args = extern struct { str: builtins.str.RocStr };
    const args: *Args = @ptrCast(@alignCast(args_ptr));

    const message = args.str.asSlice();
    const stderr: std.fs.File = .stderr();
    stderr.writeAll(message) catch {};
    stderr.writeAll("\n") catch {};
}

/// Hosted function: Stdout.line! (index 2 - sorted alphabetically)
/// Follows RocCall ABI: (ops, ret_ptr, args_ptr)
/// Returns {} and takes Str as argument
fn hostedStdoutLine(ops: *builtins.host_abi.RocOps, ret_ptr: *anyopaque, args_ptr: *anyopaque) callconv(.c) void {
    _ = ops;
    _ = ret_ptr; // Return value is {} which is zero-sized

    // Arguments struct for single Str parameter
    const Args = extern struct { str: RocStr };
    const args: *Args = @ptrCast(@alignCast(args_ptr));

    const message = args.str.asSlice();
    const stdout: std.fs.File = .stdout();
    stdout.writeAll(message) catch {};
    stdout.writeAll("\n") catch {};
}

fn hostedClientFetch(ops: *builtins.host_abi.RocOps, ret_ptr: *anyopaque, args_ptr: *anyopaque) callconv(.c) void {
    // Arguments struct for single Str parameter
    const Args = extern struct {
        url: RocStr,
        method: RocStr,
        headers: RocStr, // This is actually a RocList(RocRecord({ name: RocStr, value RocStr }))
        body: RocStr,
    };
    const args: *Args = @ptrCast(@alignCast(args_ptr));

    const url = args.url.asSlice();
    const method = args.method.asSlice();
    //const headers = args.method.asSlice(); // This is actually a RocList(RocRecord({ name: RocStr, value RocStr }))
    const body = args.method.asSlice();

    std.log.info("Fetching: {s} {s} <-\n{s}", .{ method, url, body });

    var client: std.http.Client = .{ .allocator = std.heap.page_allocator };
    defer client.deinit();

    // const uri = std.Uri.parse(url);

    // This seems to only return the status code... we probs want to dig deeper...
    const fetchResult = client.fetch(.{
        .location = .{ .url = url },
        // .method = ,
        // .payload = ,
        // .headers = ,
    }) catch unreachable;

    //if (fetchResult) |fr| {
    std.log.info("Fetch Response: {s} {s} ->\n{s}", .{ method, url, @tagName(fetchResult.status) });
    //} else {
    // std.log.error("Fetch Error: ...", .{ method, url });
    //}

    const response = "Something happened"; //fetchResult.status;

    // Return the string to roc...

    // Allocate through Roc's allocation system to ensure proper size-tracking metadata
    var roc_alloc_args = builtins.host_abi.RocAlloc{
        .alignment = 1,
        .length = response.len,
        .answer = undefined,
    };
    ops.roc_alloc(&roc_alloc_args, ops.env);

    // Copy line data to the Roc-allocated memory
    const line_copy: [*]u8 = @ptrCast(roc_alloc_args.answer);
    @memcpy(line_copy[0..response.len], response);

    // Create RocStr from the read line and return it
    const result: *RocStr = @ptrCast(@alignCast(ret_ptr));
    result.* = RocStr.init(line_copy, response.len, ops);
}

/// Hosted function: ZServer.serve! (index 3 - sorted alphabetically)
/// Follows RocCall ABI: (ops, ret_ptr, args_ptr)
/// Returns {} and takes () as argument
fn hostedServerServe(ops: *builtins.host_abi.RocOps, ret_ptr: *anyopaque, args_ptr: *anyopaque) callconv(.c) void {
    _ = ops;
    _ = ret_ptr;

    // Arguments struct for single Str parameter
    const Args = extern struct { str: RocStr };
    const args: *Args = @ptrCast(@alignCast(args_ptr));

    const str = args.str.asSlice();

    const stdout: std.fs.File = .stdout();

    std.log.info("Setting request handler... '{s}'\n", .{str});
    dev_server.placeholder_request_handler = str;

    stdout.writeAll("Starting server...\n") catch {};
    _ = dev_server.startDevServer(std.heap.page_allocator);
}

fn hostedFileDirRead(ops: *builtins.host_abi.RocOps, ret_ptr: *anyopaque, args_ptr: *anyopaque) callconv(.c) void {
    const Args = extern struct { str: RocStr };
    const args: *Args = @ptrCast(@alignCast(args_ptr));
    const path = args.str.asSlice();

    const stdout: std.fs.File = .stdout();
    stdout.writeAll("Reading Dir: ") catch {};
    stdout.writeAll(path) catch {};

    var buffer: [1024]u8 = undefined; // Temp for collecting dir contents
    var buf_len: usize = 0;

    var dir = std.fs.cwd().openDir(path, .{ .iterate = true }) catch return;
    defer dir.close();

    const allocator = std.heap.page_allocator;

    var walker = dir.walk(allocator) catch return;
    defer walker.deinit();

    while (walker.next() catch return) |entry| {
        if (std.mem.eql(u8, entry.path, ".")) continue;

        switch (entry.kind) {
            .file => {
                const name = entry.path;
                if (buf_len + name.len < buffer.len) {
                    @memcpy(buffer[buf_len..][0..name.len], name);
                    buf_len += name.len;
                }
            },
            .directory => {
                const name = entry.path;
                if (buf_len + name.len < buffer.len) {
                    @memcpy(buffer[buf_len..][0..name.len], name);
                    buf_len += name.len;
                }
            },
            else => {},
        }
    }

    const response = buffer[0..buf_len];

    // Allocate through Roc's allocation system to ensure proper size-tracking metadata
    var roc_alloc_args = builtins.host_abi.RocAlloc{
        .alignment = 1,
        .length = response.len,
        .answer = undefined,
    };
    ops.roc_alloc(&roc_alloc_args, ops.env);

    // Copy line data to the Roc-allocated memory
    const line_copy: [*]u8 = @ptrCast(roc_alloc_args.answer);
    @memcpy(line_copy[0..response.len], response);

    // Create RocStr from the read line and return it
    const result: *RocStr = @ptrCast(@alignCast(ret_ptr));
    result.* = RocStr.init(line_copy, response.len, ops);
}

fn hostedFileFileRead(ops: *builtins.host_abi.RocOps, ret_ptr: *anyopaque, args_ptr: *anyopaque) callconv(.c) void {
    const Args = extern struct { str: RocStr };
    const args: *Args = @ptrCast(@alignCast(args_ptr));
    const filepath = args.str.asSlice();

    const stdout: std.fs.File = .stdout();
    stdout.writeAll("Reading file: ") catch {};
    stdout.writeAll(filepath) catch {};

    const allocator = std.heap.page_allocator;

    const content = std.fs.cwd().readFileAlloc(
        allocator,
        filepath,
        100 * 1024 * 1024, // 100 MiB max_bytes
    ) catch unreachable;
    defer allocator.free(content);

    stdout.writeAll("Read file: ") catch {};
    stdout.writeAll(content) catch {};

    // Allocate through Roc's allocation system to ensure proper size-tracking metadata
    var roc_alloc_args = builtins.host_abi.RocAlloc{
        .alignment = 1,
        .length = content.len,
        .answer = undefined,
    };
    ops.roc_alloc(&roc_alloc_args, ops.env);

    // Copy line data to the Roc-allocated memory
    const line_copy: [*]u8 = @ptrCast(roc_alloc_args.answer);
    @memcpy(line_copy[0..content.len], content);

    // Create RocStr from the read line and return it
    const result: *RocStr = @ptrCast(@alignCast(ret_ptr));
    result.* = RocStr.init(line_copy, content.len, ops);
}

fn hostedFileFileWrite(ops: *builtins.host_abi.RocOps, ret_ptr: *anyopaque, args_ptr: *anyopaque) callconv(.c) void {
    const Args = extern struct { str1: RocStr, str2: RocStr };
    const args: *Args = @ptrCast(@alignCast(args_ptr));
    const filepath = args.str1.asSlice();
    const filecontent = args.str2.asSlice();

    const stdout: std.fs.File = .stdout();
    stdout.writeAll("Writing file: ") catch {};
    stdout.writeAll(filepath) catch {};

    std.fs.cwd().writeFile(.{
        .sub_path = filepath,
        .data = filecontent,
    }) catch unreachable;

    // We may need to make directories first, if they don't exist... perhaps a seperate platform api call for this... keep things explict?
    // try std.fs.cwd().makePath(std.fs.path.dirname(file_path) orelse ".");

    stdout.writeAll("Wrote file: ") catch {};
    stdout.writeAll("...") catch {};

    // Allocate through Roc's allocation system to ensure proper size-tracking metadata
    var roc_alloc_args = builtins.host_abi.RocAlloc{
        .alignment = 1,
        .length = filepath.len,
        .answer = undefined,
    };
    ops.roc_alloc(&roc_alloc_args, ops.env);

    // Copy line data to the Roc-allocated memory
    const line_copy: [*]u8 = @ptrCast(roc_alloc_args.answer);
    @memcpy(line_copy[0..filepath.len], filepath);

    // Create RocStr from the read line and return it
    const result: *RocStr = @ptrCast(@alignCast(ret_ptr));
    result.* = RocStr.init(line_copy, filepath.len, ops);
}

/// Array of hosted function pointers, sorted alphabetically by fully-qualified name
/// These correspond to the hosted functions defined in Stderr, and Stdout Type Modules
const hosted_function_ptrs = [_]builtins.host_abi.HostedFn{
    hostedClientFetch,
    hostedFileDirRead,
    hostedFileFileRead,
    hostedFileFileWrite,
    hostedServerServe,
    hostedStderrLine,
    hostedStdoutLine,
};

/// Platform host entrypoint
fn platform_main(argc: usize, argv: [*][*:0]u8) c_int {
    var host_env = HostEnv{
        .gpa = std.heap.GeneralPurposeAllocator(.{}){},
    };

    // Create the RocOps struct
    var roc_ops = builtins.host_abi.RocOps{
        .env = @as(*anyopaque, @ptrCast(&host_env)),
        .roc_alloc = rocAllocFn,
        .roc_dealloc = rocDeallocFn,
        .roc_realloc = rocReallocFn,
        .roc_dbg = rocDbgFn,
        .roc_expect_failed = rocExpectFailedFn,
        .roc_crashed = rocCrashedFn,
        .hosted_fns = .{
            .count = hosted_function_ptrs.len,
            .fns = @constCast(&hosted_function_ptrs),
        },
    };

    std.log.debug("[HOST] Hosted functions count: {d}", .{hosted_function_ptrs.len});

    // Build List(Str) from argc/argv
    std.log.debug("[HOST] Building args...", .{});
    const args_list = buildStrArgsList(argc, argv, &roc_ops);
    std.log.debug("[HOST] args_list ptr=0x{x} len={d}", .{ @intFromPtr(args_list.bytes), args_list.length });

    // Call the app's main! entrypoint - returns I32 exit code
    std.log.debug("[HOST] Calling roc__main_for_host...", .{});

    var exit_code: i32 = -99;
    roc__main_for_host(&roc_ops, @as(*anyopaque, @ptrCast(&exit_code)), @as(*anyopaque, @ptrCast(@constCast(&args_list))));

    std.log.debug("[HOST] Returned from roc, exit_code={d}", .{exit_code});

    // Check for memory leaks before returning
    const leak_status = host_env.gpa.deinit();
    if (leak_status == .leak) {
        std.log.err("\x1b[33mMemory leak detected!\x1b[0m", .{});
        std.process.exit(1);
    }

    return exit_code;
}

/// Build a RocList of RocStr from argc/argv
fn buildStrArgsList(argc: usize, argv: [*][*:0]u8, roc_ops: *builtins.host_abi.RocOps) RocList {
    if (argc == 0) {
        return RocList.empty();
    }

    // Allocate list with proper refcount header using RocList.allocateExact
    const args_list = RocList.allocateExact(
        @alignOf(RocStr),
        argc,
        @sizeOf(RocStr),
        true, // elements are refcounted (RocStr)
        roc_ops,
    );

    const args_ptr: [*]RocStr = @ptrCast(@alignCast(args_list.bytes));

    // Build each argument string
    for (0..argc) |i| {
        const arg_cstr = argv[i];
        const arg_len = std.mem.len(arg_cstr);

        // RocStr.init takes a const pointer to read FROM and allocates internally
        args_ptr[i] = RocStr.init(arg_cstr, arg_len, roc_ops);
    }

    return args_list;
}
