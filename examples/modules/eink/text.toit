import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// A simple application that draws a simple text page on the E-ink display
main:
  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

  // Setup the comms service, which allows communication with the Lightbug device
  comms := services.Comms --device=device
  
  print "💬 Sending hello world page to device"
  comms.send (messages.TextPage.msg
    --data=(messages.TextPage.data
      --redraw-type=messages.TextPage.REDRAW-TYPE_FULLREDRAW
      --page-title="Hello world"
      --line-1="Welcome to your Lightbug device"
      --line-2="running Toit!"))
    --now=true