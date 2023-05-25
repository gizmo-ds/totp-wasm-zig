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

export function hotp(key: string, counter: bigint, digit: number): number {
  if (!instance) return 0
  const str = to_cstr(instance, memory, key)
  const hotp = instance.exports.hotp as hotp_func
  const code = hotp(str.ptr, str.len, counter, digit)
  free(instance, str.ptr)
  return code
}

export function totp(secret: string, t: bigint, digit: number, period: number): number {
  if (!instance) return 0
  const str = to_cstr(instance, memory, secret)
  const totp = instance.exports.totp as totp_func
  const code = totp(str.ptr, str.len, t, digit, period)
  free(instance, str.ptr)
  return code
}

interface hotp_func {
  (ptr: number, len: number, counter: bigint, digit: number): number
}
interface totp_func {
  (ptr: number, len: number, t: bigint, digit: number, period: number): number
}
