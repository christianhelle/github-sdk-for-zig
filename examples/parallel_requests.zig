//! Fetches several repositories at once, with one client per thread.
//!
//! A `Client` isn't safe to share between threads, so each worker creates its
//! own and calls `deinit` before it returns.
//!
//!     zig build run-parallel_requests -- ziglang/zig christianhelle/openapi2zig

const std = @import("std");
const github = @import("github");

const Repository = struct {
    stargazers_count: u64,
};

const Job = struct {
    owner: []const u8,
    repo: []const u8,
    stars: ?u64 = null,
    failure: ?anyerror = null,

    fn run(job: *Job, gpa: std.mem.Allocator, io: std.Io, token: []const u8) void {
        job.fetch(gpa, io, token) catch |err| {
            job.failure = err;
        };
    }

    fn fetch(job: *Job, gpa: std.mem.Allocator, io: std.Io, token: []const u8) !void {
        var client = github.init(gpa, io, token);
        defer client.deinit();

        var raw = try github.client.reposGetRaw(&client, job.owner, job.repo);
        defer raw.deinit();
        if (raw.status != .ok) return error.GitHubApiError;

        const parsed = try std.json.parseFromSlice(Repository, gpa, raw.body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();
        job.stars = parsed.value.stargazers_count;
    }
};

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const defaults = [_][]const u8{ "ziglang/zig", "christianhelle/openapi2zig", "christianhelle/chlogr" };
    const names: []const []const u8 = if (args.len > 1) args[1..] else &defaults;
    const token = init.environ_map.get("GITHUB_TOKEN") orelse "";

    const jobs = try arena.alloc(Job, names.len);
    for (names, jobs) |name, *job| {
        const slash = std.mem.indexOfScalar(u8, name, '/') orelse return error.ExpectedOwnerSlashRepo;
        job.* = .{ .owner = name[0..slash], .repo = name[slash + 1 ..] };
    }

    const threads = try arena.alloc(std.Thread, jobs.len);
    for (jobs, threads) |*job, *thread| {
        thread.* = try std.Thread.spawn(.{}, Job.run, .{ job, init.gpa, init.io, token });
    }
    for (threads) |thread| thread.join();

    for (names, jobs) |name, job| {
        if (job.stars) |stars| {
            std.debug.print("{d:>7} {s}\n", .{ stars, name });
        } else {
            std.debug.print("  error {s}: {t}\n", .{ name, job.failure.? });
        }
    }
}
