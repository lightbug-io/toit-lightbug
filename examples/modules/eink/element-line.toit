import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that draws a simple bit of text on the E-ink display
main:
  device := devices.I2C --background=false
  
  print "💬 Sending line to device"
  device.eink.draw-line --status-bar-enable=false --x=0 --y=(122/2) --x2=(250 - 1) --y2=(122/2)
