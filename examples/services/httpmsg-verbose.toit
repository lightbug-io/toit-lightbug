import lightbug.devices as devices
import lightbug.services as services

// A simple application that sets up a Lightbug device and starts a HTTP server
// that allows sending messages to the device.
//
// ALL received messages will be printed to the web view, and visible via `jag monitor`.
//
// This example can be used with the Lightbug documentation site message generator, and message examples
// to directly send messages to the device, and see the responses, when on the same network.
main:
  // This example is setup to work with the RH2 device
  // Don't send an initial open message, allowing you full message control
  device := devices.I2C --background=false

  services.HttpMsg device --serve=true --listen-and-log-all=true
  services.MsgPrinter device
