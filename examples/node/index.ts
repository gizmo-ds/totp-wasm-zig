import { init, totp, hotp, steam_guard } from '../../packages/totp-wasm/index'
import { wasm_data } from '../../packages/totp-wasm/dist/wasm_data'

test()

async function test() {
  await init(Buffer.from(wasm_data, 'base64').buffer)

  {
    const key = 'GM4VC2CQN5UGS33ZJJVWYUSFMQ4HOQJW'
    const counter = BigInt(1662681600)
    const digit = 6
    const code = hotp(key, counter, digit)
    console.log(code === 886679)
  }
  {
    const secret = 'GM4VC2CQN5UGS33ZJJVWYUSFMQ4HOQJW'
    const t = BigInt(1662681600)
    const digit = 6
    const period = 30
    const code = totp(secret, t, digit, period)
    console.log(code === 473526)
  }
  {
    const secret = 'GM4VC2CQN5UGS33ZJJVWYUSFMQ4HOQJW'
    const t = BigInt(1662681600)
    const code = steam_guard(secret, t)
    console.log(code === '4PRPM')
  }
}
