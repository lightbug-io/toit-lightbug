import lightbug.devices as devices
import lightbug.services as services
import log
import gpio
import uart

// A simple application that sets up a Generic device and initiate UART communications with it.
main:
  // Setup the Toit logger with the debug log level, so you can see lower level I2C operations
  log.set-default (log.default.with-level log.DEBUG-LEVEL)

  // The device we are communicating with is connected via UART
  port := uart.Port
    --rx=gpio.Pin 15
    --tx=gpio.Pin 14
    --baud_rate=115200

  // Create a generic UART device using the port we just created
  device := devices.GenericUart --port=port

  // Setup the comms service, which allows communication with the device, but disable the default processing operations
  comms := services.Comms --device=device --startInbound=false --startOutbox=false --sendOpen=false --sendHeartbeat=false

  // Write some bytes to the device
  log.info "Writing to device"
  device.out.write "hello".to-byte-array --flush=true