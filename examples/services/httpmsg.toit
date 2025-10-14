import lightbug.devices as devices
import lightbug.services as services

// A simple application that sets up a Lightbug device and starts a HTTP server
// that allows sending messages to the device.
//
// Received responses are printed to the web view.
// Any received messages are also printed to the console, visible via `jag monitor`
//
// This example can be used with the Lightbug documentation site message generator, and message examples
// to directly send messages to the device, and see the responses, when on the same network.
main:
  // Don't handle any messages from P1 by default
  device := devices.I2C --background=false --with-default-handlers=false

  services.HttpMsg device --serve=true
  services.MsgPrinter device
