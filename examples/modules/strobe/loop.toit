import lightbug.devices as devices
import log

// A simple application that loops through all of the strobe colors.
main:
  device := devices.I2C

  // Loop through all of the strobe colours forever, changing every second.
  c := 0
  while true:
    c++
    if c == 1:
      device.strobe.red
    else if c == 2:
      device.strobe.green
    else if c == 3:
      device.strobe.blue
    else if c == 4:
      device.strobe.yellow
    else if c == 5:
      device.strobe.magenta
    else if c == 6:
      device.strobe.cyan
    else if c == 7:
      device.strobe.white
    else if c == 8:
      device.strobe.off
      c = 0
    log.info "Strobe set to $c"
    sleep --ms=1000