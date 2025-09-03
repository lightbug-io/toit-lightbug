import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that draws a simple bit of text on the E-ink display
main:
  device := devices.I2C
  
  print "💬 Sending line to device"
  device.comms.send (messages.DrawElement.msg
    --data=(messages.DrawElement.data
      --page-id=(random 10 255)
      --status-bar-enable=false
      --type=messages.DrawElement.TYPE_LINE
      --x=0
      --y=(122/2)
      --x2=(250 - 1)
      --y2=(122/2)
      ))
  
  while true:
    sleep --ms=10000