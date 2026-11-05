//! Logs every request with an observer, and pins the API version with a
//! default header.
//!
//!     zig build run-observe_requests

const std = @import("std");
const github = @import("github");

/// Passed to every callback through `ctx`.
const Stats = struct {
    requests: usize = 0,
    failures: usize = 0,

    fn from(ctx: ?*anyopaque) *Stats {
        return @ptrCast(@alignCast(ctx.?));
    }

    // The headers include Authorization, so this doesn't print them.
    fn onRequest(ctx: ?*anyopaque, method: std.http.Method, url: []const u8, _: []const std.http.Header, _: ?[]const u8) void {
        from(ctx).requests += 1;
        std.debug.print("-> {t} {s}\n", .{ method, url });
    }

    fn onResponse(ctx: ?*anyopaque, _: std.http.Method, _: []const u8, status: std.http.Status, _: []const std.http.Header, body: []const u8, duration_ns: u64) void {
        if (status.class() != .success) from(ctx).failures += 1;
        std.debug.print("<- {d} with {d} bytes in {d} ms\n", .{
            @backingInt(status),
            body.len,
            duration_ns / std.time.ns_per_ms,
        });
    }

    fn onError(ctx: ?*anyopaque, method: std.http.Method, url: []const u8, err_name: []const u8) void {
        from(ctx).failures += 1;
        std.debug.print("!! {t} {s}: {s}\n", .{ method, url, err_name });
    }
};

pub fn main(init: std.process.Init) !void {
    var client = github.init(init.gpa, init.io, init.environ_map.get("GITHUB_TOKEN") orelse "");
    defer client.deinit();

    client.default_headers = &.{.{ .name = "X-GitHub-Api-Version", .value = "2026-03-10" }};

    var stats: Stats = .{};
    client.http_observer = .{
        .ctx = &stats,
        .onRequest = &Stats.onRequest,
        .onResponse = &Stats.onResponse,
        .onError = &Stats.onError,
    };

    var repository = try github.client.reposGetRaw(&client, "christianhelle", "openapi2zig");
    defer repository.deinit();
    var missing = try github.client.reposGetRaw(&client, "christianhelle", "this-repository-does-not-exist");
    defer missing.deinit();

    std.debug.print("{d} requests, {d} failed\n", .{ stats.requests, stats.failures });
}
