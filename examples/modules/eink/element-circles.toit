import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
import log

// A simple application that draws a simple bit of text on the E-ink display
main:
  device := devices.I2C

  page := (random 10 255)

  while true:
    print "💬 Sending circle to device"
    size := (random 1 25)
    
    device.comms.send (messages.DrawElement.msg
      --data=(messages.DrawElement.data
        --page-id=page
        --status-bar-enable=false
        --type=messages.DrawElement.TYPE_CIRCLE
        --x=(random 0 (250 - 1 - size)) - (size/2)
        --y=(random 0 (250 - 1 - size)) - (size/2)
        --width=size
        --height=size
        ))
    sleep --ms=2000
