const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const wasm = b.addExecutable(.{
        .name = "totp-wasm-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        }),
        .optimize = .ReleaseSmall,
    });

    wasm.entry = .disabled;
    wasm.import_memory = true;
    wasm.rdynamic = true;

    b.installArtifact(wasm);

    const test_step = b.step("test", "Run tests");
    {
        const otp_tests = b.addTest(.{
            .root_source_file = b.path("src/otp.zig"),
            .target = target,
            .optimize = optimize,
        });
        const run_otp_tests = b.addRunArtifact(otp_tests);
        test_step.dependOn(&run_otp_tests.step);
    }
    {
        const base32_tests = b.addTest(.{
            .root_source_file = b.path("src/base32.zig"),
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
    step: std.Build.Step,
    wasm: *std.Build.Step.Compile,

    pub fn create(owner: *std.Build, wasm: *std.Build.Step.Compile) *GenWasmDateStep {
        const self = owner.allocator.create(GenWasmDateStep) catch unreachable;
        self.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = "gen wasmdata",
                .owner = owner,
                .makeFn = GenWasmDateStep.make,
            }),
            .wasm = wasm,
        };
        return self;
    }

    pub fn make(step: *std.Build.Step, _: std.Progress.Node) anyerror!void {
        const self: *GenWasmDateStep = @fieldParentPtr("step", step);
        const alloc = self.step.owner.allocator;
        const base64_encoder = std.base64.standard.Encoder;
        const wasmopt_out = try std.fs.path.join(alloc, &.{
            self.step.owner.build_root.path.?,
            "packages/totp-wasm/dist/totp-wasm.wasm",
        });

        const wasmfile = try std.fs.openFileAbsolute(wasmopt_out, .{ .mode = .read_only });
        defer wasmfile.close();

        const meta = try wasmfile.metadata();
        const buf = try alloc.alloc(u8, meta.size());
        defer alloc.free(buf);
        _ = try wasmfile.readAll(buf);

        const encoded = try alloc.alloc(u8, base64_encoder.calcSize(buf.len));
        defer alloc.free(encoded);
        _ = base64_encoder.encode(encoded, buf);

        var wasmdata = std.ArrayList(u8).init(alloc);
        defer wasmdata.deinit();
        try wasmdata.appendSlice("// @ts-nocheck wasmdata\nexport const wasm_data = \"");
        try wasmdata.appendSlice(encoded);
        try wasmdata.appendSlice("\";");

        var wasmdata_file = std.fs.cwd().createFile("packages/totp-wasm/dist/wasm_data.js", .{}) catch unreachable;
        defer wasmdata_file.close();
        try wasmdata_file.writeAll(wasmdata.items);
    }
};

const OptimizeWasmStep = struct {
    step: std.Build.Step,
    wasm: *std.Build.Step.Compile,

    pub fn create(owner: *std.Build, wasm: *std.Build.Step.Compile) *OptimizeWasmStep {
        const self = owner.allocator.create(OptimizeWasmStep) catch unreachable;
        self.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = "optimize wasm",
                .owner = owner,
                .makeFn = OptimizeWasmStep.make,
            }),
            .wasm = wasm,
        };
        return self;
    }

    pub fn make(step: *std.Build.Step, _: std.Progress.Node) anyerror!void {
        const self: *OptimizeWasmStep = @fieldParentPtr("step", step);
        const owner = self.step.owner;

        const wasm_filename = try std.fs.path.join(owner.allocator, &.{
            owner.exe_dir,
            self.wasm.out_filename,
        });
        const output_file = try std.fs.path.join(owner.allocator, &.{
            owner.build_root.path.?,
            "packages/totp-wasm/dist/totp-wasm.wasm",
        });

        if (owner.findProgram(&.{"wasm-opt"}, &.{"node_modules/.bin"})) |opt| {
            _ = owner.run(&.{
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
