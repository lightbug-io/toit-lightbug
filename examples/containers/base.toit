import lightbug.devices as devices
import lightbug.firmware as firmware

main:
  firmware.print-startup-line
  devices.I2C --open=false --background=false --startComms=true