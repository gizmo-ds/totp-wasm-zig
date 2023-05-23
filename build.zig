const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "totp-wasm-zig",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = .{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
            .abi = .musl,
        },
        .optimize = .ReleaseSmall,
    });
    lib.import_memory = true;
    lib.rdynamic = true;

    b.installArtifact(lib);

    const run_opt = b.addSystemCommand(&.{
        "wasm-opt",
        "-Os",
        "--strip-debug",
        "--strip-producers",
        "--zero-filled-memory",
    });
    const wasmopt_out = try std.fs.path.join(b.allocator, &.{
        b.getInstallPath(.lib, ""),
        "totp-wasm-zig.wasm",
    });
    defer b.allocator.free(wasmopt_out);
    run_opt.addArtifactArg(lib);
    run_opt.addArg("-o");
    run_opt.addFileSourceArg(.{ .path = wasmopt_out });

    const opt_step = b.step("opt", "optimize wasm file");
    opt_step.dependOn(&run_opt.step);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/otp.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
