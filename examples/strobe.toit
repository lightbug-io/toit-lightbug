import lightbug.devices as devices
import log

// A simple application that loops throguh all of the strobe colors
main:
  // Setup the Toit logger with the INFO log level
  log.set-default (log.default.with-level log.INFO-LEVEL)

  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

  // Loop through all of the strobe colours forever
  c := 0
  while true:
    c++
    if c == 1:
      device.strobe.set true false false // Red
    else if c == 2:
      device.strobe.set false true false // Green
    else if c == 3:
      device.strobe.set false false true // Blue
    else if c == 4:
      device.strobe.set true true false // Yellow
    else if c == 5:
      device.strobe.set true false true // Magenta
    else if c == 6:
      device.strobe.set false true true // Cyan
    else if c == 7:
      device.strobe.set true true true // White
    else if c == 8:
      device.strobe.set false false false // Off
      c = 0
    log.info "Strobe set to $c"
    sleep --ms=1000