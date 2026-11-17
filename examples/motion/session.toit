// Owns sensor setup, calibration and cleanup across motion app sessions.
// Used by rh2.toit when opening an app.

import lsm6ds3 as imu
import lis2mdl as compass
import system.storage
import .acquisition show Sampler
import .analysis as analysis
import .settings as settings
import .calibration show CalibrationStore Correction Guide

/** Hardware/calibration session shared by all motion apps in one container. */
class Session:
  dev_/any
  screen_/any
  controls_/any
  imu_/imu.Driver
  mag_/compass.Driver
  initialized_/bool := false
  sampler_/Sampler? := null
  blocked_/bool := false

  constructor .dev_ .screen_ .controls_:
    imu_ = imu.Driver (dev_.i2c-bus.device imu.ADDRESS-HIGH)
    mag_ = compass.Driver (dev_.i2c-bus.device compass.ADDRESS)

  run selected/int:
    app-name := settings.name selected
    if blocked_: throw "Restart this container to retry charging recovery"
    cleanup-error := null
    error := catch:
      try:
        if not initialized_:
          initialize_
          initialized_ = true
        else:
          dev_.with-i2c:
            configure-sensors_
          sleep --ms=200
        screen_.resume
        screen_.configure-app selected
        if sampler_ == null:
          sampler_ = create-sampler_
        sampler_.configure-app selected
        if sampler_.calibrated_: print "# resuming with startup gyro bias; motion while in menus was not tracked"
        sampler_.prepare-run
        dev_.with-i2c: imu_.restart-fifo
        controls_.clear
        print "# motion app: $app-name"
        if settings.LOG-FEATURES and selected != settings.COMPASS:
          print "generation,first_sample,time_s,qw,qx,qy,qz,gravity_updates,magnetic_updates,mag_uT,mag_overruns,dropped_windows,analysis_ms,$(analysis.HEADER)"
        sampler_.run
      finally:
        cleanup-error = stop-sensors_
    if error: throw error
    if cleanup-error: throw cleanup-error

  stop-sensors_:
    // Attempt both targets even after partial initialization or a failed stop.
    // Keep the original app error when cleanup fails too; log each failed target.
    imu-error := catch: dev_.with-i2c: imu_.stop
    if imu-error: print "# IMU shutdown failed: $imu-error"
    mag-error := catch: dev_.with-i2c: mag_.stop
    if mag-error: print "# magnetometer shutdown failed: $mag-error"
    return imu-error != null ? imu-error : mag-error

  create-sampler_ -> Sampler:
    store/CalibrationStore? := null
    error := catch: store = CalibrationStore (storage.Bucket.open --flash "lightbug/motion")
    if error: print "# calibration storage unavailable: $error"
    guide := Guide dev_ mag_ screen_ controls_ store
    correction/Correction? := null
    error = catch: correction = guide.run
    if error:
      blocked_ = guide.restore-failed_
      throw error
    return Sampler dev_ imu_ mag_ --correction=correction --screen=screen_ --controls=controls_

  initialize_:
    dev_.with-i2c:
      imu_.reset
      mag_.reset
    deadline := Time.monotonic-us + 100_000
    while true:
      pending := dev_.with-i2c: imu_.reset-pending or mag_.reset-pending
      if not pending: break
      if Time.monotonic-us >= deadline: throw "Sensor reset timed out"
      sleep --ms=2
    dev_.with-i2c:
      configure-sensors_
    // Gyro turn-on/filter transients must not become the learned zero-rate bias.
    sleep --ms=200
    dev_.with-i2c: imu_.restart-fifo

  configure-sensors_:
    // The demo's timing and scaling contract is explicit; package defaults
    // are not a substitute for this paired, no-decimation FIFO profile.
    imu_.configure
        --accel-rate=imu.Driver.RATE-104HZ
        --gyro-rate=imu.Driver.RATE-104HZ
        --accel-range=imu.Driver.ACCEL-RANGE-8G
        --gyro-range=imu.Driver.GYRO-RANGE-1000DPS
    if imu_.accel-rate-hz != settings.SAMPLE-RATE or imu_.gyro-rate-hz != settings.SAMPLE-RATE:
      throw "Motion sample rate does not match sensor configuration"
    imu_.start-fifo --mode=imu.Driver.FIFO-CONTINUOUS --rate=imu.Driver.RATE-104HZ
    mag_.configure --rate=compass.Driver.RATE-10HZ --mode=compass.Driver.MODE-CONTINUOUS
