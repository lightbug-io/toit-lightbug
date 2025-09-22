import lightbug.devices as devices
import lightbug.messages.messages_gen as messages

main:
  device := devices.I2C
  
  device.eink.draw-element --status-bar-enable=false --type=messages.DrawElement.TYPE_BOX --x=0 --y=50 --text="Not home..."
  device.eink.show-preset --page-id=1
  
  while true:
    sleep --ms=10000