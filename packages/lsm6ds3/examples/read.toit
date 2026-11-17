// Demonstrates direct and FIFO accelerometer/gyroscope reads over I2C.

import i2c
import lsm6ds3 as imu

// Standalone ESP32 example. Adapt pins/address to your board. On RH2 use the
// combined examples/motion/rh2.toit program instead, to share the V3 bus owner.
main:
  bus := i2c.Bus --sda=21 --scl=22 --frequency=100_000
  sensor := imu.Driver (bus.device imu.ADDRESS-HIGH)
  try:
    sensor.reset
    deadline := Time.monotonic-us + 100_000
    while sensor.reset-pending:
      if Time.monotonic-us >= deadline: throw "IMU reset timed out"
      sleep --ms=2
    sensor.configure
        --accel-rate=imu.Driver.RATE-104HZ
        --gyro-rate=imu.Driver.RATE-104HZ
        --accel-range=imu.Driver.ACCEL-RANGE-4G
        --gyro-range=imu.Driver.GYRO-RANGE-500DPS
    sleep --ms=200
    // A direct snapshot is useful for interactive measurements, but not history.
    acceleration := sensor.read-3-axis
    print "snapshot m/s^2: $(acceleration.x),$(acceleration.y),$(acceleration.z)"
    // FIFO preserves sample order even when the application reads in batches.
    sensor.start-fifo
        --mode=imu.Driver.FIFO-CONTINUOUS
        --rate=imu.Driver.RATE-104HZ
    count := 0
    while true:
      frames := sensor.read-fifo
      frames.do: | sample/imu.Sample |
        count++
        if count % 104 == 0:
          print "accel m/s^2: $(sample.ax),$(sample.ay),$(sample.az); gyro rad/s: $(sample.gx),$(sample.gy),$(sample.gz); clipped=$(sample.clipped)"
      sleep --ms=2
  finally:
    try:
      sensor.stop
    finally:
      bus.close
