//! Sends a request by path instead of through a generated operation. Use this
//! for an endpoint the generated client gets wrong or does not have.
//!
//!     zig build run-raw_request

const std = @import("std");
const github = @import("github");

const RateLimit = struct {
    rate: struct { limit: i64, remaining: i64 },
};

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const token = init.environ_map.get("GITHUB_TOKEN") orelse "";

    var client = github.init(init.gpa, init.io, token);
    defer client.deinit();

    // Sent with every request, including those from generated operations.
    client.default_headers = &.{.{ .name = "X-GitHub-Api-Version", .value = "2026-03-10" }};

    // Unlike generated operations, requestRaw and its variants do not send the
    // token for you.
    const authorization: []const std.http.Header = &.{.{
        .name = "Authorization",
        .value = try std.fmt.allocPrint(arena, "Bearer {s}", .{token}),
    }};
    const url = try std.fmt.allocPrint(arena, "{s}/rate_limit", .{client.base_url});

    const raw = try github.client.requestRawWithExtraHeaders(
        &client,
        .GET,
        url,
        null,
        if (token.len > 0) authorization else &.{},
    );
    defer raw.deinit();

    var result = try github.client.parseRawResponse(RateLimit, raw);
    switch (result) {
        .ok => |*rate_limit| {
            defer rate_limit.deinit();
            const rate = rate_limit.value().rate;
            std.debug.print("{d} of {d} requests left\n", .{ rate.remaining, rate.limit });
        },
        else => return error.UnexpectedResponse,
    }
}
