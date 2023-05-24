const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const wasm = b.addSharedLibrary(.{
        .name = "totp-wasm-zig",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = .{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
            .abi = .musl,
        },
        .optimize = .ReleaseSmall,
    });
    wasm.import_memory = true;
    wasm.rdynamic = true;

    b.installArtifact(wasm);

    const test_step = b.step("test", "Run tests");
    {
        const otp_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/otp.zig" },
            .target = target,
            .optimize = optimize,
        });
        const run_otp_tests = b.addRunArtifact(otp_tests);
        test_step.dependOn(&run_otp_tests.step);
    }
    {
        const base32_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/base32.zig" },
            .target = target,
            .optimize = optimize,
        });
        const run_base32_tests = b.addRunArtifact(base32_tests);
        test_step.dependOn(&run_base32_tests.step);
    }

    const bindgen_step = b.step("bind", "Generate JavaScript bindings");
    {
        const optimize_wasm = OptimizeWasmStep.create(b, wasm);
        bindgen_step.dependOn(&optimize_wasm.step);

        const gen_wasmdata = GenWasmDateStep.create(b, wasm);
        gen_wasmdata.step.dependOn(&optimize_wasm.step);
        bindgen_step.dependOn(&gen_wasmdata.step);
    }
}

const GenWasmDateStep = struct {
    step: std.build.Step,
    wasm: *std.build.Step.Compile,

    pub fn create(owner: *std.build.Builder, wasm: *std.build.Step.Compile) *GenWasmDateStep {
        const self = owner.allocator.create(GenWasmDateStep) catch unreachable;
        self.* = .{
            .step = std.build.Step.init(.{
                .id = .custom,
                .name = "gen wasmdata",
                .owner = owner,
                .makeFn = GenWasmDateStep.make,
            }),
            .wasm = wasm,
        };
        return self;
    }

    pub fn make(step: *std.build.Step, prog_node: *std.Progress.Node) anyerror!void {
        _ = prog_node;

        const self = @fieldParentPtr(GenWasmDateStep, "step", step);
        const alloc = self.step.owner.allocator;
        const base64_encoder = std.base64.standard.Encoder;
        const wasmopt_out = try std.fs.path.join(alloc, &.{
            self.step.owner.build_root.path.?,
            "packages/totp-wasm/totp-wasm.wasm",
        });

        const wasmfile = try std.fs.openFileAbsolute(wasmopt_out, .{ .mode = .read_only });
        defer wasmfile.close();

        const meta = try wasmfile.metadata();
        var buf = try alloc.alloc(u8, meta.size());
        defer alloc.free(buf);
        _ = try wasmfile.readAll(buf);

        var encoded = try alloc.alloc(u8, base64_encoder.calcSize(buf.len));
        defer alloc.free(encoded);
        _ = base64_encoder.encode(encoded, buf);

        var wasmdata = std.ArrayList(u8).init(alloc);
        defer wasmdata.deinit();
        try wasmdata.appendSlice("// @ts-nocheck wasmdata\nexport default \"");
        try wasmdata.appendSlice(encoded);
        try wasmdata.appendSlice("\";");

        var wasmdata_file = std.fs.cwd().createFile("packages/totp-wasm/wasm_data.js", .{}) catch unreachable;
        defer wasmdata_file.close();
        try wasmdata_file.writeAll(wasmdata.items);
    }
};

const OptimizeWasmStep = struct {
    step: std.build.Step,
    wasm: *std.build.Step.Compile,

    pub fn create(owner: *std.build.Builder, wasm: *std.build.Step.Compile) *OptimizeWasmStep {
        const self = owner.allocator.create(OptimizeWasmStep) catch unreachable;
        self.* = .{
            .step = std.build.Step.init(.{
                .id = .custom,
                .name = "optimize wasm",
                .owner = owner,
                .makeFn = OptimizeWasmStep.make,
            }),
            .wasm = wasm,
        };
        return self;
    }

    pub fn make(step: *std.build.Step, prog_node: *std.Progress.Node) anyerror!void {
        _ = prog_node;

        const self = @fieldParentPtr(OptimizeWasmStep, "step", step);
        const owner = self.step.owner;

        const wasm_filename = try std.fs.path.join(owner.allocator, &.{
            owner.lib_dir,
            self.wasm.out_lib_filename,
        });
        const output_file = try std.fs.path.join(owner.allocator, &.{
            owner.build_root.path.?,
            "packages/totp-wasm/totp-wasm.wasm",
        });

        if (owner.findProgram(&.{"wasm-opt"}, &.{"node_modules/.bin"})) |opt| {
            _ = owner.exec(&.{
                opt,
                "-Os",
                "--strip-debug",
                "--strip-producers",
                "--zero-filled-memory",
                wasm_filename,
                "-o",
                output_file,
            });
        } else |_| {
            try std.fs.copyFileAbsolute(wasm_filename, output_file, .{});
        }
    }
};
