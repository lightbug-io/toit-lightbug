import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
import log

// A simple application that draws a simple bit of text on the E-ink display
main:
  device := devices.I2C --background=false
  
  print "💬 Sending circle to device"
  device.eink.draw-circle  --status-bar-enable=false --x=(250/2) - 10 --y=(122/2) - 10 --width=20 --height=20
