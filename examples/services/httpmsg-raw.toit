import lightbug.devices as devices
import lightbug.services as services

// A simple application that sets up a Lightbug device and starts a HTTP server
// that allows sending messages to the device.
//
// This is a more "raw" version than the `httpmsg` example, as it doesn't
// automatically send an open on startup, and it will output ALL received messages
// to the web view.
main:
  // This example is setup to work with the RH2 device
  // Don't send an initial open message, allowing you full message control
  device := devices.RtkHandheld2 --open=false

  // Start heartbeats to keep connection alive once opened (even though we don't open it)
  // The user can click OPEN in the UI, and heartbeats will maintain the connection
  device.comms.heartbeats.start

  // Start the HTTP Message server on port 80
  // This allows communicating with the device via a HTTP page
  services.HttpMsg device --serve=true --listen-and-log-all=true

  // And start a service that prints all received messages to the console
  // To see the messages, `jag monitor` the device that is running this code
  services.MsgPrinter device
