import lightbug.devices as devices
import lightbug.services as services
import log

// A simple application that sets up a Lightbug device and initiate I2C communications with it.
main:
  // Setup the Toit logger wiht the debug log level, so you can see lower level I2C operations
  log.set-default (log.default.with-level log.DEBUG-LEVEL)

  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

  // Setup the comms service, which allows communication with the Lightbug device, but disable the default processing operations
  comms := services.Comms --device=device --startInbound=false --startOutbox=false --sendOpen=false --sendHeartbeat=false

  // Write some bytes to the device

  // Send a currently valid, but unused message https://docs.lightbug.io/devices/api/tools/parse?bytes=3+11+0+231+3+0+0+0+0+64+86
  // This will be ignored by the device
  print "Writing unused msg to device"
  device.out.write #[3, 11, 0, 231, 3, 0, 0, 0, 0, 64, 86] --flush=true

  // Send an open https://docs.lightbug.io/devices/api/tools/parse?bytes=3+11+0+11+0+0+0+0+0+73+56
  // The device will ACK this, and start sending heartbeats
  print "Writing open msg to device"
  device.out.write #[3, 11, 0, 11, 0, 0, 0, 0, 0, 73, 56] --flush=true

  // Read all pending bytes
  // This should include the ACK for the message above
  print "Reading all bytes from device"
  read := device.in.read-all
  print "Read bytes: $read"
