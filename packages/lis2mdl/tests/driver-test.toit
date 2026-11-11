// Checks LIS2MDL configuration, readings and error handling with a fake device.
// Run standalone or through tests/motion/drivers.test.toit.

import io.byte-order show LITTLE-ENDIAN
import lis2mdl as mag
import math

class Registers:
  bytes := ByteArray 256
  fail/bool := false
  fail-after/int? := null
  short-read/bool := false
  writes/List := []
  clear-on-read/bool := false
  single-active/bool := false
  single-polls/int := 0
  ready-after/int := 2
  constructor:
    bytes[0x4f] = 0x40
  write data/ByteArray:
    if fail or (fail-after != null and writes.size >= fail-after): throw "I2C_NACK"
    writes.add data
    if data[0] == 0x60 and (data[1] & 3) == 1:
      single-active = true
      single-polls = 0
    (data.size - 1).repeat: bytes[(data[0] & 0x7f) + it] = data[it + 1]
  read-reg reg/int size/int -> ByteArray:
    if fail: throw "I2C_NACK"
    if short-read: return ByteArray (size - 1)
    if reg == 0x67 and single-active:
      single-polls++
      if ready-after >= 0 and single-polls >= ready-after:
        bytes[0x67] |= 8
        bytes[0x60] = (bytes[0x60] & 0xfc) | 2
        single-active = false
    // LIS2MDL repeats the same register unless subaddress bit 7 is set.
    if size > 1 and reg & 0x80 == 0:
      return ByteArray size: bytes[reg]
    if size > 1: reg = reg & 0x7f
    result := bytes[reg..reg + size]
    if clear-on-read and reg == 0x68 and size == 6: bytes[0x67] = 0
    return result
  read-bytes address/int size/int -> ByteArray: return read-reg address size
  write-bytes address/int data/ByteArray: write (#[address] + data)

check condition/bool message/string:
  if not condition: throw message

main:
  registers := Registers
  compass := mag.Driver registers
  compass.reset
  check compass.reset-pending "Magnetometer reset not requested"
  check ((catch: compass.configure) != null) "Accepted pending magnetic reset"
  registers.bytes[0x60] = 0
  compass.configure
  check (registers.bytes[0x60] == 0x80 and registers.bytes[0x61] == 2 and registers.bytes[0x62] == 0x10) "Magnetic profile"
  check (compass.read == null) "Returned stale magnetic data"
  registers.bytes[0x67] = 0x88
  LITTLE-ENDIAN.put-int16 registers.bytes 0x68 -200
  LITTLE-ENDIAN.put-int16 registers.bytes 0x6a 100
  field := compass.read
  check (field.x == -30.0 and field.y == 15.0 and field.overrun) "Magnetic scaling/overrun"
  LITTLE-ENDIAN.put-int16 registers.bytes 0x6c -32768
  check compass.read.clipped "Magnetic rail not reported"
  registers.fail = true
  check ((catch: compass.read) == "I2C_NACK") "Swallowed magnetic I2C error"
  registers.fail = false
  compass.stop
  check (registers.bytes[0x60] == 0x82) "Magnetic idle mode"
  registers.bytes[0x4f] = 0
  check ((catch: compass.configure) != null) "Accepted different magnetometer"

  test-general-api
  test-single-shot
  print "lis2mdl driver tests passed"


test-general-api:
  registers := Registers
  compass := mag.Driver registers
  check ((catch: compass.read-now) == "LIS2MDL_NOT_CONFIGURED") "Read before configuration"
  4.repeat: | rate |
    compass.configure --rate=rate --mode=mag.Driver.MODE-IDLE
        --power=mag.Driver.POWER-LOW
        --filter=mag.Driver.FILTER-ODR-DIV-4
        --temperature-compensation=false
    check (registers.bytes[0x60] == ((rate << 2) | 0x12)) "Rate/power/mode bits"
    check (compass.rate-hz == [10.0, 20.0, 50.0, 100.0][rate]) "Rate readback"
    check ((registers.bytes[0x61] & 1) != 0) "Low-pass filter bit"
  count := registers.writes.size
  check ((catch: compass.configure --rate=4) == "INVALID_RATE") "Invalid rate accepted"
  check ((catch: compass.configure --mode=3) == "INVALID_MODE") "Invalid mode accepted"
  check (registers.writes.size == count) "Invalid configuration wrote registers"
  compass.configure
  registers.clear-on-read = true
  registers.bytes[0x67] = 0x88
  LITTLE-ENDIAN.put-int16 registers.bytes 0x68 -200
  LITTLE-ENDIAN.put-int16 registers.bytes 0x6a 100
  LITTLE-ENDIAN.put-int16 registers.bytes 0x6c 50
  sample := compass.read-now
  check (sample.overrun and sample.field is math.Point3f and sample.x == -30.0 and sample.y == 15.0) "Snapshot metadata/scaling order"
  check (compass.read == null) "Snapshot did not consume readiness"
  check (compass.read-3-axis.z == 7.5) "Immediate three-axis vector"
  check (compass.read-raw == [-200, 100, 50]) "Raw signed values"
  LITTLE-ENDIAN.put-int16 registers.bytes 0x6e -80
  check (compass.read-temperature == 15.0) "Temperature sensitivity"
  check (compass.read-raw-temperature == -80 and compass.read-temperature-fahrenheit == 59.0) "Raw/Fahrenheit temperature"
  offsets := math.Point3f -15.0 30.0 -7.5
  compass.write-offsets offsets
  check (registers.bytes[0x45] == 0x9c and registers.bytes[0x46] == 0xff) "Signed offset bytes/auto-increment"
  actual := compass.read-offsets
  check (actual.x == -15.0 and actual.y == 30.0 and actual.z == -7.5) "Offset round-trip"
  count = registers.writes.size
  check ((catch: compass.write-offsets (math.Point3f float.NAN 0 0)) != null and registers.writes.size == count) "Nonfinite offset wrote hardware"
  compass.configure-interrupt --threshold=30.0 --y=false --active-high=false --latched
  check (registers.bytes[0x65] == 200 and registers.bytes[0x66] == 0) "Interrupt threshold units"
  check (registers.bytes[0x63] == 0xa3 and (registers.bytes[0x62] & 0x40) != 0) "Interrupt axes/polarity/latch"
  registers.bytes[0x64] = 0x93
  check (compass.interrupt-status.active and compass.interrupt-status.x-positive and compass.interrupt-status.x-negative and compass.interrupt-status.overflow) "Interrupt status bits"
  compass.set-self-test true
  check ((registers.bytes[0x62] & 2) != 0) "Self-test enable"
  compass.set-self-test false
  check ((registers.bytes[0x62] & 2) == 0) "Self-test disable"
  compass.stop
  check ((registers.bytes[0x60] & 3) == 2) "Idle mode"
  compass.start-continuous
  check ((registers.bytes[0x60] & 3) == 0) "Continuous restart"
  alternate := mag.Driver.from-registers registers
  alternate.configure
  check (alternate.read-3-axis.x == -30.0) "serial.Registers adapter"
  check (not mag.Driver.HAS-FIFO) "Invented magnetometer FIFO"
  print "lis2mdl configurable modes/rates, snapshots, offsets, temperature and interrupt tests passed"

test-single-shot:
  registers := Registers
  compass := mag.Driver registers
  compass.configure --mode=mag.Driver.MODE-IDLE
  registers.clear-on-read = true
  registers.bytes[0x67] = 8 // A stale ready flag must be consumed before trigger.
  LITTLE-ENDIAN.put-int16 registers.bytes 0x68 100
  sample := compass.read-single
  check (sample.x == 15.0 and registers.single-polls >= 2) "Single-shot used old ready data"
  check (compass.operating-mode == mag.Driver.MODE-IDLE) "Single shot did not return to idle"
  check ((registers.bytes[0x61] & 0x10) != 0) "Single-shot offset cancellation"
  registers.ready-after = -1
  error := catch: compass.read-single --timeout=(Duration --ms=2)
  check (error == "LIS2MDL_MEASUREMENT_TIMEOUT" and compass.operating-mode == mag.Driver.MODE-IDLE) "Single-shot timeout did not idle sensor"
  compass.reboot
  check (compass.reboot-pending) "Factory reboot bit"
  check ((catch: compass.read-now) == "LIS2MDL_NOT_CONFIGURED") "Reboot retained stale configuration"
  registers.bytes[0x60] = 0
  compass.configure
  registers.fail-after = registers.writes.size + 1
  check ((catch: compass.configure --rate=mag.Driver.RATE-100HZ) == "I2C_NACK") "Partial configuration error was hidden"
  check ((catch: compass.read-now) == "LIS2MDL_NOT_CONFIGURED") "Partial configuration remained usable"
  registers.fail-after = null
  compass.configure
  registers.short-read = true
  check ((catch: compass.read-now) == "LIS2MDL_SHORT_READ") "Short read accepted"
  print "lis2mdl single-shot stale-data rejection, offset cancellation, timeout and reboot tests passed"
