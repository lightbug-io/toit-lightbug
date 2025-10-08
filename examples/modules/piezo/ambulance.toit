import lightbug.devices as devices
import log

main:
  device := devices.I2C --background=false
  device.piezo.ambulance --ms=2000 --intensity=1