# totp-wasm-zig

[![License](https://img.shields.io/github/license/gizmo-ds/totp-wasm-zig?style=flat-square)](./LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/gizmo-ds/totp-wasm-zig/testing.yml?branch=main&label=CI&style=flat-square)](https://github.com/gizmo-ds/totp-wasm-zig/actions/workflows/testing.yml)

## Demo

[https://totp-wasm-zig.vercel.app](https://totp-wasm-zig.vercel.app)

## Requirements

- [Zig](https://ziglang.org/download/) (0.13.0)
- [Binaryen](https://github.com/WebAssembly/binaryen) (Optional but recommended)
- [Node.js](https://nodejs.org) (Optional)

## Usage

### Deno

```typescript
import { totp, init, wasm_data } from 'https://deno.land/x/totp_wasm/deno/mod.ts'

await init(wasm_data)
const code = totp('GM4VC2CQN5UGS33ZJJVWYUSFMQ4HOQJW', 1662681600, 6, 30)
console.log(code)
// 473526
```

### Browser

[example](./examples/browser)

### Node.js

[example](./examples/node)

### Bun

[example](./examples/bun)

## Build

### Compiling WebAssembly

Requirements:

- [Zig](https://ziglang.org/download/) (0.13.0)
- [Node.js](https://nodejs.org) (Optional)

```fish
# pnpm install
zig build
zig build bind
```

## Related Projects

Here are some related projects that you may find useful:

- [totp-wasm](https://github.com/gizmo-ds/totp-wasm): Rust implementation of this project.
- [UdonOTPLib](https://github.com/gizmo-ds/UdonOTPLib): C# implementation for the VRChat game.

## License

Code is distributed under [MIT](./LICENSE) license, feel free to use it in your proprietary projects as well.
