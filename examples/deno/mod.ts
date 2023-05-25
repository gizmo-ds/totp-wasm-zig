import { init, wasm_data, totp, hotp } from 'totp-wasm'
import { assertEquals, base64Decode } from './deps.ts'

await init(base64Decode(wasm_data))

Deno.test({
  name: 'HOTP test',
  fn() {
    const key = 'GM4VC2CQN5UGS33ZJJVWYUSFMQ4HOQJW'
    const counter = BigInt(1662681600)
    const digit = 6
    const code = hotp(key, counter, digit)
    assertEquals(code, 886679)
  },
})

Deno.test({
  name: 'TOTP test',
  fn() {
    const secret = 'GM4VC2CQN5UGS33ZJJVWYUSFMQ4HOQJW'
    const t = BigInt(1662681600)
    const digit = 6
    const period = 30
    const code = totp(secret, t, digit, period)
    assertEquals(code, 473526)
  },
})
