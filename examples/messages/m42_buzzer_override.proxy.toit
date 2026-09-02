import lightbug.devices as devices
import .m42_buzzer_override show run

// Same buzzer-override demo as m42_buzzer_override.toit, but connects through
// a local `squish chasm proxy --device <ID>` process instead of physical I2C -
// the first example of the squish chasm proxy transport (devices.Proxy).
// The bug it reproduces is fixed in a future firmware release; on fixed
// firmware the Siren should play immediately even without the workaround.
// Start the proxy first, then:
//   jag run -d host examples/messages/m42_buzzer_override.proxy.toit

// TODO once fixed in FW, this and the nearby examples should be updated (and this comment)

main:
  run devices.Proxy
