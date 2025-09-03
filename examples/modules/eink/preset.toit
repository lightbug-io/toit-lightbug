import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that requests the device to display its home page
main:
  device := devices.I2C
  
  print "💬 Sending request for home page to device"
  device.comms.send (messages.BasePage.msg
    --data=(messages.BasePage.data
      --page-id=1
      --status-bar-enable=true))