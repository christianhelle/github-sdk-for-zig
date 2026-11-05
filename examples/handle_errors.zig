//! Tells API errors apart from responses that do not match the model.
//!
//!     zig build run-handle_errors -- christianhelle does-not-exist

const std = @import("std");
const github = @import("github");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const owner = if (args.len > 1) args[1] else "christianhelle";
    const repo_name = if (args.len > 2) args[2] else "does-not-exist";

    var client = github.init(init.gpa, init.io, init.environ_map.get("GITHUB_TOKEN") orelse "");
    defer client.deinit();

    var result = try github.client.reposGetResult(&client, owner, repo_name);
    defer result.deinit();

    switch (result) {
        .ok => |*repository| std.debug.print("found {s}\n", .{repository.value().full_name}),
        .api_error => |response| std.debug.print("GitHub answered {d}: {s}\n", .{
            @backingInt(response.status),
            response.body,
        }),
        .parse_error => |failure| std.debug.print("{s} while parsing: {s}\n", .{
            failure.error_name,
            failure.raw.body,
        }),
    }
}
