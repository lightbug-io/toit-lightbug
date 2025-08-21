import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that draws a simple text page on the E-ink display
main:
  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2
  
  print "💬 Sending a menu to the device"
  device.comms.send (messages.MenuPage.msg
    --data=(messages.MenuPage.data
      // --redraw-type=messages.MenuPage.REDRAW-TYPE_FULLREDRAW
      --item-count=3
      --initial-item-selection=3
      --item-1="Option 1"
      --item-2="Option 2"
      --item-3="Option 3"))
    --now=true