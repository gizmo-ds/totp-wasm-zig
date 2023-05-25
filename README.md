# totp-wasm-zig

[![License](https://img.shields.io/github/license/gizmo-ds/totp-wasm-zig?style=flat-square)](./LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/gizmo-ds/totp-wasm-zig/testing.yml?branch=main&label=docker%20image&style=flat-square)](https://github.com/gizmo-ds/totp-wasm-zig/actions/workflows/testing.yml)

> **Warning**  
> This project is still in the early stage of development and is not ready for production use.

# Requirements

- [Zig](https://ziglang.org/)
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

## Packaging the totp-wasm JavaScript bundle

```fish
npx esbuild packages/totp-wasm/index.ts --bundle --format=esm --platform=node --target=es2017 --minify --outfile=packages/totp-wasm/index.js
```

# How to install Binaryen?

You can download the latest release of Binaryen from [https://github.com/WebAssembly/binaryen/releases](https://github.com/WebAssembly/binaryen/releases). Once that's done, simply extract the compressed file somewhere. `wasm-opt` will be in the `bin` folder.

## License

Code is distributed under [MIT](./LICENSE) license, feel free to use it in your proprietary projects as well.
