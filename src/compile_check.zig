//! Forces the compiler to analyze every generated operation, which it otherwise
//! skips until an operation is called. Run with .

const std = @import("std");
const client = @import("client.zig");

/// Operations that openapi2zig 0.6.1 emits with path arguments in the wrong
/// order, where the swap also fails to compile. See "Known limitations" in
/// docs/USAGE.md. Remove entries once the generator is fixed and the client is
/// regenerated.
const known_broken = [_][]const u8{
    "actionsListCustomImageVersionsForOrg",
    "packagesGetPackageVersionForUser",
    "projectsAddFieldForOrg",
    "projectsDeleteItemForOrg",
    "projectsDeleteItemForUser",
    "projectsGetFieldForOrg",
    "projectsGetFieldForUser",
    "projectsGetForOrg",
    "projectsGetForUser",
    "projectsGetOrgItem",
    "projectsGetUserItem",
    "projectsListFieldsForOrg",
    "projectsListFieldsForUser",
    "projectsListItemsForOrg",
    "projectsListItemsForUser",
    "projectsListViewItemsForOrg",
    "projectsListViewItemsForUser",
    "projectsUpdateItemForOrg",
    "projectsUpdateItemForUser",
};

fn isKnownBroken(comptime name: []const u8) bool {
    for (known_broken) |broken| {
        const is_variant = std.mem.startsWith(u8, name, broken) and
            (name.len == broken.len or
                std.mem.eql(u8, name[broken.len..], "Raw") or
                std.mem.eql(u8, name[broken.len..], "Result"));
        if (is_variant) return true;
    }
    return false;
}

test "every generated operation compiles" {
    @setEvalBranchQuota(1_000_000_000);
    inline for (comptime std.meta.declarations(client)) |name| {
        if (comptime isKnownBroken(name)) continue;
        const info = @typeInfo(@TypeOf(@field(client, name)));
        if (info == .@"fn" and !info.@"fn".is_generic) _ = &@field(client, name);
    }
}
