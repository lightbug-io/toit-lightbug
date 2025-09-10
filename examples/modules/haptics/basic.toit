import lightbug.devices as devices
import log

main:
  device := devices.I2C
  // play a medium pattern repeatedly
  device.haptics.pattern1
  while true:
    sleep --ms=1000
