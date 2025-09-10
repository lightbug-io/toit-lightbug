import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
import log

// A simple application that draws a simple bit of text on the E-ink display
main:
  device := devices.I2C

  while true:
    print "💬 Sending circle to device"
    size := (random 4 25)
    // Compute a random position keeping the circle inside the screen.
    x := (random 0 (250 - 1 - size)) - (size / 2)
    y := (random 0 (122 - 1 - size)) - (size / 2)
    device.eink.draw-circle --status-bar-enable=false --x=x --y=y --width=size --height=size
    sleep --ms=2000
