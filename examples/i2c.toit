import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages as messages
import log

// A simple application that sets up a Lightbug device and initiate I2C communications with it.
main:
  // Setup the Toit logger wiht the debug log level
  log.set-default (log.default.with-level log.DEBUG-LEVEL)

  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

  // Setup the comms service, which allows communication with the Lightbug device, but don't start any part of it
  comms := services.Comms --device=device 

  // while true:
  //   comms.send messages.UbloxPlData.get-msg
  //   sleep --ms=2000

  comms.send 
    messages.GsmOwnership.set-msg 1 --minutes=60