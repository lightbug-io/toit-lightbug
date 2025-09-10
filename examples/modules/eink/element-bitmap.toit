import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
import lightbug.util.bitmaps show lightbug-20-20 lightbug-30-30 lightbug-40-40

main:
  device := devices.I2C

  print "💬 Sending bitmap logo to device screen"
  device.eink.draw-bitmap --status-bar-enable=false --x=0 --y=0 --width=40 --height=40 --bitmap=lightbug-40-40
  
  // Continue running to keep the app alive
  while true:
    sleep --ms=10000