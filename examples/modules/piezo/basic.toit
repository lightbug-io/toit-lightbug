import lightbug.devices as devices
import log

main:
  device := devices.I2C
  device.piezo.med
  while true:
    sleep --ms=1000