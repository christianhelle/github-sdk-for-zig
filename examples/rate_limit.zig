//! Reads your remaining requests as a typed model.
//!
//! Calling this endpoint doesn't count against your rate limit.
//!
//!     zig build run-rate_limit

const std = @import("std");
const github = @import("github");

pub fn main(init: std.process.Init) !void {
    var client = github.init(init.gpa, init.io, init.environ_map.get("GITHUB_TOKEN") orelse "");
    defer client.deinit();

    var overview = try github.client.rateLimitGet(&client);
    defer overview.deinit();

    const resources = overview.value().resources;
    print("core", resources.core);
    print("search", resources.search);
    // Some limits only apply to some accounts, so they're optional.
    if (resources.graphql) |graphql| print("graphql", graphql);
}

fn print(name: []const u8, limit: github.models.@"rate-limit") void {
    std.debug.print("{s:<8} {d}/{d} left, resets at {d} (Unix time)\n", .{
        name,
        limit.remaining,
        limit.limit,
        limit.reset,
    });
}
