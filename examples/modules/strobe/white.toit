import lightbug.devices as devices
import log

main:
  (devices.RtkHandheld2).strobe.white
  while true:
    sleep --ms=1000