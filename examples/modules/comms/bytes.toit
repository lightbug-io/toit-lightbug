import lightbug.devices as devices
import lightbug.services as services
import log

// A simple application that sets up a Lightbug device and starts sending raw bytes to it
main:
  // Do not send an open or heartbeat messages
  device := devices.I2C --open=false

  // Send a currently valid, but unused message to the device, with a device ID.
  // The device will ignore it, but it will ACK the message
  print "Writing unused msg to device"
  device.out.write #[3, 17, 0, 231, 3, 1, 0, 1, 4, 231, 3, 0, 0, 0, 0, 184, 115] --flush=true

  // Send an open to the device
  // This will start the device and allow it to send heartbeats
  // There is no message ID so no ACK is expected
  print "Writing open msg to device"
  device.out.write #[3, 11, 0, 11, 0, 0, 0, 0, 0, 73, 56] --flush=true

  // Read all pending bytes from the device
  // This should include response to the first message
  print "Reading all bytes from device"
  read := device.in.read
  print "Read bytes: $read"
