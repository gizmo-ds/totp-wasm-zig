const std = @import("std");
const allocator = std.heap.wasm_allocator;

const otp = @import("./otp.zig");

export fn hotp(key_ptr: [*]const u8, key_len: usize, counter: u64, digits: u32) u32 {
    return otp.hotp(key_ptr[0..key_len], counter, digits);
}

export fn totp(secret_ptr: [*]const u8, secret_len: usize, t: i64, digit: u32, period: u32) u32 {
    return otp.totp(secret_ptr[0..secret_len], t, digit, period) catch return 0;
}

export fn steam_guard(secret_ptr: [*]const u8, secret_len: usize, t: i64) u32 {
    _ = otp.steam_guard(secret_ptr[0..secret_len], t) catch return 0;
    return 0;
}

export fn malloc(size: usize) ?[*]const u8 {
    const ret = allocator.alloc(u8, size + @sizeOf(usize)) catch return null;
    return ret.ptr;
}

export fn free(ptr: [*:0]u8) void {
    allocator.free(std.mem.span(ptr));
}
