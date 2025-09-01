import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that draws a simple bit of text on the E-ink display
main:
  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2
  
  print "💬 Sending circle to device"
  device.comms.send (messages.DrawElement.msg
    --data=(messages.DrawElement.data
      --page-id=(random 10 255)
      --status-bar-enable=false
      --type=messages.DrawElement.TYPE_CIRCLE
      --x=(250/2) - 10
      --y=(122/2) - 10
      --width=20
      --height=20
      ))
  
  while true:
    sleep --ms=10000