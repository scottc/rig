const std = @import("std");
const zap = @import("zap");

const Context = struct {
    userName: []const u8,
    channel: []const u8,
    // we need to hold on to them and just re-use them for every incoming
    // connection
    subscribeArgs: WebsocketHandler.SubscribeArgs,
    settings: WebsocketHandler.WebSocketSettings,
};

const ContextList = std.ArrayList(*Context);

pub const ContextManager = struct {
    allocator: std.mem.Allocator,
    channel: []const u8,
    usernamePrefix: []const u8,
    contexts: ContextList = undefined,

    pub fn init(
        allocator: std.mem.Allocator,
        channelName: []const u8,
        usernamePrefix: []const u8,
    ) ContextManager {
        return .{
            .allocator = allocator,
            .channel = channelName,
            .usernamePrefix = usernamePrefix,
            .contexts = ContextList.empty,
        };
    }

    pub fn deinit(self: *ContextManager) void {
        for (self.contexts.items) |ctx| {
            self.allocator.free(ctx.userName);
        }
        self.contexts.deinit(self.allocator);
    }

    pub fn newContext(self: *ContextManager) !*Context {
        const ctx = try self.allocator.create(Context);
        const userName = try std.fmt.allocPrint(
            self.allocator,
            "{s}{d}",
            .{ self.usernamePrefix, self.contexts.items.len },
        );
        ctx.* = .{
            .userName = userName,
            .channel = self.channel,
            // used in subscribe()
            .subscribeArgs = .{
                .channel = self.channel,
                .force_text = true,
                .context = ctx,
            },
            // used in upgrade()
            .settings = .{
                .on_open = on_open_websocket,
                .on_close = on_close_websocket,
                .on_message = handle_websocket_message,
                .context = ctx,
            },
        };
        try self.contexts.append(self.allocator, ctx);
        return ctx;
    }
};

//
// Websocket Callbacks
//
fn on_open_websocket(context: ?*Context, handle: zap.WebSockets.WsHandle) !void {
    if (context) |ctx| {
        _ = try WebsocketHandler.subscribe(handle, &ctx.subscribeArgs);

        // say hello
        var buf: [128]u8 = undefined;
        const message = try std.fmt.bufPrint(
            &buf,
            "[Web Server Thread] {s} joined the chat.",
            .{ctx.userName},
        );

        // send notification to all others
        WebsocketHandler.publish(.{ .channel = ctx.channel, .message = message });
        std.log.info("[Web Server Thread] new websocket opened: {s}", .{message});
    }
}

fn on_close_websocket(context: ?*Context, uuid: isize) !void {
    _ = uuid;
    if (context) |ctx| {
        // say goodbye
        var buf: [128]u8 = undefined;
        const message = try std.fmt.bufPrint(
            &buf,
            "[Web Server Thread] {s} left the chat.",
            .{ctx.userName},
        );

        // send notification to all others
        WebsocketHandler.publish(.{ .channel = ctx.channel, .message = message });
        std.log.info("[Web Server Thread] websocket closed: {s}", .{message});
    }
}

fn handle_websocket_message(
    context: ?*Context,
    handle: zap.WebSockets.WsHandle,
    message: []const u8,
    is_text: bool,
) !void {
    _ = handle;
    _ = is_text;

    if (context) |ctx| {
        // send message
        const buflen = 128; // arbitrary len
        var buf: [buflen]u8 = undefined;

        const format_string = "{s}: {s}";
        const fmt_string_extra_len = 2; // ": " between the two strings
        //
        const max_msg_len = buflen - ctx.userName.len - fmt_string_extra_len;
        if (max_msg_len > 0) {
            // there is space for the message, because the user name + format
            // string extra do not exceed the buffer now, let's check: do we
            // need to trim the message?
            var trimmed_message: []const u8 = message;
            if (message.len > max_msg_len) {
                trimmed_message = message[0..max_msg_len];
            }
            const chat_message = try std.fmt.bufPrint(
                &buf,
                format_string,
                .{ ctx.userName, trimmed_message },
            );

            // send notification to all others
            WebsocketHandler.publish(
                .{ .channel = ctx.channel, .message = chat_message },
            );
            std.log.info("[Web Server Thread] {s}", .{chat_message});
        } else {
            std.log.warn(
                "[Web Server Thread] Username is very long, cannot deal with that size: {d}",
                .{ctx.userName.len},
            );
        }
    }
}

pub fn on_request(r: zap.Request) !void {
    const path = r.path orelse "/";

    if (std.mem.eql(u8, path, "/") or std.mem.eql(u8, path, "/index.html")) {
        serve_file(r, "public/index.html", "text/html");
        return;
    }

    if (std.mem.eql(u8, path, "/main.wasm")) {
        serve_file(r, "public/main.wasm", "application/wasm");
        return;
    }

    r.setStatus(.not_found);
    r.sendBody("<h1>404</h1>") catch {};
}

fn serve_file(r: zap.Request, file_path: []const u8, mime: []const u8) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const file = std.fs.cwd().openFile(file_path, .{}) catch {
        r.setStatus(.internal_server_error);
        r.sendBody("File not found") catch {};
        return;
    };
    defer file.close();

    const data = file.readToEndAlloc(allocator, 1024 * 1024 * 10) catch |err| {
        std.log.err("Read error: {}", .{err});
        r.setStatus(.internal_server_error);
        r.sendBody("Read error") catch {};
        return;
    };
    defer allocator.free(data);

    r.setHeader("Content-Type", mime) catch {};
    r.setHeader("Cache-Control", "no-cache") catch {};
    r.sendBody(data) catch {
        r.setStatus(.internal_server_error);
    };
}

pub fn on_upgrade(r: zap.Request, target_protocol: []const u8) !void {
    // make sure we're talking the right protocol
    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        std.log.warn("[Web Server Thread] received illegal protocol: {s}", .{target_protocol});
        r.setStatus(.bad_request);
        r.sendBody("400 - BAD REQUEST") catch unreachable;
        return;
    }
    var context = GlobalContextManager.newContext() catch |err| {
        std.log.err("[Web Server Thread] Error creating context: {any}", .{err});
        return;
    };

    try WebsocketHandler.upgrade(r.h, &context.settings);
    std.log.info("[Web Server Thread] connection upgrade OK", .{});
}

// global variables, yeah!
pub var GlobalContextManager: ContextManager = undefined;

pub const WebsocketHandler = zap.WebSockets.Handler(Context);

pub fn serverThread() !void {
    zap.start(.{
        .threads = 1,
        .workers = 1,
    });
}
