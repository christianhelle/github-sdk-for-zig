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
