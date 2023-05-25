# totp-wasm-zig

[![License](https://img.shields.io/github/license/gizmo-ds/totp-wasm-zig?style=flat-square)](./LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/gizmo-ds/totp-wasm-zig/testing.yml?branch=main&label=CI&style=flat-square)](https://github.com/gizmo-ds/totp-wasm-zig/actions/workflows/testing.yml)

# Demo

[https://totp-wasm-zig.vercel.app](https://totp-wasm-zig.vercel.app)

# Requirements

- [Zig](https://ziglang.org/) (0.11.0-dev.3295+7cb2e653a)
- [Binaryen](https://github.com/WebAssembly/binaryen) (Optional but recommended)
- [Node.js](https://nodejs.org) (Optional)

# Build

## Compiling WebAssembly

To reduce the size of the `.wasm` file, you can choose to install [Binaryen](https://github.com/WebAssembly/binaryen).

[How to install Binaryen?](#how-to-install-binaryen)

```fish
zig build
zig build bind
```

# How to install Binaryen?

You can download the latest release of Binaryen from [https://github.com/WebAssembly/binaryen/releases](https://github.com/WebAssembly/binaryen/releases). Once that's done, simply extract the compressed file somewhere. `wasm-opt` will be in the `bin` folder.

# Related Projects

Here are some related projects that you may find useful:

- [totp-wasm](https://github.com/gizmo-ds/totp-wasm): Rust implementation of this project.
- [UdonOTPLib](https://github.com/gizmo-ds/UdonOTPLib): C# implementation for the VRChat game.

## License

Code is distributed under [MIT](./LICENSE) license, feel free to use it in your proprietary projects as well.
