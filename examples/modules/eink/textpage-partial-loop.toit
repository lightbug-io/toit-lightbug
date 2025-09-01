import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that draws a simple text page on the E-ink display
// Then loops to update the page counter every second
main:
  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2
  
  print "💬 Sending hello world page to device"
  device.comms.send (messages.TextPage.msg
    --data=(messages.TextPage.data
      --redraw-type=messages.TextPage.REDRAW-TYPE_FULLREDRAW
      --page-title="Hello world"
      --line-1="Welcome to your Lightbug device"
      --line-2="running Toit!"))
  
  print "Looping to update the page counter every second"
  i := 0
  while true:
    sleep --ms=1000
    i = i + 1
    print "💬 Updating page counter to $i"
    device.comms.send (messages.TextPage.msg
      --data=(messages.TextPage.data
        --redraw-type=messages.TextPage.REDRAW-TYPE_PARTIALREDRAW
        --line-4="$i"))