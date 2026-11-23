// Tests FIFO acquisition, discontinuities and recovery.
// Run as part of the RH2 motion host test suite.

import ...examples.motion.settings as mode
import io.byte-order show LITTLE-ENDIAN
import lsm6ds3 as imu
import lis2mdl as mag
import ...examples.motion.acquisition show Sampler
import ...examples.motion.settings as settings
import ...examples.motion.analysis as analysis

class StaleRegisters:
  resets/int := 0
  read-reg reg/int size/int -> ByteArray:
    if reg == 0x3a: return #[0x68, 0x05, 0, 0] // More than two seconds queued.
    if reg == 0x3e: return ByteArray size
    if reg == 0x3b: return #[0]
    if reg == 0x0f: return #[0x69]
    return ByteArray size
  write data/ByteArray: resets++

class SensorBus:
  with-i2c [action]: return action.call

main:
  // Exercise the real sample->calibration->fusion->queue path without GPIOs.
  // Driver objects are never accessed by consume_; the input is a decoded frame.
  sampler := Sampler null (imu.Driver null) (mag.Driver null)
  if sampler.heading-enabled: throw "Uncalibrated heading enabled"
  bytes := ByteArray 12
  LITTLE-ENDIAN.put-int16 bytes 6 -4098 // Upright RH2: specific force is -X.
  stationary := imu.Sample bytes 0
  (settings.CALIBRATION-SAMPLES - 1).repeat:
    sampler.consume_ stationary null
  if sampler.calibrated_: throw "Calibrated with an incomplete quiet window"
  sampler.consume_ stationary null
  if not sampler.calibrated_: throw "Quiet calibration never completed"
  settings.WARMUP-SAMPLES.repeat: sampler.consume_ stationary null
  if sampler.ready_.size != 0: throw "Warmup leaked into output"
  analysis.WINDOW-SIZE.repeat: sampler.consume_ stationary null
  if sampler.ready_.size != 1: throw "Lost completed window"
  first-sample := sampler.window_.first-sample
  analysis.WINDOW-HOP.repeat: sampler.consume_ stationary null
  if sampler.ready_.size != 1 or sampler.dropped_ != 1:
    throw "Slow reporter did not replace a stale window"
  newest := sampler.ready_.receive --blocking=false
  if newest.window.first-sample != first-sample: throw "Queue did not retain latest overlapping window"
  previous-bias := sampler.bias_
  previous-attitude := sampler.fusion_.attitude
  sampler.configure-app mode.FREQUENCY-DOMAIN
  sampler.prepare-run
  if not sampler.spectrum-enabled_ or sampler.autocorrelation-enabled_ or sampler.peaks-enabled_ or sampler.bias_ != previous-bias:
    throw "Frequency app changed calibration or retained time-domain workload"
  sampler.configure-app mode.TIME-DOMAIN
  if sampler.spectrum-enabled_ or not sampler.autocorrelation-enabled_ or not sampler.peaks-enabled_:
    throw "Time-domain app enabled spectral work"
  sampler.invalidate_
  if not sampler.calibrated_ or sampler.window_.count != 0 or sampler.generation_ != 1 or
      sampler.bias_ != previous-bias or sampler.fusion_.attitude != previous-attitude or sampler.warmup_ != 0:
    throw "Acquisition gap lost gyro bias or retained window state"
  sampler.calibrated_ = false
  sampler.calibration-start-us_ = 0
  sampler.invalidate_
  if sampler.calibration-start-us_ != 0: throw "Repeated faults extended calibration timeout"
  LITTLE-ENDIAN.put-int16 bytes 6 -32768
  clipped := imu.Sample bytes 0
  sampler.consume_ clipped null
  if sampler.calibration_.count != 0: throw "Clipped data entered calibration"
  sampler.report-error_ = "REPORT_FAILED"
  if (catch: sampler.acquire_) != "REPORT_FAILED": throw "Reporter failure left acquisition running silently"
  registers := StaleRegisters
  sensor := imu.Driver registers
  sensor.configure
  sensor.start-fifo
  registers.resets = 0
  stale := Sampler (SensorBus) sensor (mag.Driver null)
  stale.calibrated_ = true
  original-bias := stale.bias_
  batch := stale.read-batch_
  if not batch[0].is-empty or registers.resets != 2 or not stale.calibrated_ or stale.bias_ != original-bias:
    throw "Backlog was not discarded without recalibration"
  print "Acquisition warmup, gap, saturation, and queue bounds tests passed"
