import lightbug.devices as devices

// A simple application that loops through all of the strobe colors.
main:
  device := devices.I2C --background=false

  // Sequence through the RGB colors, one every 100ms
  device.strobe.sequence --speed-ms=100 --colors=device.strobe.RGB-SEQUENCE