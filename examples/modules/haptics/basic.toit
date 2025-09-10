import lightbug.devices as devices
import log

main:
  device := devices.I2C
  device.haptics.fade
  while true:
    sleep --ms=1000
