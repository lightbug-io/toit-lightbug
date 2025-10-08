import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that draws a simple bit of text on the E-ink display
main:
  device := devices.I2C --background=false
  
  print "💬 Sending text to device"
  page := (random 10 255)
  device.eink.draw-element --page-id=page --status-bar-enable=false --type=messages.DrawElement.TYPE_BOX --x=0 --y=0 --text="Lightbug..."
