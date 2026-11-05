//! Fetches a repository as a typed model.
//!
//!     zig build run-get_repository -- christianhelle chlogr

const std = @import("std");
const github = @import("github");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const owner = if (args.len > 1) args[1] else "christianhelle";
    const repo_name = if (args.len > 2) args[2] else "chlogr";

    // An empty token means anonymous requests, limited to 60 per hour.
    const token = init.environ_map.get("GITHUB_TOKEN") orelse "";

    var client = github.init(init.gpa, init.io, token);
    defer client.deinit();

    var repository = try github.client.reposGet(&client, owner, repo_name);
    defer repository.deinit();

    const value = repository.value();
    std.debug.print("{s}: {d} stars, default branch {s}\n", .{
        value.full_name,
        value.stargazers_count,
        value.default_branch,
    });
    if (value.description) |description| std.debug.print("{s}\n", .{description});
}
