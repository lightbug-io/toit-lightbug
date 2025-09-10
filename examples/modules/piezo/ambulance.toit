import lightbug.devices as devices
import log

main:
  device := devices.I2C
  device.piezo.ambulance --ms=2000 --intensity=1
  while true:
    sleep --ms=1000