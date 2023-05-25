export function malloc(instance: WebAssembly.Instance, size: number): number {
  return (instance.exports.malloc as (size: number) => number)(size + 1)
}
export function free(instance: WebAssembly.Instance, ptr: number): void {
  ;(instance.exports.free as (ptr: number) => number)(ptr)
}
export function to_cstr(
  instance: WebAssembly.Instance,
  memory: WebAssembly.Memory,
  s: string
): { ptr: number; len: number } {
  const buf = new TextEncoder().encode(s)
  const ptr = malloc(instance, buf.length)
  new Uint8Array(memory.buffer, ptr, buf.length).set(buf)
  new Uint8Array(memory.buffer, ptr + buf.length, 1).set([0])
  return { ptr, len: buf.length }
}
