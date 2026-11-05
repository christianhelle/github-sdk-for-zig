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
    const authorization = [_]std.http.Header{.{
        .name = "Authorization",
        .value = try std.fmt.allocPrint(arena, "Bearer {s}", .{token}),
    }};
    const extra_headers: []const std.http.Header = if (token.len > 0) &authorization else &.{};
    const url = try std.fmt.allocPrint(arena, "{s}/rate_limit", .{client.base_url});

    const raw = try github.client.requestRawWithExtraHeaders(&client, .GET, url, null, extra_headers);

    // parseRawResponse takes ownership of the raw response.
    var result = try github.client.parseRawResponse(RateLimit, raw);
    defer result.deinit();

    switch (result) {
        .ok => |*rate_limit| {
            const rate = rate_limit.value().rate;
            std.debug.print("{d} of {d} requests left\n", .{ rate.remaining, rate.limit });
        },
        .api_error => |response| {
            std.debug.print("GitHub answered {d}: {s}\n", .{ @backingInt(response.status), response.body });
            return error.GitHubApiError;
        },
        .parse_error => |failure| {
            std.debug.print("{s} while parsing: {s}\n", .{ failure.error_name, failure.raw.body });
            return error.UnexpectedResponse;
        },
    }
}
