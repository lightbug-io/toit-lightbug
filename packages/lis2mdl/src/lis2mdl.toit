// Provides configurable LIS2MDL magnetic field acquisition and controls.
// Imported by the package example and applications such as the RH2 demo.

import io.byte-order show LITTLE-ENDIAN
import math

ADDRESS ::= 0x1e
MICROTESLA-PER-LSB ::= 0.15

/** Native left-handed sensor axes; field is in microtesla. */
class Sample:
  field/math.Point3f
  overrun/bool
  clipped/bool := false
  constructor bytes/ByteArray .overrun:
    if bytes.size != 6: throw "LIS2MDL_SHORT_READ"
    field = math.Point3f
        ((LITTLE-ENDIAN.int16 bytes 0) * MICROTESLA-PER-LSB)
        ((LITTLE-ENDIAN.int16 bytes 2) * MICROTESLA-PER-LSB)
        ((LITTLE-ENDIAN.int16 bytes 4) * MICROTESLA-PER-LSB)
    3.repeat:
      if (LITTLE-ENDIAN.int16 bytes (2 * it)).abs >= 32_760: clipped = true
  x -> float: return field.x
  y -> float: return field.y
  z -> float: return field.z

class Status:
  raw/int
  constructor .raw:
  data-ready -> bool: return (raw & 8) != 0
  overrun -> bool: return (raw & 0x80) != 0
  x-ready -> bool: return (raw & 1) != 0
  y-ready -> bool: return (raw & 2) != 0
  z-ready -> bool: return (raw & 4) != 0

/** Reading the hardware source register also acknowledges latched interrupts. */
class InterruptStatus:
  raw/int
  constructor .raw:
  active -> bool: return (raw & 1) != 0
  overflow -> bool: return (raw & 2) != 0
  x-positive -> bool: return (raw & 0x80) != 0
  y-positive -> bool: return (raw & 0x40) != 0
  z-positive -> bool: return (raw & 0x20) != 0
  x-negative -> bool: return (raw & 0x10) != 0
  y-negative -> bool: return (raw & 8) != 0
  z-negative -> bool: return (raw & 4) != 0

/**
LIS2MDL magnetic sensor. There is no hardware FIFO and no programmable full-scale
range: sensitivity is always 0.15 uT/LSB. The caller owns transport and locking.
Calibration/axis mapping belong above this driver; no board-specific flips occur.
*/
class Driver:
  static HAS-FIFO ::= false
  static RATE-10HZ ::= 0
  static RATE-20HZ ::= 1
  static RATE-50HZ ::= 2
  static RATE-100HZ ::= 3
  static MODE-CONTINUOUS ::= 0
  static MODE-SINGLE ::= 1
  static MODE-IDLE ::= 2
  static POWER-HIGH-RESOLUTION ::= 0
  static POWER-LOW ::= 1
  static FILTER-ODR-DIV-2 ::= 0
  static FILTER-ODR-DIV-4 ::= 1
  static SET-RESET-EVERY-63 ::= 0
  static SET-RESET-OFFSET-CANCELLATION ::= 1
  static SET-RESET-POWER-ON-ONLY ::= 2

  // Sensor register map; masks below are fields within these registers.
  static WHO-AM-I_ ::= 0x4f
  static CFG-REG-A_ ::= 0x60
  static CFG-REG-B_ ::= 0x61
  static CFG-REG-C_ ::= 0x62
  static STATUS-REG_ ::= 0x67
  static INT-SOURCE-REG_ ::= 0x64
  static OUTX-L-REG_ ::= 0x68
  static TEMP-OUT-L-REG_ ::= 0x6e
  static OFFSET-X-REG-L_ ::= 0x45
  static INT-THS-L-REG_ ::= 0x65
  static INT-CTRL-REG_ ::= 0x63

  device_/any
  configured_/bool := false
  constructor .device_:
  /** Accept a serial.Registers-style object with read-bytes/write-bytes. */
  constructor.from-registers registers:
    device_ = RegisterTransport_ registers

  identity -> int: return (read-register WHO-AM-I_)[0]
  reset-pending -> bool: return ((read-register CFG-REG-A_)[0] & 0x20) != 0
  reboot-pending -> bool: return ((read-register CFG-REG-A_)[0] & 0x40) != 0
  status -> Status: return Status (read-register STATUS-REG_)[0]
  data-ready -> bool: return status.data-ready
  operating-mode -> int: return (read-register CFG-REG-A_)[0] & 3
  rate-hz -> float: return [10.0, 20.0, 50.0, 100.0][((read-register CFG-REG-A_)[0] >> 2) & 3]
  interrupt-status -> InterruptStatus: return InterruptStatus (read-register INT-SOURCE-REG_)[0]

  /** Request reset; caller polls reset-pending with a bounded timeout. */
  reset:
    check-identity_
    configured_ = false
    write-register CFG-REG-A_ #[0x20]

  /** Reload factory calibration; wait for reboot-pending to clear, then configure. */
  reboot:
    check-identity_
    configured_ = false
    update-register CFG-REG-A_ 0x40 0x40

  /**
  Configure using named RATE-*, MODE-*, POWER-*, FILTER-* and SET-RESET-* values.
  Single mode triggers one measurement; idle waits for trigger or start-continuous.
  Temperature compensation and offset cancellation are enabled by default.
  BDU/little-endian output are enforced; GPIO interrupts remain caller-managed.
  */
  configure --rate/int=RATE-10HZ --mode/int=MODE-CONTINUOUS
      --power/int=POWER-HIGH-RESOLUTION --filter/int=FILTER-ODR-DIV-2
      --temperature-compensation/bool=true --set-reset/int=SET-RESET-OFFSET-CANCELLATION
      --data-ready-pin/bool=false:
    if not 0 <= rate <= 3: throw "INVALID_RATE"
    if not 0 <= mode <= 2: throw "INVALID_MODE"
    if not 0 <= power <= 1 or not 0 <= filter <= 1 or not 0 <= set-reset <= 2: throw "INVALID_CONFIGURATION"
    check-identity_
    if reset-pending or reboot-pending: throw "LIS2MDL_RESET_PENDING"
    configured_ = false
    update-register CFG-REG-C_ 0x3b (0x10 | (data-ready-pin ? 1 : 0))
    one-shot-cancel := mode == MODE-SINGLE and set-reset == SET-RESET-OFFSET-CANCELLATION
    update-register CFG-REG-B_ 0x17 (filter | (set-reset << 1) | (one-shot-cancel ? 0x10 : 0))
    write-register CFG-REG-A_ #[(mode | (rate << 2) | (power << 4) | (temperature-compensation ? 0x80 : 0))]
    configured_ = true

  /** Latest XYZ snapshot regardless of ready flags. This method never waits. */
  read-now -> Sample:
    require-configured_
    state := status
    return Sample (read-register OUTX-L-REG_ --size=6) state.overrun

  /** Immediate XYZ field vector, in microtesla. */
  read-3-axis -> math.Point3f: return read-now.field
  read-raw -> List:
    bytes := read-register OUTX-L-REG_ --size=6
    return List 3: LITTLE-ENDIAN.int16 bytes (2 * it)

  /** Fresh-data poll: null until all three axes have new data; no waiting. */
  read -> Sample?: return read-if-ready
  read-if-ready -> Sample?:
    require-configured_
    state := status
    if not state.data-ready: return null
    return Sample (read-register OUTX-L-REG_ --size=6) state.overrun

  read-raw-temperature -> int: return LITTLE-ENDIAN.int16 (read-register TEMP-OUT-L-REG_ --size=2) 0
  read-temperature -> float: return 25.0 + read-raw-temperature / 8.0
  read-temperature-fahrenheit -> float: return read-temperature * 1.8 + 32.0

  /** Start continuous measurements, retaining configured rate, power and filter. */
  start-continuous:
    require-configured_
    update-register CFG-REG-B_ 0x10 0
    update-register CFG-REG-A_ 3 MODE-CONTINUOUS

  /**
  Trigger a fresh single measurement without waiting. Enters idle and clears old
  output first so data-ready belongs to the new conversion. Poll readiness later.
  */
  trigger:
    require-configured_
    stop
    read-register OUTX-L-REG_ --size=6
    cancellation := ((read-register CFG-REG-B_)[0] & 6) == 2
    update-register CFG-REG-B_ 0x10 (cancellation ? 0x10 : 0)
    update-register CFG-REG-A_ 3 MODE-SINGLE

  /**
  Blocking single-shot convenience for an exclusively owned bus. On a shared bus
  use trigger, data-ready and read-if-ready as separately locked transactions.
  Does not install a task or hold any driver lock. Timeout leaves the sensor idle.
  */
  read-single --timeout/Duration=(Duration --ms=500) -> Sample:
    if timeout.in-ms <= 0: throw "INVALID_TIMEOUT"
    trigger
    deadline := Time.monotonic-us + timeout.in-us
    while true:
      value := read-if-ready
      if value != null: return value
      if Time.monotonic-us >= deadline:
        stop
        throw "LIS2MDL_MEASUREMENT_TIMEOUT"
      sleep --ms=2

  /** Enter idle, retaining rate/filter/temperature settings. Does not close bus. */
  stop: update-register CFG-REG-A_ 3 MODE-IDLE

  /** Hardware user offsets in native-axis microtesla, quantized to 0.15 uT. */
  write-offsets offsets/math.Point3f:
    values := [offsets.x, offsets.y, offsets.z]
    counts := values.map:
      if not it.is-finite: throw "INVALID_MAGNETIC_OFFSET"
      value := (it / MICROTESLA-PER-LSB).round.to-int
      if not -32768 <= value <= 32767: throw "INVALID_MAGNETIC_OFFSET"
      value
    bytes := ByteArray 6
    3.repeat: LITTLE-ENDIAN.put-int16 bytes (2 * it) counts[it]
    write-register OFFSET-X-REG-L_ bytes
  read-offsets -> math.Point3f:
    bytes := read-register OFFSET-X-REG-L_ --size=6
    return math.Point3f ((LITTLE-ENDIAN.int16 bytes 0) * MICROTESLA-PER-LSB) ((LITTLE-ENDIAN.int16 bytes 2) * MICROTESLA-PER-LSB) ((LITTLE-ENDIAN.int16 bytes 4) * MICROTESLA-PER-LSB)

  /** Hardware stimulus toggle only; the caller owns settling and pass/fail checks. */
  set-self-test enabled/bool: update-register CFG-REG-C_ 2 (enabled ? 2 : 0)

  /**
  Native-axis threshold event; threshold is microtesla (0..4915.05), rounded to LSB.
  Configures the sensor pin, not an ESP/host ISR. Source reads clear latched events.
  */
  configure-interrupt --threshold/float --x/bool=true --y/bool=true --z/bool=true
      --active-high/bool=true --latched/bool=true --enabled/bool=true:
    if not threshold.is-finite or not 0 <= threshold <= 32767 * MICROTESLA-PER-LSB: throw "INVALID_THRESHOLD"
    counts := (threshold / MICROTESLA-PER-LSB).round.to-int
    bytes := ByteArray 2
    LITTLE-ENDIAN.put-uint16 bytes 0 counts
    write-register INT-THS-L-REG_ bytes
    bits := (x ? 0x80 : 0) | (y ? 0x40 : 0) | (z ? 0x20 : 0) | (active-high ? 4 : 0) | (latched ? 2 : 0) | (enabled ? 1 : 0)
    write-register INT-CTRL-REG_ #[bits]
    update-register CFG-REG-C_ 0x40 (enabled ? 0x40 : 0)

  /** I2C raw-register escape hatch; multi-byte transfers use auto-increment. */
  read-register address/int --size/int=1 -> ByteArray:
    if not 0 <= address <= 0x7f or not 1 <= size <= 128: throw "INVALID_REGISTER_READ"
    bytes := device_.read-reg (size > 1 ? address | 0x80 : address) size
    if bytes.size != size: throw "LIS2MDL_SHORT_READ"
    return bytes
  write-register address/int data/ByteArray:
    if not 0 <= address <= 0x7f or data.is-empty or data.size > 128: throw "INVALID_REGISTER_WRITE"
    device_.write (#[(data.size > 1 ? address | 0x80 : address)] + data)
  update-register address/int mask/int value/int:
    if not 0 <= mask <= 255 or not 0 <= value <= 255: throw "INVALID_REGISTER_VALUE"
    old := (read-register address)[0]
    write-register address #[((old & (0xff ^ mask)) | (value & mask))]
  check-identity_:
    if identity != 0x40: throw "LIS2MDL_ID_MISMATCH"
  require-configured_:
    if not configured_: throw "LIS2MDL_NOT_CONFIGURED"

class RegisterTransport_:
  registers_/any
  constructor .registers_:
  read-reg address/int size/int -> ByteArray: return registers_.read-bytes address size
  write bytes/ByteArray: registers_.write-bytes bytes[0] bytes[1..]
