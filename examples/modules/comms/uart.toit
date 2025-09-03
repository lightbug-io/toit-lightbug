import lightbug.devices as devices
import lightbug.services as services
import log
import gpio
import uart

// A simple application that sets up a Generic device and initiate UART comms with it.
//
// This requires a device connected to a Lightbug device via UART.
// The device must be configured to use the same RX and TX pins as specified in the code
main:
  // The device we are communicating with is connected via UART
  port := uart.Port
    --rx=gpio.Pin 15
    --tx=gpio.Pin 14
    --baud_rate=115200

  // Create a generic UART device using the port we just created
  // Do not send an open or heartbeat messages
  device := devices.UART --port=port --open=false

  // Write some bytes to the device
  log.info "Writing to device"
  device.out.write "hello".to-byte-array --flush=true

  // Read all pending bytes from the device
  // This should include responses to the above messages
  print "Reading all bytes from device"
  read := device.in.read
  print "Read bytes: $read"
