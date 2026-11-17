// Reads fresh magnetic field samples from an LIS2MDL over I2C.

import i2c
import lis2mdl as mag

// Adapt pins to your board. Use the combined motion example on RH2 so this
// sensor and the STM32 transport share one bus owner.
main:
  bus := i2c.Bus --sda=21 --scl=22 --frequency=100_000
  sensor := mag.Driver (bus.device mag.ADDRESS)
  try:
    sensor.reset
    deadline := Time.monotonic-us + 100_000
    while sensor.reset-pending:
      if Time.monotonic-us >= deadline: throw "Magnetometer reset timed out"
      sleep --ms=2
    sensor.configure
        --rate=mag.Driver.RATE-20HZ
        --mode=mag.Driver.MODE-CONTINUOUS
        --power=mag.Driver.POWER-HIGH-RESOLUTION
    while true:
      // Polling never blocks the application waiting for the next measurement.
      sample := sensor.read-if-ready
      if sample:
        field := sample.field
        print "magnetic uT: $(field.x),$(field.y),$(field.z); overrun=$(sample.overrun); clipped=$(sample.clipped)"
      sleep --ms=20
  finally:
    try:
      sensor.stop
    finally:
      bus.close
