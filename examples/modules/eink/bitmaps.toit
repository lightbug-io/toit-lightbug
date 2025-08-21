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
  
  print "💬 Sending bitmap logo to device screen"
  
  print "📷 Drawing 40x40 logo at (0,0) top left"
  device.comms.send (messages.DrawBitmap.msg
    --data=(messages.DrawBitmap.data
      --page-id=1234
      --redraw-type=messages.DrawBitmap.REDRAW-TYPE_FULLREDRAW
      --x=0
      --y=0
      --width=40
      --height=40
      --bitmap=lightbug-40-40))
    --now=true

  print "📷 Drawing a second 40x40 logo at (210,0) top right"
  device.comms.send (messages.DrawBitmap.msg
    --data=(messages.DrawBitmap.data
      --page-id=1234
      --redraw-type=messages.DrawBitmap.REDRAW-TYPE_PARTIALREDRAW
      --x=209
      --y=0
      --width=40
      --height=40
      --bitmap=lightbug-40-40))
    --now=true