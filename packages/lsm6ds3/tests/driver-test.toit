// Checks LSM6DS3 scaling, configuration, FIFO and error handling with a fake device.
// Run standalone or through tests/motion/drivers.test.toit.

import io.byte-order show LITTLE-ENDIAN
import lsm6ds3 as imu

class Registers:
  bytes := ByteArray 256
  writes := []
  fifo := ByteArray 48
  last-fifo-size/int := 0
  overrun-after-read/bool := false
  fail/bool := false
  fail-after/int? := null
  short-read/bool := false
  constructor:
    bytes[0x0f] = 0x69
    bytes[0x4f] = 0x40
  write data/ByteArray:
    if fail or (fail-after != null and writes.size >= fail-after): throw "I2C_NACK"
    writes.add data
    (data.size - 1).repeat: bytes[data[0] + it] = data[it + 1]
  read-reg reg/int size/int -> ByteArray:
    if fail: throw "I2C_NACK"
    if short-read: return ByteArray (size - 1)
    if reg == 0x3e:
      last-fifo-size = size
      if overrun-after-read: bytes[0x3b] |= 0x40
      return fifo[0..size]
    return bytes[reg..reg + size]
  read-bytes address/int size/int -> ByteArray: return read-reg address size
  write-bytes address/int data/ByteArray: write (#[address] + data)

check condition/bool message/string:
  if not condition: throw message

main:
  registers := Registers
  sensor := imu.Driver registers
  sensor.reset
  check sensor.reset-pending "IMU reset not requested"
  check ((catch: sensor.configure) != null) "Accepted unfinished reset"
  registers.bytes[0x12] = 0
  sensor.configure
  check (registers.bytes[0x0a] == 0) "Configure implicitly started FIFO"
  sensor.start-fifo
  check (registers.bytes[0x12] == 0x44 and registers.bytes[0x10] == 0x4c and registers.bytes[0x11] == 0x48) "Wrong IMU scale/ODR"
  check (registers.bytes[0x08] == 9 and registers.bytes[0x0a] == 0x26) "Wrong FIFO profile"
  check sensor.read-fifo.is-empty "Read empty FIFO"
  registers.bytes[0x3a] = 5
  check sensor.read-fifo.is-empty "Read partial frame"
  registers.bytes[0x3a] = 30
  4.repeat:
    LITTLE-ENDIAN.put-int16 registers.fifo (it * 12) -1000
    LITTLE-ENDIAN.put-int16 registers.fifo (it * 12 + 6) 1000
    LITTLE-ENDIAN.put-int16 registers.fifo (it * 12 + 10) -32768
  frames := sensor.read-fifo
  check (frames.size == 3 and registers.last-fifo-size == 48) "Unbounded FIFO batch"
  check (sensor.pending-frames == 1) "Incorrect unread FIFO frame estimate"
  check (sensor.read-fifo.size == 4) "Discarded more than first frame"
  sample/imu.Sample := frames[0]
  check ((sample.ax - 2.3928226).abs < 1e-7) "Acceleration scale"
  check ((sample.gx + 0.610865238).abs < 1e-7) "Gyro scale or signed decode"
  check (sample.az < 0 and sample.clipped) "Signed rail not reported"
  sensor.restart-fifo
  check (sensor.pending-frames == 0) "FIFO restart retained stale backlog"
  registers.bytes[0x3c] = 1
  check ((catch: sensor.read-fifo) != null) "Accepted misaligned FIFO"
  registers.bytes[0x3c] = 0
  registers.bytes[0x3b] = 0x40
  check ((catch: sensor.read-fifo) != null) "Accepted overrun"
  registers.bytes[0x3b] = 0
  registers.overrun-after-read = true
  check ((catch: sensor.read-fifo) != null) "Accepted overrun during burst"
  registers.bytes[0x0f] = 0x6a
  check ((catch: sensor.configure) != null) "Accepted different IMU model"
  registers.fail = true
  check ((catch: sensor.read-fifo) == "I2C_NACK") "Swallowed I2C error"

  test-general-api
  test-fifo-modes
  print "lsm6ds3 driver tests passed"

// Exercise public configuration against independent sensitivity/register tables.
test-general-api:
  registers := Registers
  sensor := imu.Driver registers
  check ((catch: sensor.read-now) == "LSM6DS3_NOT_CONFIGURED") "Read before configure"
  [0, 1, 2, 3].do: | range |
    sensor.configure --accel-range=range
    LITTLE-ENDIAN.put-int16 registers.bytes 0x28 1000
    expected := [0.061, 0.488, 0.122, 0.244][range] * 9.80665
    check ((sensor.read-acceleration.x - expected).abs < 1e-9) "Range-dependent acceleration conversion"
    check ((sensor.convert-acceleration 1000) == sensor.read-acceleration.x) "Raw FIFO acceleration conversion"
    check (((registers.bytes[0x10] >> 2) & 3) == range) "Acceleration range bits"
  [0, 1, 2, 4, 6].do: | range |
    sensor.configure --gyro-range=range
    LITTLE-ENDIAN.put-int16 registers.bytes 0x22 -1000
    mdps := {0: 8.75, 1: 4.375, 2: 17.5, 4: 35.0, 6: 70.0}[range]
    expected := -mdps * 3.141592653589793 / 180
    check ((sensor.read-angular-velocity.x - expected).abs < 1e-9) "Range-dependent angular velocity"
    check ((sensor.convert-angular-velocity -1000) == sensor.read-angular-velocity.x) "Raw FIFO angular velocity conversion"
    check (((registers.bytes[0x11] >> 1) & 7) == range) "Gyro range bits"
  11.repeat: | rate |
    sensor.configure --accel-rate=rate --gyro-rate=(min rate 8)
    check ((registers.bytes[0x10] >> 4) == rate and (registers.bytes[0x11] >> 4) == (min rate 8)) "Rate encoding"
  count := registers.writes.size
  check ((catch: sensor.configure --gyro-rate=9) == "INVALID_RATE") "Invalid gyro ODR"
  check ((catch: sensor.configure --gyro-range=3) == "INVALID_RANGE") "Invalid gyro range"
  check ((catch: sensor.configure --accel-power=1 --accel-rate=6) != null) "Impossible normal-mode rate"
  check (registers.writes.size == count) "Invalid configuration wrote to hardware"
  check ((catch: sensor.convert-acceleration 32768) == "INVALID_RAW_COUNT") "Invalid raw FIFO count"
  sensor.configure --accel-rate=imu.Driver.RATE-52HZ --gyro-rate=imu.Driver.RATE-52HZ
      --accel-bandwidth=imu.Driver.BANDWIDTH-50HZ
      --accel-power=imu.Driver.POWER-NORMAL
  check (sensor.accel-rate-hz == 52.0 and sensor.gyro-rate-hz == 52.0) "Actual configured rate getter"
  check (registers.bytes[0x10] == 0x3f and (registers.bytes[0x13] & 0x80) != 0 and (registers.bytes[0x15] & 16) != 0) "Bandwidth/power bits"
  registers.bytes[0x1e] = 0
  check (sensor.read-if-ready == null and sensor.read == null) "Unready fresh-data poll"
  check (sensor.read-now.acceleration != null) "Immediate snapshot incorrectly required fresh data"
  registers.bytes[0x1e] = 7
  check (sensor.status.temperature-ready and sensor.data-ready) "Status decoding"
  measurement := sensor.read-6-axis
  check (measurement.acceleration != null and measurement.angular-velocity != null) "Six-axis vector result"
  check (measurement.ax == sensor.read-3-axis.x) "Three-axis and six-axis acceleration disagree"
  check ((sensor.read-raw-angular-velocity)[0] == -1000) "Raw signed XYZ"
  LITTLE-ENDIAN.put-int16 registers.bytes 0x20 -160
  check (sensor.read-temperature == 15.0 and sensor.read-temperature-fahrenheit == 59.0) "Temperature conversion"
  registers.bytes[0x0d] = 0xc4
  sensor.configure-interrupt --pin=1 --fifo-watermark --gyroscope-ready --active-low --open-drain
  check (registers.bytes[0x0d] == 0xce and (registers.bytes[0x12] & 0x30) == 0x30) "Interrupt routing/polarity or unrelated bits"
  count = registers.writes.size
  check ((catch: sensor.configure-interrupt --pin=1 --temperature-ready) != null and registers.writes.size == count) "Invalid interrupt changed hardware"
  sensor.set-self-test --accelerometer=imu.Driver.SELF-TEST-NEGATIVE --gyroscope=imu.Driver.SELF-TEST-NEGATIVE
  check ((registers.bytes[0x14] & 15) == 14) "Negative self-test encodings"
  sensor.stop
  check ((registers.bytes[0x10] & 0xf0) == 0 and (registers.bytes[0x11] & 0xf0) == 0) "Powerdown rate bits"
  check (sensor.accel-rate-hz == 0.0 and sensor.gyro-rate-hz == 0.0) "Powerdown cached state"
  check ((catch: sensor.read-now) == "SENSORS_POWERED_DOWN") "Powered-down data presented as active"
  check ((catch: sensor.restart-fifo) == "FIFO_NOT_CONFIGURED") "Restarted FIFO with powered-down sensors"

  alternate := imu.Driver.from-registers registers
  alternate.configure
  check ((alternate.read-acceleration.x - 2.3928226).abs < 1e-8) "serial.Registers adapter"
  print "lsm6ds3 configurable ranges/rates, snapshots, temperature, interrupts and power tests passed"

test-fifo-modes:
  registers := Registers
  sensor := imu.Driver registers
  sensor.configure --gyro-rate=imu.Driver.RATE-OFF
  sensor.start-fifo --gyro-decimation=imu.Driver.FIFO-NOT-STORED --watermark-words=100 --stop-on-watermark
  check (registers.bytes[0x06] == 100 and registers.bytes[0x08] == 1 and (registers.bytes[0x13] & 1) != 0) "Accelerometer-only FIFO setup"
  registers.bytes[0x3a] = 6
  LITTLE-ENDIAN.put-int16 registers.fifo 6 1000
  frames := sensor.read-fifo
  check (frames.size == 1 and frames[0].angular-velocity == null and frames[0].acceleration != null) "Single-sensor FIFO frame"
  check ((frames[0].ax - 2.3928226).abs < 1e-8) "Accelerometer-only FIFO scale/order"
  check ((catch: frames[0].gx) == "CHANNEL_NOT_IN_FRAME") "Invented absent channel values"
  sensor.stop-fifo
  check ((catch: sensor.read-fifo) == "FIFO_NOT_RUNNING") "Stopped FIFO read"
  sensor.configure --accel-rate=imu.Driver.RATE-OFF
  sensor.start-fifo --accel-decimation=imu.Driver.FIFO-NOT-STORED
      --mode=imu.Driver.FIFO-STOP-WHEN-FULL
  registers.bytes[0x3b] = 0x20 // Full but not overrun is valid in stop-when-full mode.
  frames = sensor.read-fifo
  check (frames.size == 1 and frames[0].acceleration == null and frames[0].angular-velocity != null) "Gyroscope-only/full FIFO"
  sensor.configure --accel-rate=imu.Driver.RATE-52HZ
  sensor.start-fifo --gyro-decimation=imu.Driver.FIFO-DIV-2 --watermark-words=0xabc
  check (registers.bytes[0x06] == 0xbc and registers.bytes[0x07] == 0x0a) "12-bit watermark"
  check ((catch: sensor.read-fifo) == "FIFO_PATTERN_REQUIRES_RAW_READ") "Mixed decimation silently decoded"
  registers.bytes[0x3b] = 0
  registers.bytes[0x3c] = 3
  LITTLE-ENDIAN.put-int16 registers.fifo 0 -1234
  raw := sensor.read-fifo-raw --max-words=2
  check (raw.words == [-1234, 0] and raw.status.pattern == 3) "Raw FIFO pattern/word preservation"
  count := registers.writes.size
  check ((catch: sensor.start-fifo --watermark-words=4096) != null and registers.writes.size == count) "Invalid FIFO watermark wrote hardware"
  sensor.configure
  check ((catch: sensor.restart-fifo) == "FIFO_NOT_CONFIGURED") "Reconfigure retained incompatible FIFO decoding"
  sensor.start-fifo
  registers.fail-after = registers.writes.size + 2
  check ((catch: sensor.start-fifo --gyro-decimation=imu.Driver.FIFO-DIV-2) == "I2C_NACK") "Partial FIFO setup failure was hidden"
  registers.fail-after = null
  check ((catch: sensor.restart-fifo) == "FIFO_NOT_CONFIGURED") "Partial FIFO setup retained an incompatible saved profile"
  registers.fail-after = registers.writes.size + 3
  check ((catch: sensor.configure --accel-range=imu.Driver.ACCEL-RANGE-2G) == "I2C_NACK") "Partial configuration error was hidden"
  check ((catch: sensor.read-now) == "LSM6DS3_NOT_CONFIGURED") "Partial configuration retained stale conversion factors"
  registers.fail-after = null
  sensor.configure
  registers.short-read = true
  check ((catch: sensor.read-now) == "LSM6DS3_SHORT_READ") "Short register burst accepted"
  registers.short-read = false
  registers.fail-after = registers.writes.size + 2
  check ((catch: sensor.stop) == "I2C_NACK") "Partial power-down failure was hidden"
  check ((catch: sensor.read-now) == "LSM6DS3_NOT_CONFIGURED") "Partial power-down retained stale channel assumptions"
  print "lsm6ds3 FIFO modes, single sensors, raw patterns, watermark and reconfiguration tests passed"
