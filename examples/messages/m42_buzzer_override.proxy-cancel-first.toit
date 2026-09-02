import lightbug.devices as devices
import .m42_buzzer_override show run

// Same buzzer-override demo as m42_buzzer_override.proxy.toit, but with the
// duration-0 cancel workaround enabled, so you can compare both behaviors
// through the proxy without needing -D (unsupported with -d host). The
// workaround is only needed on firmware that predates the fix for this bug.
// Start `squish chasm proxy --device <ID>` first, then:
//   jag run -d host examples/messages/m42_buzzer_override.proxy-cancel-first.toit

// TODO once fixed in FW, this file should be removed

main:
  run devices.Proxy --cancel-first
