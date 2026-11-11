// Samples the sensors, maintains orientation and queues motion windows.
// Used by session.toit for all three RH2 motion apps.

import lsm6ds3 as imu
import lis2mdl as compass
import motion-fusion show Fusion Vector3 Quaternion GRAVITY
import monitor
import lightbug.messages show ButtonPress
import .analysis as analysis
import .settings as settings
import .compass as compass-ui
import .calibration show Correction
import .display show Screen Controls

/** End-of-window metadata travels with its samples through the bounded queue. */
class Report:
  window/analysis.Window
  attitude/Quaternion
  magnetic-count/int
  field/float?
  overruns/int
  dropped/int
  sample-us/int
  constructor .window .attitude .magnetic-count .field .overruns .dropped .sample-us:

/** Acquisition owns sensor and filter state; reporting never holds the bus. */
class Sampler:
  dev_/any
  imu_/imu.Driver
  mag_/compass.Driver
  ready_ := monitor.Channel 1
  fusion_ := Fusion
  calibration_ := Calibration
  bias_ := Vector3 0 0 0
  imu-axes_ := settings.imu-axes
  calibrated_/bool := false
  warmup_/int := settings.WARMUP-SAMPLES
  generation_/int := 0
  index_/int := 0
  dropped_/int := 0
  mag-overruns_/int := 0
  mag-strength_/float? := null
  next-mag-poll-us_/int := 0
  last-data-us_/int := Time.monotonic-us
  calibration-start-us_/int := Time.monotonic-us
  window_/analysis.Window := analysis.Window 0 0
  next-window_/analysis.Window? := null
  correction_/Correction?
  screen_/Screen?
  controls_/Controls?
  next-status-us_/int := 0
  report-error_/any := null
  spectrum-enabled_/bool := false
  autocorrelation-enabled_/bool := true
  peaks-enabled_/bool := true
  compass-enabled_/bool := false
  next-compass-us_/int := 0
  next-compass-log-us_/int := 0
  last-magnetic-us_/int := 0

  constructor .dev_ .imu_ .mag_ --correction/Correction?=null --screen/Screen?=null --controls/Controls?=null --generation/int=0:
    generation_ = generation
    correction_ = correction
    screen_ = screen
    controls_ = controls

  heading-enabled -> bool: return correction_ != null

  configure-app selected/int:
    settings.name selected // Validate before changing the processing profile.
    compass-enabled_ = selected == settings.COMPASS
    spectrum-enabled_ = selected == settings.FREQUENCY-DOMAIN
    autocorrelation-enabled_ = selected == settings.TIME-DOMAIN
    peaks-enabled_ = selected == settings.TIME-DOMAIN

  prepare-run:
    last-magnetic-us_ = 0
    next-compass-us_ = 0
    // Menus pause acquisition. Retain a completed bias, but start a new
    // sample timeline and never integrate the time spent browsing menus.
    index_ = 0
    window_ = analysis.Window 0 generation_
    next-window_ = null
    last-data-us_ = Time.monotonic-us
    calibration-start-us_ = last-data-us_
    report-error_ = null
    if calibrated_:
      warmup_ = 0
    else:
      calibration_ = Calibration
      warmup_ = settings.WARMUP-SAMPLES

  run:
    reporter := task --background=true::
      error := catch: report_
      if error: report-error_ = error
    try:
      acquire_
    finally:
      generation_++
      reporter.cancel

  acquire_:
    failures := 0
    while true:
      if report-error_ != null: throw report-error_
      if controls_ != null:
        button := controls_.poll --page=screen_.current-page
        if button != null:
          if compass-enabled_:
            if button == ButtonPress.BUTTON-ID_ACTION: return
          else:
            screen_.button button
        if screen_.exit-requested:
          screen_.exit-requested = false
          return
      update-status_
      frames := []
      magnetic/Vector3? := null
      error := catch:
        batch := read-batch_
        frames = batch[0]
        magnetic = batch[1]
      if error:
        print "# acquisition gap: $error; preserving gyro bias, orientation may drift"
        invalidate_
        failures++
        if failures >= 5: throw "Repeated sensor acquisition failures: $error"
        dev_.with-i2c: imu_.restart-fifo
        sleep --ms=20
        continue
      if not frames.is-empty:
        last-data-us_ = Time.monotonic-us
        failures = 0
      frames.size.repeat: | i |
        consume_ frames[i] (i == frames.size - 1 ? magnetic : null)
      if not calibrated_ and Time.monotonic-us - calibration-start-us_ > settings.CALIBRATION-TIMEOUT-US:
        throw "Calibration timed out: hold the unit still and restart"
      // Release the shared bus and yield even when there is a backlog.
      if imu_.pending-frames > 0: yield else: sleep --ms=2

  read-batch_ -> List:
    started := Time.monotonic-us
    limit := imu_.pending-frames >= 4 ? 16 : 4
    frames := dev_.with-i2c: imu_.read-fifo --max-frames=limit
    elapsed-ms := (Time.monotonic-us - started) / 1000
    if elapsed-ms >= 250: print "# IMU batch delayed $(elapsed-ms)ms (includes bus wait)"
    if imu_.pending-frames > settings.MAX-BACKLOG-FRAMES:
      print "# IMU backlog $(imu_.pending-frames) frames; discarding stale motion data"
      invalidate_
      dev_.with-i2c: imu_.restart-fifo
      return [[], null]
    if frames.is-empty and Time.monotonic-us - last-data-us_ > 1_000_000:
      throw "IMU produced no frames for one second"
    magnetic/Vector3? := null
    // Keep polling the compass during FIFO catch-up so old magnetic data
    // does not sit unread. Apply heading only near the live IMU stream.
    if not frames.is-empty:
      field := read-magnetic_
      if imu_.pending-frames == 0: magnetic = field
    return [frames, magnetic]

  read-magnetic_ -> Vector3?:
    now := Time.monotonic-us
    if now < next-mag-poll-us_: return null
    // Poll twice per nominal magnetic sample rather than once per IMU frame.
    next-mag-poll-us_ = now + 50_000
    sample := dev_.with-i2c: mag_.read
    if sample == null: return null
    if sample.overrun: mag-overruns_++
    field := Vector3 sample.x sample.y sample.z
    if correction_ != null: field = correction_.apply field
    field = imu-axes_.apply (settings.magnetic-to-imu field)
    mag-strength_ = field.length
    if sample.clipped or sample.overrun or not heading-enabled: return null
    // The simple fit's radius is not an independent absolute field reference.
    // Gate relative changes, then scale for Fusion's illustrative uT gate.
    if not 0.6 * correction_.field <= mag-strength_ <= 1.4 * correction_.field: return null
    return field.scaled (50.0 / correction_.field)

  consume_ sample/imu.Sample magnetic/Vector3?:
    index_++
    if sample.clipped:
      if calibrated_ or calibration_.count > 0:
        print "# clipped IMU sample; restarting motion window, orientation may drift"
        invalidate_
      return
    a := imu-axes_.apply (Vector3 sample.ax sample.ay sample.az)
    g := imu-axes_.apply (Vector3 sample.gx sample.gy sample.gz)
    if not calibrated_:
      if calibration_.add a g:
        bias_ = calibration_.bias
        fusion_.reset calibration_.acceleration
        calibrated_ = true
        print "# gyro bias rad/s: $(bias_.x),$(bias_.y),$(bias_.z)"
      return
    fusion_.update a (g.minus bias_) (1.0 / settings.SAMPLE-RATE) --magnetic=magnetic
    if fusion_.magnetic-used:
      now := Time.monotonic-us
      if compass-enabled_ and magnetic != null:
        elapsed := now - last-magnetic-us_
        weight := last-magnetic-us_ == 0 ? 1.0 : elapsed / (300_000.0 + elapsed)
        fusion_.attitude = compass-ui.reference-heading fusion_.attitude magnetic weight
      last-magnetic-us_ = now
    if warmup_ > 0:
      warmup_--
      return
    if compass-enabled_:
      now := Time.monotonic-us
      if screen_ != null and now >= next-compass-us_ and imu_.pending-frames == 0:
        next-compass-us_ = now + 100_000
        fresh := heading-enabled and last-magnetic-us_ > 0 and now - last-magnetic-us_ < 2_000_000
        screen_.compass-results fusion_.attitude fresh now
        if settings.LOG-DIAGNOSTICS and now >= next-compass-log-us_:
          next-compass-log-us_ = now + 5_000_000
          age := last-magnetic-us_ == 0 ? -1 : (now - last-magnetic-us_) / 1000
          quality := correction_ == null ? null : correction_.quality-score
          print "# compass: calibrated=$heading-enabled quality=$quality field_uT=$mag-strength_ magnetic_age_ms=$age overruns=$mag-overruns_"
      return
    if window_.count == 0: window_ = analysis.Window index_ generation_
    if window_.count == analysis.WINDOW-HOP and next-window_ == null:
      next-window_ = analysis.Window index_ generation_
    linear := fusion_.linear-acceleration a
    svm := a.length
    if next-window_ != null:
      next-window_.add linear svm fusion_.acceleration-used --magnetic-used=fusion_.magnetic-used
    full := window_.add linear svm fusion_.acceleration-used --magnetic-used=fusion_.magnetic-used
    if full:
      sample-us := Time.monotonic-us - (imu_.pending-frames * 1_000_000 / settings.SAMPLE-RATE)
      entry := Report window_ fusion_.attitude window_.magnetic-count mag-strength_ mag-overruns_ dropped_ sample-us
      if not ready_.try-send entry:
        if (ready_.receive --blocking=false) != null: dropped_++
        entry = Report window_ fusion_.attitude window_.magnetic-count mag-strength_ mag-overruns_ dropped_ sample-us
        if not ready_.try-send entry: dropped_++
      window_ = next-window_
      next-window_ = null

  invalidate_:
    generation_++
    last-magnetic-us_ = 0
    index_ = 0
    // Preserve the stationary bias across a FIFO gap. Attitude cannot be
    // reconstructed over missing samples; feedback must settle it again.
    if not calibrated_: calibration_ = Calibration
    last-data-us_ = Time.monotonic-us
    warmup_ = calibrated_ ? 0 : settings.WARMUP-SAMPLES
    window_ = analysis.Window 0 generation_
    next-window_ = null
    if screen_ != null and calibrated_: screen_.note-gap

  update-status_:
    if screen_ == null or Time.monotonic-us < next-status-us_: return
    if compass-enabled_ and calibrated_ and warmup_ == 0: return
    next-status-us_ = Time.monotonic-us + 1_000_000
    if not calibrated_:
      screen_.status "Keep unit still" ["Gyro calibration", "Quiet $(calibration_.count)/$(settings.CALIBRATION-SAMPLES)", "Hold still for 2 seconds", "Away from vibration"]
    else if warmup_ > 0:
      screen_.status "Fusion warmup" ["Settling orientation", "$(warmup_) samples left", "", "Then see motion results"]
    else if not screen_.has-results:
      screen_.status "Collecting motion" ["$(window_.count)/$(analysis.WINDOW-SIZE) samples", "Left/right: results pages", "Middle: motion apps", "About 2.5s per window"]

  report_:
    plan/analysis.Plan? := spectrum-enabled_ ? (analysis.Plan analysis.WINDOW-SIZE analysis.SAMPLE-RATE) : null
    while true:
      entry := ready_.receive
      window/analysis.Window := entry.window
      if window.generation != generation_: continue
      q/Quaternion := entry.attitude
      start := Time.monotonic-us
      features := analysis.Features window
          --with-spectrum=spectrum-enabled_
          --with-autocorrelation=autocorrelation-enabled_
          --with-peaks=peaks-enabled_
          --spectrum-plan=plan
      elapsed-ms := (Time.monotonic-us - start) / 1000
      if window.generation != generation_: continue
      time := window.first-sample / analysis.SAMPLE-RATE
      if settings.LOG-FEATURES:
        print "$(window.generation),$(window.first-sample),$time,$(q.w),$(q.x),$(q.y),$(q.z),$(window.correction-count),$(entry.magnetic-count),$(entry.field),$(entry.overruns),$(entry.dropped),$elapsed-ms,$features"
      if screen_ != null:
        screen_.results features q window.generation window.correction-count entry.field entry.dropped entry.overruns heading-enabled --magnetic-count=entry.magnetic-count --analysis-ms=elapsed-ms --sample-us=entry.sample-us

/** Rejects moving windows instead of silently learning motion as gyro bias. */
class Calibration:
  count/int := 0
  acceleration/Vector3 := Vector3 0 0 0
  bias/Vector3 := Vector3 0 0 0
  acceleration-energy_/float := 0.0
  gyro-energy_/float := 0.0

  add a/Vector3 g/Vector3 -> bool:
    if (a.length - GRAVITY).abs > 0.05 * GRAVITY or g.length > 0.25:
      clear
      return false
    count++
    acceleration = acceleration.plus a
    bias = bias.plus g
    acceleration-energy_ += a.length * a.length
    gyro-energy_ += g.length * g.length
    if count < settings.CALIBRATION-SAMPLES: return false
    acceleration = acceleration.scaled (1.0 / count)
    bias = bias.scaled (1.0 / count)
    a-variance := max 0.0 (acceleration-energy_ / count - acceleration.length * acceleration.length)
    g-variance := max 0.0 (gyro-energy_ / count - bias.length * bias.length)
    if a-variance > 0.01 or g-variance > 0.0004:
      clear
      return false
    return true

  clear:
    count = 0
    acceleration = Vector3 0 0 0
    bias = Vector3 0 0 0
    acceleration-energy_ = 0.0
    gyro-energy_ = 0.0
