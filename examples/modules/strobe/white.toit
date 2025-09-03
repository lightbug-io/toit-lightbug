import lightbug.devices as devices
import log

main:
  (devices.I2C).strobe.white
  while true:
    sleep --ms=1000