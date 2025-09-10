import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
import lightbug.modules as modules
import log

// A simple application that draws a simple text page on the E-ink display
// Then loops to update the page counter every second
main:
  device := devices.I2C
  
  print "💬 Sending hello world page to device"
  // Buffer the text page and clear previous content
  device.eink.text-page --page-title="Hello world" --lines=["Welcome to your Lightbug device", "running Toit!"] --status-bar-enable

  print "Looping to update the page counter every second"
  startTime := Time.now
  sleep --ms=1000
  while true:
    i := (Time.now.s-since-epoch - startTime.s-since-epoch)
    print "💬 Sending counter update $i"
    device.eink.text-page --lines=[null, null, null, ("$i")]
    sleep --ms=1000