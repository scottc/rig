const std = @import("std");

pub const DevServer = struct {
    allocator: std.mem.Allocator,
    listener: std.net.Server,
    routes: std.StringHashMap(Route),
    shutdown: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    const Route = struct {
        pattern: []const u8,
        handler: Handler,
        param_names: []const []const u8, // for /user/{id}/profile/{tab}
    };

    pub const Handler = *const fn (req: Request, res: *Response) anyerror!void;

    pub fn init(allocator: std.mem.Allocator, port: u16) !DevServer {
        const address = try std.net.Address.parseIp("127.0.0.1", port);
        return .{
            .allocator = allocator,
            .listener = try address.listen(.{ .reuse_address = true }),
            .routes = std.StringHashMap(Route).init(allocator),
        };
    }

    pub fn deinit(self: *DevServer) void {
        self.routes.deinit();
        self.listener.close();
    }

    pub fn getPort(self: *const DevServer) u16 {
        return self.listener.listen_address.getPort();
    }

    pub fn route(self: *DevServer, pattern: []const u8, handler: Handler) !void {
        var param_names = std.ArrayList([]const u8).init(self.allocator);
        defer param_names.deinit();

        var it = std.mem.splitScalar(u8, pattern, '/');
        while (it.next()) |part| {
            if (std.mem.startsWith(u8, part, "{") and std.mem.endsWith(u8, part, "}")) {
                try param_names.append(part[1 .. part.len - 1]);
            }
        }

        try self.routes.put(pattern, .{
            .pattern = pattern,
            .handler = handler,
            .param_names = try param_names.toOwnedSlice(),
        });
    }

    pub fn listenAndServe(self: *DevServer) !void {
        std.log.info("Roc dev server → http://localhost:{d}", .{self.getPort()});

        while (!self.shutdown.load(.monotonic)) {
            const conn = self.listener.accept() catch |err| switch (err) {
                error.ConnectionAborted, error.ConnectionReset => continue,
                else => return err,
            };
            const conn_copy = conn;

            // Fire-and-forget thread per connection (dev server, not production)
            _ = try std.Thread.spawn(.{}, handleConnection, .{ self, conn_copy });
        }
    }

    pub fn stop(self: *DevServer) void {
        self.shutdown.store(true, .monotonic);
    }

    fn handleConnection(server: *DevServer, conn: std.net.Server.Connection) void {
        defer conn.stream.close();

        var arena = std.heap.ArenaAllocator.init(server.allocator);
        defer arena.deinit();
        const alloc = arena.allocator();

        var buffer: [32 * 1024]u8 = undefined;
        const n = conn.stream.read(&buffer) catch return;
        if (n == 0) return;

        var parser = RequestParser{ .raw = buffer[0..n] };
        const req = parser.parse(alloc) catch |err| {
            std.log.warn("Failed to parse request: {}", .{err});
            return;
        };

        var res = Response{
            .conn = conn,
            .allocator = alloc,
            .status_code = 200,
            .headers = std.StringHashMap([]const u8).init(alloc),
        };
        defer res.deinit();

        // Try exact match first
        if (server.routes.get(req.path)) |r| {
            req.params = std.StringHashMap([]const u8).init(alloc);
            r.handler(req, &res) catch |err| res.serverError(err);
            return;
        }

        // Then try pattern matching
        for (server.routes.values()) |r| {
            if (matchRoute(r.pattern, req.path)) |params| {
                req.params = params;
                r.handler(req, &res) catch |err| res.serverError(err);
                return;
            }
        }

        res.notFound();
    }

    fn matchRoute(pattern: []const u8, path: []const u8) ?std.StringHashMap([]const u8) {
        var pattern_parts = std.mem.splitScalar(u8, pattern, '/');
        var path_parts = std.mem.splitScalar(u8, path, '/');

        var params = std.StringHashMap([]const u8).init(std.heap.page_allocator catch return null);
        errdefer params.deinit();

        while (true) {
            const pat = pattern_parts.next() orelse return params;
            const pth = path_parts.next() orelse return null;

            if (std.mem.eql(u8, pat, pth)) continue;

            if (pat.len > 2 and pat[0] == '{' and pat[pat.len - 1] == '}') {
                params.put(pat[1 .. pat.len - 1], pth) catch return null;
                continue;
            }

            return null;
        }
    }
};

pub const Request = struct {
    method: []const u8,
    path: []const u8,
    query: ?[]const u8,
    headers: std.StringHashMap([]const u8),
    params: std.StringHashMap([]const u8) = undefined, // filled by router
    allocator: std.mem.Allocator,

    pub fn deinit(self: *Request) void {
        self.headers.deinit();
    }

    pub fn getHeader(self: Request, name: []const u8) ?[]const u8 {
        return self.headers.get(name);
    }
};

pub const Response = struct {
    conn: std.net.Server.Connection,
    allocator: std.mem.Allocator,
    status_code: u16,
    headers: std.StringHashMap([]const u8),
    wrote_headers: bool = false,

    pub fn deinit(self: *Response) void {
        self.headers.deinit();
    }

    pub fn status(self: *Response, code: u16) *Response {
        self.status_code = code;
        return self;
    }

    pub fn header(self: *Response, name: []const u8, value: []const u8) *Response {
        self.headers.put(name, value) catch {};
        return self;
    }

    pub fn send(self: *Response, body: []const u8) !void {
        try self.writeHeaders(body.len);
        _ = try self.conn.stream.writeAll(body);
    }

    pub fn sendText(self: *Response, text: []const u8) !void {
        _ = self.header("Content-Type", "text/plain; charset=utf-8");
        try self.send(text);
    }

    pub fn sendHtml(self: *Response, html: []const u8) !void {
        _ = self.header("Content-Type", "text/html; charset=utf-8");
        try self.send(html);
    }

    pub fn sendJson(self: *Response, json: []const u8) !void {
        _ = self.header("Content-Type", "application/json");
        try self.send(json);
    }

    pub fn sendFile(self: *Response, path: []const u8) !void {
        const file = std.fs.cwd().openFile(path, .{}) catch return self.notFound();
        defer file.close();

        const stat = file.stat() catch return self.serverError(@src());
        const content_type = mimeTypeForPath(path) orelse "application/octet-stream";

        self.header("Content-Type", content_type);
        try self.writeHeaders(@intCast(stat.size));

        var buf: [8192]u8 = undefined;
        var total: usize = 0;
        while (total < stat.size) {
            const n = file.read(&buf) catch break;
            if (n == 0) break;
            _ = try self.conn.stream.writeAll(buf[0..n]);
            total += n;
        }
    }

    pub fn redirect(self: *Response, location: []const u8) !void {
        self.status(302).header("Location", location);
        try self.send("");
    }

    pub fn notFound(self: *Response) void {
        self.status(404).sendText("Not Found") catch {};
    }

    pub fn serverError(self: *Response, err: anyerror) void {
        std.log.err("Dev server error: {}", .{err});
        self.status(500).sendText("Internal Server Error") catch {};
    }

    fn writeHeaders(self: *Response, body_len: usize) !void {
        if (self.wrote_headers) return;
        self.wrote_headers = true;

        var writer = self.conn.stream.writer();
        try writer.print("HTTP/1.1 {d} {s}\r\n", .{ self.status_code, statusText(self.status_code) });

        try writer.writeAll("Connection: keep-alive\r\n");
        try writer.print("Content-Length: {d}\r\n", .{body_len});

        var it = self.headers.iterator();
        while (it.next()) |entry| {
            try writer.print("{s}: {s}\r\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }

        try writer.writeAll("\r\n");
    }
};

const RequestParser = struct {
    raw: []const u8,
    pos: usize = 0,

    fn parse(self: *RequestParser, allocator: std.mem.Allocator) !Request {
        const method_end = std.mem.indexOfScalarPos(u8, self.raw, self.pos, ' ') orelse return error.InvalidRequest;
        const method = self.raw[self.pos..method_end];
        self.pos = method_end + 1;

        const path_end = std.mem.indexOfScalarPos(u8, self.raw, self.pos, ' ') orelse return error.InvalidRequest;
        const full_path = self.raw[self.pos..path_end];
        self.pos = path_end + 1;

        const query = if (std.mem.indexOfScalar(u8, full_path, '?')) |q|
            full_path[q + 1 ..]
        else
            null;
        const path = if (std.mem.indexOfScalar(u8, full_path, '?')) |q|
            full_path[0..q]
        else
            full_path;

        // Skip HTTP/1.1\r\n
        self.pos = std.mem.indexOfPos(u8, self.raw, self.pos, "\r\n") orelse return error.InvalidRequest;
        self.pos += 2;

        var headers = std.StringHashMap([]const u8).init(allocator);

        while (self.pos < self.raw.len) {
            if (self.raw[self.pos] == '\r' and self.raw[self.pos + 1] == '\n') {
                self.pos += 2;
                break;
            }

            const line_end = std.mem.indexOfPos(u8, self.raw, self.pos, "\r\n") orelse return error.InvalidRequest;
            const line = self.raw[self.pos..line_end];

            if (std.mem.indexOfScalar(u8, line, ':')) |colon| {
                const name = std.mem.trim(u8, line[0..colon], " ");
                const value = std.mem.trim(u8, line[colon + 1 ..], " ");
                try headers.put(name, value);
            }

            self.pos = line_end + 2;
        }

        return Request{
            .method = method,
            .path = path,
            .query = query,
            .headers = headers,
            .allocator = allocator,
        };
    }
};

fn statusText(code: u16) []const u8 {
    return switch (code) {
        200 => "OK",
        302 => "Found",
        404 => "Not Found",
        500 => "Internal Server Error",
        else => "OK",
    };
}

fn mimeTypeForPath(path: []const u8) ?[]const u8 {
    const ext = std.fs.path.extension(path);
    return switch (std.mem.hash_slice_u8(ext)) {
        std.mem.hash_slice_u8(".html") => "text/html",
        std.mem.hash_slice_u8(".css") => "text/css",
        std.mem.hash_slice_u8(".js") => "application/javascript",
        std.mem.hash_slice_u8(".json") => "application/json",
        std.mem.hash_slice_u8(".png") => "image/png",
        std.mem.hash_slice_u8(".jpg"), std.mem.hash_slice_u8(".jpeg") => "image/jpeg",
        std.mem.hash_slice_u8(".svg") => "image/svg+xml",
        std.mem.hash_slice_u8(".wasm") => "application/wasm",
        else => null,
    };
}
