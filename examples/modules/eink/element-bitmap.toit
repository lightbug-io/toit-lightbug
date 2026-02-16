import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
import lightbug.util.bitmaps.lightbug-40-40 show *

main:
  device := devices.I2C --background=false

  print "💬 Sending bitmap to device screen"
  device.eink.draw-bitmap --status-bar-enable=false --x=0 --y=0 --width=LIGHTBUG-40-40-WIDTH --height=LIGHTBUG-40-40-HEIGHT --bitmap=LIGHTBUG-40-40-DATA
