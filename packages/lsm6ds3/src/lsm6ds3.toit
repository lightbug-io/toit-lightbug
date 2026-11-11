// Provides configurable LSM6DS3 accelerometer, gyroscope and FIFO access.
// Imported by the package example and applications such as the RH2 demo.

import io.byte-order show LITTLE-ENDIAN
import math

ADDRESS-LOW ::= 0x6a
ADDRESS-HIGH ::= 0x6b
GRAVITY ::= 9.80665
SAMPLE-RATE ::= 104 // Default only; use the driver's rate getters after configuration.

/** Native-axis SI measurement. Missing FIFO channels are null, never zero. */
class Sample:
  acceleration/math.Point3f? := null
  angular-velocity/math.Point3f? := null
  clipped/bool := false

  /** Decode gyro XYZ followed by acceleration XYZ. Factors convert one LSB to SI. */
  constructor bytes/ByteArray offset/int
      --accel-factor/float=(0.000244 * GRAVITY) --gyro-factor/float=(0.035 * math.PI / 180)
      --accelerometer/bool=true --gyroscope/bool=true:
    words := (accelerometer ? 3 : 0) + (gyroscope ? 3 : 0)
    if words == 0 or offset < 0 or offset + words * 2 > bytes.size: throw "INVALID_FRAME"
    if gyroscope:
      angular-velocity = vector_ bytes offset gyro-factor
      offset += 6
    if accelerometer: acceleration = vector_ bytes offset accel-factor
    start := offset - (gyroscope ? 6 : 0)
    words.repeat:
      if (LITTLE-ENDIAN.int16 bytes (start + 2 * it)).abs >= 32_760: clipped = true

  ax -> float: return (require-vector_ acceleration).x
  ay -> float: return (require-vector_ acceleration).y
  az -> float: return (require-vector_ acceleration).z
  gx -> float: return (require-vector_ angular-velocity).x
  gy -> float: return (require-vector_ angular-velocity).y
  gz -> float: return (require-vector_ angular-velocity).z

/** Output-register readiness snapshot. Reading data consumes its ready flag. */
class Status:
  raw/int
  constructor .raw:
  acceleration-ready -> bool: return (raw & 1) != 0
  gyroscope-ready -> bool: return (raw & 2) != 0
  temperature-ready -> bool: return (raw & 4) != 0

/** FIFO sizes and pattern are in 16-bit words, not bytes or six-axis frames. */
class FifoStatus:
  words/int
  pattern/int
  flags/int
  constructor bytes/ByteArray:
    if bytes.size != 4: throw "LSM6DS3_SHORT_READ"
    words = bytes[0] | ((bytes[1] & 15) << 8)
    pattern = bytes[2] | ((bytes[3] & 3) << 8)
    flags = bytes[1]
  watermark -> bool: return (flags & 0x80) != 0
  overrun -> bool: return (flags & 0x40) != 0
  full -> bool: return (flags & 0x20) != 0
  empty -> bool: return (flags & 0x10) != 0

/** Raw FIFO words together with the pattern at the start of the read. */
class FifoChunk:
  status/FifoStatus
  words/List
  constructor .status bytes/ByteArray:
    words = List (bytes.size / 2): LITTLE-ENDIAN.int16 bytes (it * 2)

/**
LSM6DS3 / LSM6DS3TR (identity 0x69). Other family members are not interchangeable.

The caller owns transport, locking and settling time. No tasks or bus closing
occur here. Methods propagate transport errors and reject short reads.
*/
class Driver:
  static HAS-FIFO ::= true
  static RATE-OFF ::= 0
  static RATE-12-5HZ ::= 1
  static RATE-26HZ ::= 2
  static RATE-52HZ ::= 3
  static RATE-104HZ ::= 4
  static RATE-208HZ ::= 5
  static RATE-416HZ ::= 6
  static RATE-833HZ ::= 7
  static RATE-1660HZ ::= 8
  static RATE-3330HZ ::= 9 // Accelerometer/FIFO only.
  static RATE-6660HZ ::= 10 // Accelerometer/FIFO only.
  static ACCEL-RANGE-2G ::= 0
  static ACCEL-RANGE-16G ::= 1
  static ACCEL-RANGE-4G ::= 2
  static ACCEL-RANGE-8G ::= 3
  static GYRO-RANGE-245DPS ::= 0
  static GYRO-RANGE-125DPS ::= 1
  static GYRO-RANGE-500DPS ::= 2
  static GYRO-RANGE-1000DPS ::= 4
  static GYRO-RANGE-2000DPS ::= 6
  static BANDWIDTH-400HZ ::= 0
  static BANDWIDTH-200HZ ::= 1
  static BANDWIDTH-100HZ ::= 2
  static BANDWIDTH-50HZ ::= 3
  static POWER-HIGH-PERFORMANCE ::= 0
  static POWER-NORMAL ::= 1
  static FIFO-STOP-WHEN-FULL ::= 1
  static FIFO-CONTINUOUS-TO-FIFO ::= 3
  static FIFO-BYPASS-TO-CONTINUOUS ::= 4
  static FIFO-CONTINUOUS ::= 6
  static FIFO-NOT-STORED ::= 0 // Per-sensor decimator, not an operating mode.
  static FIFO-NO-DECIMATION ::= 1
  static FIFO-DIV-2 ::= 2
  static FIFO-DIV-3 ::= 3
  static FIFO-DIV-4 ::= 4
  static FIFO-DIV-8 ::= 5
  static FIFO-DIV-16 ::= 6
  static FIFO-DIV-32 ::= 7
  static SELF-TEST-OFF ::= 0
  static SELF-TEST-POSITIVE ::= 1
  static SELF-TEST-NEGATIVE ::= -1
  static SENSOR-ACCELEROMETER ::= 0
  static SENSOR-GYROSCOPE ::= 1

  // Sensor register map; masks below are fields within these registers.
  static WHO-AM-I_ ::= 0x0f
  static CTRL3-C_ ::= 0x12
  static STATUS-REG_ ::= 0x1e
  static FIFO-STATUS1_ ::= 0x3a
  static CTRL1-XL_ ::= 0x10
  static CTRL2-G_ ::= 0x11
  static CTRL4-C_ ::= 0x13
  static CTRL5-C_ ::= 0x14
  static CTRL6-C_ ::= 0x15
  static CTRL7-G_ ::= 0x16
  static CTRL9-XL_ ::= 0x18
  static CTRL10-C_ ::= 0x19
  static OUTX-L-G_ ::= 0x22
  static OUTX-L-XL_ ::= 0x28
  static OUT-TEMP-L_ ::= 0x20
  static FIFO-CTRL1_ ::= 0x06
  static FIFO-CTRL2_ ::= 0x07
  static FIFO-CTRL3_ ::= 0x08
  static FIFO-CTRL4_ ::= 0x09
  static FIFO-CTRL5_ ::= 0x0a
  static INT1-CTRL_ ::= 0x0d
  static INT2-CTRL_ ::= 0x0e
  static FIFO-DATA-OUT-L_ ::= 0x3e
  static FIFO-STATUS2_ ::= 0x3b

  device_/any
  configured_/bool := false
  accel-rate_/int := RATE-OFF
  gyro-rate_/int := RATE-OFF
  accel-range_/int := ACCEL-RANGE-8G
  gyro-range_/int := GYRO-RANGE-1000DPS
  accel-factor_/float := 0.000244 * GRAVITY
  gyro-factor_/float := 0.035 * math.PI / 180
  fifo-control_/int := 0
  fifo-accel_/int := 1
  fifo-gyro_/int := 1
  fifo-decoded_/bool := false
  fifo-running_/bool := false
  discard-first_/bool := true
  pending-frames/int := 0
  constructor .device_:
  /** Accept a serial.Registers-style object with read-bytes/write-bytes. */
  constructor.from-registers registers:
    device_ = RegisterTransport_ registers

  identity -> int: return (read-register WHO-AM-I_)[0]
  reset-pending -> bool: return ((read-register CTRL3-C_)[0] & 1) != 0
  accel-rate-hz -> float: return rate-hz_ accel-rate_
  gyro-rate-hz -> float: return rate-hz_ gyro-rate_
  accel-range -> int: return accel-range_
  gyro-range -> int: return gyro-range_
  status -> Status: return Status (read-register STATUS-REG_)[0]
  data-ready -> bool:
    state := status
    return (accel-rate_ == 0 or state.acceleration-ready) and (gyro-rate_ == 0 or state.gyroscope-ready) and
        (accel-rate_ != 0 or gyro-rate_ != 0)
  fifo-status -> FifoStatus: return FifoStatus (read-register FIFO-STATUS1_ --size=4)

  /** Request software reset; poll reset-pending with a bounded timeout. */
  reset:
    check-identity_
    configured_ = false
    fifo-control_ = 0
    fifo-running_ = false
    pending-frames = 0
    write-register CTRL3-C_ #[1]

  /**
  Configure sensors without starting FIFO. Rate/range/power/bandwidth values are
  the named Driver constants above. Gyro rates stop at RATE-1660HZ. Null accel
  bandwidth selects the ODR-dependent default; explicit values select 400/200/100/50 Hz.
  BDU and little-endian auto-increment are always enabled. Reconfiguration clears
  the FIFO and changes conversion factors; break downstream timelines accordingly.
  */
  configure --accel-rate/int=RATE-104HZ --gyro-rate/int=RATE-104HZ
      --accel-range/int=ACCEL-RANGE-8G --gyro-range/int=GYRO-RANGE-1000DPS
      --accel-power/int=POWER-HIGH-PERFORMANCE --gyro-power/int=POWER-HIGH-PERFORMANCE
      --accel-bandwidth/int?=null:
    if not 0 <= accel-rate <= 10 or not 0 <= gyro-rate <= 8: throw "INVALID_RATE"
    if not 0 <= accel-range <= 3 or not [0, 1, 2, 4, 6].contains gyro-range: throw "INVALID_RANGE"
    if not 0 <= accel-power <= 1 or not 0 <= gyro-power <= 1: throw "INVALID_POWER_MODE"
    if accel-power == POWER-NORMAL and accel-rate > RATE-208HZ: throw "INVALID_ACCEL_NORMAL_RATE"
    if gyro-power == POWER-NORMAL and gyro-rate > RATE-208HZ: throw "INVALID_GYRO_NORMAL_RATE"
    if accel-bandwidth != null and not 0 <= accel-bandwidth <= 3: throw "INVALID_BANDWIDTH"
    check-identity_
    if reset-pending: throw "LSM6DS3_RESET_PENDING"
    configured_ = false
    fifo-control_ = 0
    fifo-decoded_ = false
    stop-fifo
    update-register CTRL3-C_ 0x46 0x44
    write-register CTRL1-XL_ #[((accel-rate << 4) | (accel-range << 2) | (accel-bandwidth == null ? 0 : accel-bandwidth))]
    write-register CTRL2-G_ #[((gyro-rate << 4) | (gyro-range << 1))]
    update-register CTRL4-C_ 0x80 (accel-bandwidth == null ? 0 : 0x80)
    update-register CTRL5-C_ 0xef 0 // Disable output rounding and self-test stimulus.
    update-register CTRL6-C_ 0x10 (accel-power << 4)
    update-register CTRL7-G_ 0x80 (gyro-power << 7)
    update-register CTRL9-XL_ 0x38 0x38
    update-register CTRL10-C_ 0x38 0x38
    accel-rate_ = accel-rate
    gyro-rate_ = gyro-rate
    accel-range_ = accel-range
    gyro-range_ = gyro-range
    accel-factor_ = [0.061, 0.488, 0.122, 0.244][accel-range] * (GRAVITY / 1000)
    gyro-factor_ = {0: 8.75, 1: 4.375, 2: 17.5, 4: 35.0, 6: 70.0}[gyro-range] * (math.PI / 180_000)
    configured_ = true

  /** Immediate output-register snapshot, even if the ready flags are clear. */
  read-now -> Sample:
    require-configured_
    if accel-rate_ != 0 and gyro-rate_ != 0:
      return decode_ (read-register OUTX-L-G_ --size=12) 0 true true
    if accel-rate_ != 0: return decode_ (read-register OUTX-L-XL_ --size=6) 0 true false
    if gyro-rate_ != 0: return decode_ (read-register OUTX-L-G_ --size=6) 0 false true
    throw "SENSORS_POWERED_DOWN"
  /** Fresh-data alias, consistent with the LIS2MDL driver. */
  read -> Sample?: return read-if-ready
  read-6-axis -> Sample:
    require-configured_
    if accel-rate_ == 0 or gyro-rate_ == 0: throw "SIX_AXIS_REQUIRES_BOTH_SENSORS"
    return read-now

  /** Polling convenience; never waits for the next conversion. */
  read-if-ready -> Sample?:
    require-configured_
    return data-ready ? read-now : null

  /** Read one sensor's XYZ vector now, in m/s² or rad/s. */
  read-3-axis --sensor/int=SENSOR-ACCELEROMETER -> math.Point3f:
    if sensor == SENSOR-ACCELEROMETER: return read-acceleration
    if sensor == SENSOR-GYROSCOPE: return read-angular-velocity
    throw "INVALID_SENSOR"
  read-acceleration -> math.Point3f:
    require-configured_
    if accel-rate_ == 0: throw "ACCELEROMETER_POWERED_DOWN"
    return vector_ (read-register OUTX-L-XL_ --size=6) 0 accel-factor_
  read-angular-velocity -> math.Point3f:
    require-configured_
    if gyro-rate_ == 0: throw "GYROSCOPE_POWERED_DOWN"
    return vector_ (read-register OUTX-L-G_ --size=6) 0 gyro-factor_
  read-raw-acceleration -> List: return raw-vector_ (read-register OUTX-L-XL_ --size=6)
  read-raw-angular-velocity -> List: return raw-vector_ (read-register OUTX-L-G_ --size=6)
  /** Scale a raw output/FIFO count using the current range, without bus I/O. */
  convert-acceleration raw/int -> float:
    require-configured_
    if not -32768 <= raw <= 32767: throw "INVALID_RAW_COUNT"
    return raw * accel-factor_
  /** Scale a raw output/FIFO count to rad/s using the current gyro range. */
  convert-angular-velocity raw/int -> float:
    require-configured_
    if not -32768 <= raw <= 32767: throw "INVALID_RAW_COUNT"
    return raw * gyro-factor_
  read-raw-temperature -> int: return LITTLE-ENDIAN.int16 (read-register OUT-TEMP-L_ --size=2) 0
  read-temperature -> float: return 25.0 + read-raw-temperature / 16.0
  read-temperature-fahrenheit -> float: return read-temperature * 1.8 + 32.0

  /**
  Start FIFO with explicit mode, rate, watermark (16-bit words) and decimators.
  RATE-OFF is invalid. Triggered modes require separate application trigger setup.
  Decoded reads support one/both sensors at FIFO rate without decimation; arbitrary
  rate/decimation patterns remain available through read-fifo-raw.
  */
  start-fifo --mode/int=FIFO-CONTINUOUS --rate/int?=null --watermark-words/int=0
      --accel-decimation/int=FIFO-NO-DECIMATION --gyro-decimation/int=FIFO-NO-DECIMATION
      --stop-on-watermark/bool=false:
    require-configured_
    actual-rate := rate == null ? (max accel-rate_ gyro-rate_) : rate
    if not [1, 3, 4, 6].contains mode: throw "INVALID_FIFO_MODE"
    if not 1 <= actual-rate <= 10: throw "INVALID_FIFO_RATE"
    if stop-on-watermark and watermark-words == 0: throw "WATERMARK_REQUIRED"
    if not 0 <= watermark-words <= 4095: throw "INVALID_WATERMARK"
    if not 0 <= accel-decimation <= 7 or not 0 <= gyro-decimation <= 7: throw "INVALID_DECIMATION"
    if accel-decimation == 0 and gyro-decimation == 0: throw "FIFO_REQUIRES_A_SENSOR"
    if (accel-decimation != 0 and accel-rate_ == 0) or (gyro-decimation != 0 and gyro-rate_ == 0): throw "FIFO_SENSOR_POWERED_DOWN"
    // A partially written profile must never be restarted with the old decoder.
    fifo-control_ = 0
    fifo-decoded_ = false
    stop-fifo
    write-register FIFO-CTRL1_ #[(watermark-words & 0xff)]
    update-register FIFO-CTRL2_ 0xff (watermark-words >> 8) // No temperature/pedometer data sets.
    write-register FIFO-CTRL3_ #[(accel-decimation | (gyro-decimation << 3))]
    write-register FIFO-CTRL4_ #[0]
    update-register CTRL4-C_ 0x11 (stop-on-watermark ? 1 : 0) // Exclude temperature from the decoded pattern.
    fifo-control_ = (actual-rate << 3) | mode
    fifo-accel_ = accel-decimation
    fifo-gyro_ = gyro-decimation
    fifo-decoded_ = (accel-decimation == 0 or (accel-rate_ == actual-rate and accel-decimation == 1)) and
        (gyro-decimation == 0 or (gyro-rate_ == actual-rate and gyro-decimation == 1))
    restart-fifo

  /** Clear and restart using the last start-fifo profile. Break your timeline. */
  restart-fifo:
    require-configured_
    if fifo-control_ == 0: throw "FIFO_NOT_CONFIGURED"
    fifo-running_ = false
    write-register FIFO-CTRL5_ #[0]
    write-register FIFO-CTRL5_ #[fifo-control_]
    fifo-running_ = true
    discard-first_ = true
    pending-frames = 0

  stop-fifo:
    fifo-running_ = false
    pending-frames = 0
    write-register FIFO-CTRL5_ #[0]

  /** Bounded decoded frames. The first frame after a mode change is discarded. */
  read-fifo --max-frames/int=4 -> List:
    if not 1 <= max-frames <= 16: throw "INVALID_BATCH_SIZE"
    if not fifo-running_: throw "FIFO_NOT_RUNNING"
    if not fifo-decoded_: throw "FIFO_PATTERN_REQUIRES_RAW_READ"
    state := fifo-status
    if state.overrun: throw "LSM6DS3_FIFO_OVERRUN"
    if state.pattern != 0: throw "LSM6DS3_FIFO_ALIGNMENT"
    words-per-frame := (fifo-accel_ == 0 ? 0 : 3) + (fifo-gyro_ == 0 ? 0 : 3)
    count := min max-frames (state.words / words-per-frame)
    pending-frames = state.words / words-per-frame - count
    if count == 0: return []
    bytes := fifo-bytes_ (count * words-per-frame)
    first := discard-first_ ? 1 : 0
    discard-first_ = false
    return List (count - first): decode_ bytes ((it + first) * words-per-frame * 2) (fifo-accel_ != 0) (fifo-gyro_ != 0)

  /** Raw signed words and their starting pattern, for arbitrary decimation. */
  read-fifo-raw --max-words/int=32 -> FifoChunk:
    if not 1 <= max-words <= 256: throw "INVALID_BATCH_SIZE"
    if not fifo-running_: throw "FIFO_NOT_RUNNING"
    state := fifo-status
    if state.overrun: throw "LSM6DS3_FIFO_OVERRUN"
    pending-frames = 0
    return FifoChunk state (fifo-bytes_ (min max-words state.words))

  /** Route data-ready / FIFO events; no GPIO or host ISR is installed. */
  configure-interrupt --pin/int=1 --acceleration-ready/bool=false --gyroscope-ready/bool=false
      --temperature-ready/bool=false --fifo-watermark/bool=false --fifo-overrun/bool=false
      --fifo-full/bool=false --active-low/bool=false --open-drain/bool=false:
    if not 1 <= pin <= 2 or (pin == 1 and temperature-ready): throw "INVALID_INTERRUPT_PIN"
    bits := (acceleration-ready ? 1 : 0) | (gyroscope-ready ? 2 : 0) | (temperature-ready ? 4 : 0) |
        (fifo-watermark ? 8 : 0) | (fifo-overrun ? 16 : 0) | (fifo-full ? 32 : 0)
    update-register (pin == 1 ? INT1-CTRL_ : INT2-CTRL_) (pin == 1 ? 0x3b : 0x3f) bits
    update-register CTRL3-C_ 0x30 ((active-low ? 0x20 : 0) | (open-drain ? 0x10 : 0))

  /** Enable hardware stimulus only; baseline, settling and pass/fail are caller-owned. */
  set-self-test --accelerometer/int=SELF-TEST-OFF --gyroscope/int=SELF-TEST-OFF:
    if not [0, 1, -1].contains accelerometer or not [0, 1, -1].contains gyroscope: throw "INVALID_SELF_TEST"
    a := accelerometer == -1 ? 2 : accelerometer
    g := gyroscope == -1 ? 3 : gyroscope
    update-register CTRL5-C_ 15 (a | (g << 2))

  /** Stop both channels without releasing the transport or altering their ranges. */
  stop:
    was-configured := configured_
    configured_ = false // A failed power-down may leave only one channel running.
    fifo-control_ = 0
    fifo-decoded_ = false
    stop-fifo
    update-register CTRL1-XL_ 0xf0 0
    update-register CTRL2-G_ 0xf0 0
    accel-rate_ = 0
    gyro-rate_ = 0
    configured_ = was-configured

  /** Low-level escape hatch. Writes can invalidate high-level scaling/FIFO assumptions. */
  read-register address/int --size/int=1 -> ByteArray:
    if not 0 <= address <= 0x7f or not 1 <= size <= 512: throw "INVALID_REGISTER_READ"
    bytes := device_.read-reg address size
    if bytes.size != size: throw "LSM6DS3_SHORT_READ"
    return bytes
  write-register address/int data/ByteArray:
    if not 0 <= address <= 0x7f or data.is-empty or data.size > 255: throw "INVALID_REGISTER_WRITE"
    device_.write (#[address] + data)
  update-register address/int mask/int value/int:
    if not 0 <= mask <= 255 or not 0 <= value <= 255: throw "INVALID_REGISTER_VALUE"
    old := (read-register address)[0]
    write-register address #[((old & (0xff ^ mask)) | (value & mask))]

  require-configured_:
    if not configured_: throw "LSM6DS3_NOT_CONFIGURED"
  check-identity_:
    if identity != 0x69: throw "LSM6DS3_ID_MISMATCH"
  fifo-bytes_ words/int -> ByteArray:
    if words == 0: return #[]
    bytes := read-register FIFO-DATA-OUT-L_ --size=(words * 2)
    if ((read-register FIFO-STATUS2_)[0] & 0x40) != 0: throw "LSM6DS3_FIFO_OVERRUN"
    return bytes
  decode_ bytes/ByteArray offset/int accelerometer/bool gyroscope/bool -> Sample:
    return Sample bytes offset --accel-factor=accel-factor_ --gyro-factor=gyro-factor_ --accelerometer=accelerometer --gyroscope=gyroscope

rate-hz_ rate/int -> float:
  return [0.0, 12.5, 26.0, 52.0, 104.0, 208.0, 416.0, 833.0, 1660.0, 3330.0, 6660.0][rate]
vector_ bytes/ByteArray offset/int factor/float -> math.Point3f:
  return math.Point3f ((LITTLE-ENDIAN.int16 bytes offset) * factor) ((LITTLE-ENDIAN.int16 bytes (offset + 2)) * factor) ((LITTLE-ENDIAN.int16 bytes (offset + 4)) * factor)
raw-vector_ bytes/ByteArray -> List:
  return List 3: LITTLE-ENDIAN.int16 bytes (it * 2)
require-vector_ value/math.Point3f? -> math.Point3f:
  if value == null: throw "CHANNEL_NOT_IN_FRAME"
  return value

// Adapter keeps the package independent of any particular serial transport package.
class RegisterTransport_:
  registers_/any
  constructor .registers_:
  read-reg address/int size/int -> ByteArray: return registers_.read-bytes address size
  write bytes/ByteArray: registers_.write-bytes bytes[0] bytes[1..]
