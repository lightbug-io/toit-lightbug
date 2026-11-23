// Tests magnetometer polling and corrections during acquisition.
// Run as part of the RH2 motion host test suite.

import io.byte-order show LITTLE-ENDIAN
import lsm6ds3 as imu
import lis2mdl as mag
import motion-fusion show Vector3
import ...examples.motion.acquisition show Sampler
import ...examples.motion.calibration show Correction

class Device:
  with-i2c [action]: return action.call

class IMURegisters:
  words/int := 24
  write bytes/ByteArray:
  read-reg address/int size/int -> ByteArray:
    if address == 0x0f: return #[0x69]
    if address == 0x3a: return #[words, 0, 0, 0]
    if address == 0x3b: return #[0]
    return ByteArray size

class MagneticRegisters:
  reads/int := 0
  overrun/bool := false
  write bytes/ByteArray:
  read-reg address/int size/int -> ByteArray:
    if address == 0x67: return overrun ? #[0x88] : #[0x08]
    if address == 0x4f: return #[0x40]
    if address == 0x60 or address == 0x61 or address == 0x62: return ByteArray size
    if address != 0xe8 or size != 6: throw "Missing LIS2MDL auto-increment"
    reads++
    bytes := ByteArray 6
    LITTLE-ENDIAN.put-int16 bytes 0 400
    LITTLE-ENDIAN.put-int16 bytes 2 -200
    LITTLE-ENDIAN.put-int16 bytes 4 100
    return bytes

main:
  registers := MagneticRegisters
  imu-registers := IMURegisters
  correction := Correction (Vector3 15 -5 0) (Vector3 1 1.2 0.8) 45.0
  sensor := imu.Driver imu-registers
  sensor.configure
  sensor.start-fifo
  magnetometer := mag.Driver registers
  magnetometer.configure
  sampler := Sampler (Device) sensor magnetometer --correction=correction
  first := sampler.read-batch_
  if first[0].size != 3: throw "Initial FIFO transition frame retained"
  field/Vector3 := first[1]
  if (field.minus ((Vector3 45 30 12).scaled (50.0 / 45))).length > 1e-8:
    throw "Native calibration and handedness were applied in wrong order"
  if not sampler.heading-enabled: throw "Valid correction did not enable heading"
  sampler.next-mag-poll-us_ = Time.monotonic-us + 1_000_000
  if sampler.read-magnetic_ != null or registers.reads != 1:
    throw "Compass poll interval did not limit bus reads"
  sampler.next-mag-poll-us_ = 0
  imu-registers.words = 30 // A complete batch with one old frame still queued.
  second := sampler.read-batch_
  if second[0].size != 4 or second[1] != null or registers.reads != 2:
    throw "FIFO catch-up skipped compass polling or used a live field on old frames"
  registers.overrun = true
  sampler.next-mag-poll-us_ = 0
  if sampler.read-magnetic_ != null or sampler.mag-overruns_ != 1:
    throw "Overrun field used for heading"
  uncalibrated := Sampler (Device) (imu.Driver null) magnetometer
  registers.overrun = false
  if uncalibrated.read-magnetic_ != null or uncalibrated.heading-enabled:
    throw "Uncalibrated field used for heading"
  print "Compass catch-up polling, calibration order, and heading gates tests passed"
