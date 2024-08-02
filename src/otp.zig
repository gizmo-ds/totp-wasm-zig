const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const HmacSha1 = std.crypto.auth.hmac.HmacSha1;

const base32 = @import("./base32.zig");

pub fn hotp(key: []const u8, counter: u64, digit: u32) u32 {
    var hmac: [HmacSha1.mac_length]u8 = undefined;
    const counter_bytes = [8]u8{
        @truncate(counter >> 56),
        @truncate(counter >> 48),
        @truncate(counter >> 40),
        @truncate(counter >> 32),
        @truncate(counter >> 24),
        @truncate(counter >> 16),
        @truncate(counter >> 8),
        @truncate(counter),
    };

    HmacSha1.create(hmac[0..], counter_bytes[0..], key);

    const offset = hmac[hmac.len - 1] & 0xf;
    const bin_code = hmac[offset .. offset + 4];
    const int_code = @as(u32, bin_code[3]) |
        @as(u32, bin_code[2]) << 8 |
        @as(u32, bin_code[1]) << 16 |
        @as(u32, bin_code[0]) << 24 & 0x7FFFFFFF;

    const code = int_code % (std.math.pow(u32, 10, digit));
    return code;
}

test "hotp test" {
    const key: []const u8 = "GM4VC2CQN5UGS33ZJJVWYUSFMQ4HOQJW";
    const counter: u64 = 1662681600;
    const digits: u32 = 6;
    const code: u32 = 886679;

    try testing.expectEqual(code, hotp(key, counter, digits));
}

pub fn totp(alloc: std.mem.Allocator, secret: []const u8, t: i64, digit: u32, period: u32) !u32 {
    const counter = @divFloor(t, period);
    const data = try base32.decode(alloc, secret);
    defer alloc.free(data);
    const code = hotp(data, @bitCast(counter), digit);
    return code;
}

test "totp test" {
    const secret: []const u8 = "GM4VC2CQN5UGS33ZJJVWYUSFMQ4HOQJW";
    const t: i64 = 1662681600;
    const digits: u32 = 6;
    const period: u32 = 30;
    const code: u32 = 473526;

    try testing.expectEqual(code, try totp(std.heap.page_allocator, secret, t, digits, period));
}

const STEAM_CHARS: *const [26:0]u8 = "23456789BCDFGHJKMNPQRTVWXY";

pub fn steam_guard(alloc: std.mem.Allocator, secret: []const u8, t: i64) ![5]u8 {
    const counter: u64 = @intCast(@divFloor(t, 30));
    const key = try base32.decode(alloc, secret);
    defer alloc.free(key);

    const counter_bytes = [8]u8{
        @truncate(counter >> 56),
        @truncate(counter >> 48),
        @truncate(counter >> 40),
        @truncate(counter >> 32),
        @truncate(counter >> 24),
        @truncate(counter >> 16),
        @truncate(counter >> 8),
        @truncate(counter),
    };

    var hmac: [HmacSha1.mac_length]u8 = undefined;

    HmacSha1.create(hmac[0..], counter_bytes[0..], key);

    const offset = hmac[hmac.len - 1] & 0xf;
    const bytes = hmac[offset .. offset + 4];
    const result = @as(u32, bytes[3]) |
        @as(u32, bytes[2]) << 8 |
        @as(u32, bytes[1]) << 16 |
        @as(u32, bytes[0]) << 24 & 0x7FFFFFFF;

    var fc: u32 = result;
    var bin_code = [_]u8{0} ** 5;

    for (0..5) |i| {
        bin_code[i] = STEAM_CHARS[(fc % STEAM_CHARS.len)];
        fc /= @intCast(STEAM_CHARS.len);
    }
    return bin_code;
}

test "Steam Guard test" {
    const secret: []const u8 = "GM4VC2CQN5UGS33ZJJVWYUSFMQ4HOQJW";
    const t: i64 = 1662681600;
    const code = "4PRPM";

    try testing.expectEqualSlices(u8, code[0..], (try steam_guard(std.heap.page_allocator, secret, t))[0..]);
}
