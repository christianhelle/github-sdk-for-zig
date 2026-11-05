//! Uses the status code as the answer: 204 means merged, 404 means not.
//!
//! The plain and Result forms would turn the 404 into an error, so use Raw.
//!
//!     zig build run-check_merged -- christianhelle chlogr 57

const std = @import("std");
const github = @import("github");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const owner = if (args.len > 1) args[1] else "christianhelle";
    const repo_name = if (args.len > 2) args[2] else "chlogr";
    const number = if (args.len > 3) try std.fmt.parseInt(i64, args[3], 10) else 57;

    var client = github.init(init.gpa, init.io, init.environ_map.get("GITHUB_TOKEN") orelse "");
    defer client.deinit();

    var raw = try github.client.pullsCheckIfMergedRaw(&client, owner, repo_name, number);
    defer raw.deinit();

    switch (raw.status) {
        .no_content => std.debug.print("{s}/{s}#{d} is merged\n", .{ owner, repo_name, number }),
        // GitHub also answers 404 when the pull request doesn't exist.
        .not_found => std.debug.print("{s}/{s}#{d} is not merged\n", .{ owner, repo_name, number }),
        else => {
            std.debug.print("GitHub answered {d}: {s}\n", .{ @backingInt(raw.status), raw.body });
            return error.GitHubApiError;
        },
    }
}
