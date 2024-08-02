const std = @import("std");
const testing = std.testing;
const allocator = std.heap.wasm_allocator;

const otp = @import("./otp.zig");

export fn hotp(key_ptr: [*]const u8, key_len: usize, counter: u64, digits: u32) u32 {
    return otp.hotp(key_ptr[0..key_len], counter, digits);
}

export fn totp(secret_ptr: [*]const u8, secret_len: usize, t: i64, digit: u32, period: u32) u32 {
    return otp.totp(allocator, secret_ptr[0..secret_len], t, digit, period) catch @panic("failed to generate totp code");
}

export fn steam_guard(secret_ptr: [*]const u8, secret_len: usize, t: i64) [*]u8 {
    var code = otp.steam_guard(allocator, secret_ptr[0..secret_len], t) catch @panic("failed to generate steam guard code");
    const output: []u8 = allocator.alloc(u8, 5) catch @panic("failed to allocate memory");
    @memcpy(output[0..5], code[0..5]);
    return output[0..5 :0].ptr;
}

export fn malloc(size: usize) ?[*]const u8 {
    const ret = allocator.alloc(u8, size + @sizeOf(usize)) catch return null;
    return ret.ptr;
}

export fn free(ptr: [*:0]u8) void {
    allocator.free(std.mem.span(ptr));
}
