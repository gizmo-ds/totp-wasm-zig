export { hotp, totp, steam_guard, init } from '../../../packages/totp-wasm/index'
import _wasm_url from '../../../packages/totp-wasm/dist/totp-wasm.wasm?url'
export const wasm_url = _wasm_url
