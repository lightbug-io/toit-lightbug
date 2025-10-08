import lightbug.devices as devices
import log

main:
  device := devices.I2C --background=false
  device.haptics.fade
