import lightbug.devices as devices
import lightbug.services as services
import log

// A simple application that sets up a Lightbug device and starts sending raw bytes to it
main:
  // RtkHandheld2 is a Lightbug device that uses I2C, and is pre-configured
  // Do not send an open or heartbeat messages
  device := devices.RtkHandheld2 --open=false

  // Send a currently valid, but unused message to the device
  // The device will ignore it, but it will ACK the message
  // https://docs.lightbug.io/devices/api/tools/parse?bytes=3+11+0+231+3+0+0+0+0+64+86
  print "Writing unused msg to device"
  device.out.write #[3, 11, 0, 231, 3, 0, 0, 0, 0, 64, 86] --flush=true

  // Send an open to the device
  // This will start the device and allow it to send heartbeats
  // https://docs.lightbug.io/devices/api/tools/parse?bytes=3+11+0+11+0+0+0+0+0+73+56
  print "Writing open msg to device"
  device.out.write #[3, 11, 0, 11, 0, 0, 0, 0, 0, 73, 56] --flush=true

  // Read all pending bytes from the device
  // This should include responses to the above messages
  print "Reading all bytes from device"
  read := device.in.read
  print "Read bytes: $read"
