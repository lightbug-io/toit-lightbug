import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.modules.comms.message-handler show MessageHandler
import lightbug.modules.strobe.strobe show Strobe
import lightbug.protocol as protocol
import log

main:
  device := (devices.I2C --open=false --logger=((log.default.with-name "lb").with-level log.DEBUG-LEVEL) ).comms
  while true:
    sleep --ms=10000
