import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
import lightbug.util.bitmaps show lightbug-20-20 lightbug-30-30 lightbug-40-40

/**
A simple application that demonstrates drawing bitmaps on the E-ink display.
This example shows how to display a Lightbug logo.
*/
main:
  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2
  
  page := (random 10 255)
  screen-width := 250
  screen-height := 122
  bitmap-dimension := 40
  positions := [
    [messages.DrawElement.REDRAW-TYPE_CLEARDONTDRAW, 0, 0], // Top left
    [messages.DrawElement.REDRAW-TYPE_BUFFERONLY, (screen-width - 1 - bitmap-dimension), 0], // Top right
    [messages.DrawElement.REDRAW-TYPE_BUFFERONLY, 0, (screen-height - 1 - bitmap-dimension)], // Bottom left
    [messages.DrawElement.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR, (screen-width - 1 - bitmap-dimension), (screen-height - 1 - bitmap-dimension)], // Bottom right
  ]

  print "💬 Sending bitmap logos to device screen"
  positions.do: | p |
    device.comms.send (messages.DrawElement.msg
      --data=(messages.DrawElement.data
        --page-id=page
        --status-bar-enable=false
        --redraw-type=p[0]
        --x=p[1]
        --y=p[2]
        --width=bitmap-dimension
        --height=bitmap-dimension
        --type=messages.DrawElement.TYPE_BITMAP
        --bitmap=lightbug-40-40))
  
  // Continue running to keep the app alive
  while true:
    sleep --ms=10000