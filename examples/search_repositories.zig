//! Searches repositories, passing some optional query parameters and not others.
//!
//! Search has its own rate limit: 10 requests a minute without a token.
//!
//!     zig build run-search_repositories -- "language:zig stars:>1000"

const std = @import("std");
const github = @import("github");

const SearchResult = struct {
    total_count: i64,
    items: []const Repository,
};

const Repository = struct {
    full_name: []const u8,
    stargazers_count: u64,
    description: ?[]const u8 = null,
};

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const query = if (args.len > 1) args[1] else "language:zig stars:>1000";

    var client = github.init(init.gpa, init.io, init.environ_map.get("GITHUB_TOKEN") orelse "");
    defer client.deinit();

    // Pass null for a parameter you don't want to send. Query values are
    // percent-encoded for you, so the spaces and ">" above are fine.
    var raw = try github.client.searchReposRaw(&client, query, "stars", "desc", 10, null);
    defer raw.deinit();

    if (raw.status != .ok) {
        std.debug.print("GitHub answered {d}: {s}\n", .{ @backingInt(raw.status), raw.body });
        return error.GitHubApiError;
    }

    const parsed = try std.json.parseFromSlice(SearchResult, init.gpa, raw.body, .{
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();

    std.debug.print("{d} repositories match \"{s}\"\n", .{ parsed.value.total_count, query });
    for (parsed.value.items) |repository| {
        std.debug.print("{d:>7} {s}\n", .{ repository.stargazers_count, repository.full_name });
    }
}
