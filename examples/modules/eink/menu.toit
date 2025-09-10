import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that draws a simple text page on the E-ink display
main:
  device := devices.I2C
  
  print "💬 Sending a menu to the device"
  device.eink.send-menu --items=["Option 1", "Option 2", "Option 3", "Option 4"] --selected-item=1
  
  while true:
    sleep --ms=10000