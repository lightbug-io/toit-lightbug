import lightbug.devices as devices
import lightbug.services as services
import log

// A simple application that sets up a Lightbug device and initiate I2C communications with it.
main:
  // Setup the Toit logger wiht the debug log level
  log.set-default (log.default.with-level log.DEBUG-LEVEL)

  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

  // Setup the comms service, which allows communication with the Lightbug device, but don't start any part of it
  comms := services.Comms --device=device --startInbound=false --startOutbox=false --sendOpen=false --sendHearbeat=false

  // Write some bytes to the device
  // A currently valid, but unused message https://docs.lightbug.io/devices/api/tools/parse?bytes=3+17+0+561+3+0+0+0+0+100+134
  print "Writing unused msg to device"
  device.out.write #[3, 11, 0, 231, 3, 0, 0, 0, 0, 64, 86] --flush=true
  // And an open
  print "Writing open msg to device"
  device.out.write #[3, 11, 0, 11, 0, 0, 0, 0, 0, 73, 56] --flush=true

  // Read all bytes
  print "Reading all bytes from device"
  read := device.in.read-all
  print "Read bytes: $read"
