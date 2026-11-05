//! Walks a paginated list into a caller-defined struct.
//!
//! List operations return untyped JSON and the client does not expose response
//! headers, so decode the raw body yourself and stop at the first short page.
//!
//!     zig build run-list_releases -- christianhelle openapi2zig

const std = @import("std");
const github = @import("github");

/// Only the fields you declare are decoded.
const Release = struct {
    tag_name: []const u8,
    published_at: ?[]const u8 = null,
    draft: bool = false,
};

const page_size = 100;

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const owner = if (args.len > 1) args[1] else "christianhelle";
    const repo_name = if (args.len > 2) args[2] else "openapi2zig";

    var client = github.init(init.gpa, init.io, init.environ_map.get("GITHUB_TOKEN") orelse "");
    defer client.deinit();

    var page: i64 = 1;
    var total: usize = 0;
    while (true) : (page += 1) {
        var raw = try github.client.reposListReleasesRaw(&client, owner, repo_name, page_size, page);
        defer raw.deinit();

        if (raw.status.class() != .success) {
            std.debug.print("GitHub answered {d}: {s}\n", .{ @intFromEnum(raw.status), raw.body });
            return error.GitHubApiError;
        }

        const parsed = try std.json.parseFromSlice([]const Release, init.gpa, raw.body, .{
            .ignore_unknown_fields = true,
        });
        defer parsed.deinit();

        for (parsed.value) |release| {
            if (release.draft) continue;
            std.debug.print("{s} {s}\n", .{ release.tag_name, release.published_at orelse "unpublished" });
            total += 1;
        }

        if (parsed.value.len < page_size) break;
    }
    std.debug.print("{d} releases\n", .{total});
}
