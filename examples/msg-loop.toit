import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages as messages
import log

// A simple application that sets up a Lightbug device and initiate I2C communications with it, then sending a single message in a loop
main:
  // Setup the Toit logger wiht the debug log level, so you can see lower level I2C operations
  log.set-default (log.default.with-level log.DEBUG-LEVEL)

  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

  // Setup the comms service, which allows communication with the Lightbug device
  comms := services.Comms --device=device

  // Write a message to the device in a loop, every 5 seconds
  // While running `jag monitor` on the device, you should see the messages being sent, and a response being received
  while true:
    response := comms.send 
      messages.DeviceIds.get-msg
      --preSend=(:: print "Sending message to device")
      --postSend=(:: print "Message sent to device")
      --withLatch=true
    if response:
      print "Response: $response"
    else:
      print "No response from device"
    sleep --ms=5000