//! Creates an issue. This writes to GitHub, so it needs an explicit target and
//! a token with permission to open issues there.
//!
//!     GITHUB_TOKEN=... zig build run-create_issue -- owner repo "Issue title"

const std = @import("std");
const github = @import("github");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    if (args.len != 4) {
        std.debug.print("usage: create_issue <owner> <repo> <title>\n", .{});
        return error.InvalidArguments;
    }

    const token = init.environ_map.get("GITHUB_TOKEN") orelse return error.MissingGitHubToken;

    var client = github.init(init.gpa, init.io, token);
    defer client.deinit();

    // Request bodies are std.json.Value, so build the JSON object by hand.
    var body: std.json.ObjectMap = .empty;
    try body.put(arena, "title", .{ .string = args[3] });
    try body.put(arena, "body", .{ .string = "Created with github-sdk-for-zig" });

    var result = try github.client.issuesCreateResult(&client, args[1], args[2], .{ .object = body });
    defer result.deinit();

    switch (result) {
        .ok => |*issue| std.debug.print("created {s}\n", .{issue.value().html_url}),
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
