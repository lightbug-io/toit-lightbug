import esp32
import lightbug.devices as devices
import lightbug.modules.power show Cpu2Sleep

// This example owns whole-chip sleep. Coordinate other containers first.
main:
  esp32.ext1-wakeup-status (1 << 7)
  device := devices.I2C --open=false --reinit-on-comms-start=false
  power := Cpu2Sleep device.comms --wake-message-types=[48]
  power.start-awake device

  // Keep a programming window on cold boot; skip it after deep-sleep wake.
  if esp32.reset-reason != esp32.RESET-DEEPSLEEP: sleep (Duration --s=20)
  while not (power.deep-sleep device --duration=(Duration --h=1)):
    sleep (Duration --s=5)
