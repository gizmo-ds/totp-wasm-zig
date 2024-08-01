import { to_cstr, free } from './wasm'

const memory = new WebAssembly.Memory({ initial: 250 })
const imports = { env: { memory } }

let instance: WebAssembly.Instance | undefined

export async function init(r: BufferSource | Response | PromiseLike<Response>) {
  if (instance) return
  const m =
    r instanceof Promise || r instanceof Response
      ? await WebAssembly.instantiateStreaming(r, imports)
      : await WebAssembly.instantiate(r as BufferSource, imports)
  instance = m.instance
}

export function hotp(key: string, counter: bigint, digit: number): string {
  if (!instance) return ''
  const str = to_cstr(instance, memory, key)
  const hotp = instance.exports.hotp as hotp_func
  const output_ptr = hotp(str.ptr, str.len, counter, digit)
  const code = new TextDecoder().decode(new Uint8Array(memory.buffer, output_ptr, 6))
  free(instance, str.ptr)
  free(instance, output_ptr)
  return code
}

export function totp(secret: string, t: bigint, digit: number, period: number): string {
  if (!instance) return ''
  const str = to_cstr(instance, memory, secret)
  const totp = instance.exports.totp as totp_func
  const output_ptr = totp(str.ptr, str.len, t, digit, period)
  const code = new TextDecoder().decode(new Uint8Array(memory.buffer, output_ptr, 6))
  free(instance, str.ptr)
  free(instance, output_ptr)
  return code
}

export function steam_guard(secret: string, t: bigint): string {
  if (!instance) return ''
  const str = to_cstr(instance, memory, secret)
  const steam_guard = instance.exports.steam_guard as steam_guard_func
  const output_ptr = steam_guard(str.ptr, str.len, t)
  const code = new TextDecoder().decode(new Uint8Array(memory.buffer, output_ptr, 5))
  free(instance, str.ptr)
  free(instance, output_ptr)
  return code
}

interface hotp_func {
  (ptr: number, len: number, counter: bigint, digit: number): number
}
interface totp_func {
  (ptr: number, len: number, t: bigint, digit: number, period: number): number
}

interface steam_guard_func {
  (ptr: number, len: number, t: bigint): number
}
