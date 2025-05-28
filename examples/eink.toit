import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
import lightbug.protocol as protocol
import log

// A simple application that draws a simple text page on the E-ink display
main:
  // Setup the Toit logger with the INFO log level
  log.set-default (log.default.with-level log.INFO-LEVEL)

  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

  // Setup the comms service, which allows communication with the Lightbug device
  comms := services.Comms --device=device

  // Send a basic text page to the device to display
  // Create a TextPage message using the new API
  text_page_data := protocol.Data
  text_page_data.add-data-uint messages.TextPage.PAGE-ID 2001
  text_page_data.add-data-string messages.TextPage.PAGE-TITLE "Hello world"
  text_page_data.add-data-string messages.TextPage.LINE-2 "Welcome to your Lightbug device"
  text_page_data.add-data-string messages.TextPage.LINE-3 "running Toit"
  text_page_data.add-data-uint8 messages.TextPage.REDRAW-TYPE 2 // FullRedraw
  
  text_page := messages.TextPage.do-msg --data=text_page_data
  
  latch := comms.send text_page
    --now=true
    --withLatch=true
    --preSend=(:: print "💬 Sending text page to device")
    --postSend=(:: print "💬 Text page sent")
    --onAck=(:: print "✅ Text page ACKed")
    --onNack=(:: print "❌ Text page NACKed")
    --onError=(:: print "❌ Text page error")
  
  print "Waiting on message latch"
  response := latch.get
  // The value of the latch will be false on timeout or unknown error, or the msg object for the response
  // Such as https://docs.lightbug.io/devices/api/tools/parse?bytes=03%2C28%2C00%2C05%2C00%2C04%2C00%2C03%2C04%2C01%2C02%2C04%2C7f%2C0e%2C60%2C9b%2C01%2C00%2C04%2Cd9%2C16%2C00%2C00%2C08%2Cb3%2Cd5%2C9b%2C00%2C00%2C00%2C00%2C00%2C01%2C00%2C01%2C02%2C19%2C27%2Ca9%2C0c
  print "Latch response: $response"