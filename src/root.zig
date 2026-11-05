//! A GitHub REST API client for Zig, generated from GitHub's OpenAPI
//! description by openapi2zig (https://github.com/christianhelle/openapi2zig).
//!
//! `client.zig`, `models.zig` and `runtime.zig` are generated. This file is the
//! hand-written entry point of the package and survives regeneration.

const std = @import("std");

/// Every generated operation, as free functions taking a `*Client`.
pub const client = @import("client.zig");
/// Every schema from the OpenAPI description, as a struct.
pub const models = @import("models.zig");
/// Shared response types and helpers used by the generated operations.
pub const runtime = @import("runtime.zig");

pub const Client = client.Client;
pub const Owned = runtime.Owned;
pub const ApiResult = runtime.ApiResult;
pub const RawResponse = runtime.RawResponse;
pub const HttpObserver = runtime.HttpObserver;

test {
    _ = runtime;
}

const TestRepository = struct { full_name: []const u8 };

fn testResponse(status: std.http.Status, body: []const u8) !RawResponse {
    return .{
        .allocator = std.testing.allocator,
        .status = status,
        .body = try std.testing.allocator.dupe(u8, body),
    };
}

test "parseRawResponse returns the parsed value on success" {
    const raw = try testResponse(.ok, "{\"full_name\":\"owner/repo\",\"ignored\":1}");
    var result = try client.parseRawResponse(TestRepository, raw);
    defer result.deinit();

    try std.testing.expectEqualStrings("owner/repo", result.ok.value().full_name);
}

test "parseRawResponse keeps the body of an API error" {
    const raw = try testResponse(.not_found, "{\"message\":\"Not Found\"}");
    var result = try client.parseRawResponse(TestRepository, raw);
    defer result.deinit();

    try std.testing.expectEqual(std.http.Status.not_found, result.api_error.status);
    try std.testing.expectEqualStrings("{\"message\":\"Not Found\"}", result.api_error.body);
}

test "parseRawResponse reports a body that does not match the model" {
    const raw = try testResponse(.ok, "{\"unexpected\":true}");
    var result = try client.parseRawResponse(TestRepository, raw);
    defer result.deinit();

    try std.testing.expectEqualStrings("MissingField", result.parse_error.error_name);
}
