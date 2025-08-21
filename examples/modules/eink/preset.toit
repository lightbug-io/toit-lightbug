import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that requests the device to display its home page
main:
  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2
  
  print "💬 Sending request for home page to device"
  device.comms.send (messages.PresetPage.msg)
    --now=true