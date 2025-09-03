import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that draws a simple bit of text on the E-ink display
main:
  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

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
