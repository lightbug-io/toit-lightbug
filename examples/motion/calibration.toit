// Guides magnetometer calibration, stores corrections and restores charging.
// Used by session.toit before starting motion acquisition.

import lightbug.messages as messages
import lightbug.protocol as protocol
import lightbug.messages show ButtonPress
import motion-fusion show Vector3
import lis2mdl show Sample
import .display as display
import .settings as settings

MIN-CAPTURE-US ::= 20_000_000
CHECK-INTERVAL-US ::= 2_000_000

/** Guided setup uses V3 display/buttons while magnetic reads keep their own lock. */
class Guide:
  dev_/any
  mag_/any
  screen_/any
  controls_/any
  store_/CalibrationStore?
  restore-failed_/bool := false

  constructor .dev_ .mag_ .screen_ .controls_ .store_:

  run -> Correction?:
    recover-charging_
    saved/Correction? := null
    error := catch: if store_ != null: saved = store_.load
    if error: print "# calibration load failed: $error"
    lines := ["Device pauses charging", "No need to unplug", "Middle: calibrate", "Left: skip, heading off"]
    if saved != null:
      lines = ["Saved calibration found", "Middle: use saved", "Right: recalibrate", "Left: skip, heading off"]
      if saved.quality-score != null: lines[0] = "Saved quality $(saved.quality-score)/100"
    choice := prompt_ display.PAGE-SETUP "Mag setup" lines
    if choice == ButtonPress.BUTTON-ID_UP_LEFT: return null
    if saved != null and choice == ButtonPress.BUTTON-ID_ACTION: return saved
    while true:
      quality/Quality? := null
      error = catch: quality = calibrate_
      if error:
        if restore-failed_:
          print "# charge restore failed: $error"
          screen_.present display.PAGE-ERROR "Charge restore failed"
              ["Check console for limit", "Restart to retry restore", "Heading stays off", "Restart after checking"]
          throw "Charge restore failed; restart to retry"
        if error == "Calibration cancelled": return null
        print "# magnetic calibration rejected: $error"
        choice = prompt_ display.PAGE-SETUP "Try calibration"
            [calibration-hint error, "Check sensor and retry", "Middle: try again", "Left: skip, heading off"]
        if choice == ButtonPress.BUTTON-ID_UP_LEFT: return null
        continue
      candidate := quality.correction
      candidate.quality-score = quality.score
      print "# calibration quality $(quality.score)/100; held-out RMS error $((quality.rms-error * 100).to-int)%"
      choice = prompt_ display.PAGE-CONFIRM "Save calibration?"
          ["Quality $(quality.score)/100", "Charging may affect heading", "Middle: save and use", "Right: redo / Left: off"]
      if choice == ButtonPress.BUTTON-ID_UP_LEFT: return null
      if choice == ButtonPress.BUTTON-ID_DOWN_RIGHT: continue
      return save_ candidate

  calibrate_ -> Quality:
    screen_.present display.PAGE-ROTATE "Mag calibration"
        ["Device pauses charging", "No need to unplug", "Preparing calibration", "Please wait"]
    if store_ == null: throw "Charge recovery storage unavailable"
    original := get-charge-limit dev_.comms
    // Persist before changing hardware so the next app launch can recover
    // after power loss or forced container termination bypasses finally.
    store_.remember-charge-limit original
    print "# calibration: original charge current limit $original mA"
    try:
      set-charge-limit dev_.comms 0
      if (get-charge-limit dev_.comms) != 0: throw "Charge limit did not change to zero"
      print "# calibration: charging paused"
      sleep --ms=500
      return collect_ (Capture)
    finally:
      restore-charging_ original

  recover-charging_:
    if store_ == null: return
    original := store_.pending-charge-limit
    if original == null: return
    screen_.present display.PAGE-SETUP "Restoring charging"
        ["Interrupted calibration", "Restoring saved limit", "Please wait", ""]
    restore-charging_ original

  restore-charging_ original/int:
    restore-failed_ = true
    set-charge-limit dev_.comms original
    if (get-charge-limit dev_.comms) != original: throw "Charge restore verification failed; original limit $original mA"
    store_.clear-charge-limit
    restore-failed_ = false
    print "# calibration: restored charge current limit $original mA"

  prompt_ page/int title/string lines/List -> int:
    controls_.clear
    screen_.present page title lines
    controls_.clear
    return controls_.wait page

  save_ correction/Correction -> Correction?:
    while true:
      error := catch:
        if store_ == null: throw "Flash storage unavailable"
        store_.save correction
      if error == null:
        screen_.present display.PAGE-CONFIRM "Saved"
            ["Field $(display.number correction.field) uT", "Heading enabled", "Next: keep unit still", "Gyro calibration follows"]
        return correction
      print "# magnetic calibration save failed: $error"
      choice := prompt_ display.PAGE-CONFIRM "Save failed"
          ["Calibration not saved", "Middle: use this session", "Right: retry saving", "Left: skip, heading off"]
      if choice == ButtonPress.BUTTON-ID_UP_LEFT: return null
      if choice == ButtonPress.BUTTON-ID_ACTION: return correction

  collect_ capture/Capture -> Quality:
    page := display.PAGE-ROTATE
    title := "Mag calibration"
    screen_.present page title ["Turn unit slowly", "Show every face upward", "About 20 seconds or more", "Left: skip"]
    start := Time.monotonic-us
    next-check := start
    next-raw-log := start
    last-good := start
    successful-checks := 0
    overruns := 0
    clipped := 0
    while true:
      if (controls_.poll --page=page) == ButtonPress.BUTTON-ID_UP_LEFT: throw "Calibration cancelled"
      sample := dev_.with-i2c: mag_.read
      now := Time.monotonic-us
      if sample != null:
        if sample.overrun: overruns++
        if sample.clipped: clipped++
        if settings.LOG-DIAGNOSTICS and now >= next-raw-log:
          raw := Vector3 sample.x sample.y sample.z
          print "# mag raw ms=$((now - start) / 1000) x=$(sample.x) y=$(sample.y) z=$(sample.z) norm=$(raw.length) overrun=$(sample.overrun) clipped=$(sample.clipped)"
          next-raw-log = now + 1_000_000
      // An overrun means an earlier reading was missed, not that this latest
      // sample is unusable. Slow calibration tolerates irregular sample times.
      if sample != null and not sample.clipped:
        if offer-sample capture sample: last-good = now
      if now - last-good > 10_000_000:
        print "# mag calibration: $(capture.samples.size) accepted, $overruns overruns, $clipped clipped"
        throw "No usable magnetic samples"
      if now >= next-check:
        quality/Quality? := null
        error := catch: quality = capture.fit-checked --allow-imperfect
        successful-checks = error == null ? successful-checks + 1 : 0
        if now - start >= MIN-CAPTURE-US and successful-checks >= 2: return quality
        hint := error == null ? "Fit found - keep turning" : (calibration-hint error)
        if error == "ROTATE_ALL_THREE_AXES" or error == "FIELD_NOT_STABLE": hint = capture.detail
        spans := capture.spans
        progress := "X$(spans.x.to-int) Y$(spans.y.to-int) Z$(spans.z.to-int) uT"
        if settings.LOG-DIAGNOSTICS:
          print "# mag calibration: $(capture.samples.size) readings, spans $progress, $overruns overruns, $clipped clipped, status $error, $(capture.detail)"
        bars := "X$(axis-bar spans.x) Y$(axis-bar spans.y) Z$(axis-bar spans.z)"
        screen_.show page title ["Turn unit slowly", hint, bars, "Left: skip"]
        next-check = now + CHECK-INTERVAL-US
      sleep --ms=50

calibration-hint error -> string:
  if error == "Charge recovery storage unavailable": return "Calibration needs flash"
  if error == "MORE_ROTATION_SAMPLES": return "Gathering readings..."
  if error == "ROTATE_ALL_THREE_AXES": return "Tilt end over end and roll"
  if error == "FIELD_NOT_STABLE": return "Field varies - turn slowly"
  if error == "MAGNETIC_ENVIRONMENT" or error == "EXCESSIVE_MAGNETIC_DISTORTION":
    return "Field outside fit range"
  if error == "No usable magnetic samples": return "No usable sensor readings"
  return "Sensor read failed"

/** Calibration can use the latest reading even when intermediate ones were lost. */
offer-sample capture/Capture sample/Sample -> bool:
  if sample.clipped: return false
  return capture.add (Vector3 sample.x sample.y sample.z)

/** Each bar reaches five blocks at the minimum 20 uT axis span. */
axis-bar span/float -> string:
  bars := ["-----", "#----", "##---", "###--", "####-", "#####"]
  return bars[min 5 (max 0 (span / 4).to-int)]

MAX-SAMPLES ::= 600
MIN-SAMPLES ::= 120
// Older records could have been fitted from a non-incrementing sensor read.
RECORD-VERSION ::= 2

/** Native-axis hard-iron offset and diagonal soft-iron scale, in microtesla. */
class Correction:
  quality-score/int? := null
  offset/Vector3
  scale/Vector3
  field/float
  constructor .offset .scale .field:
    if not offset.finite or not scale.finite or not field.is-finite: throw "INVALID_MAG_CALIBRATION"
    if offset.x.abs > 150 or offset.y.abs > 150 or offset.z.abs > 150 or
        not 10 <= field <= 150: throw "MAGNETIC_ENVIRONMENT"
    [scale.x, scale.y, scale.z].do:
      if not 0.5 <= it <= 2.0: throw "EXCESSIVE_MAGNETIC_DISTORTION"

  apply raw/Vector3 -> Vector3:
    v := raw.minus offset
    return Vector3 (v.x * scale.x) (v.y * scale.y) (v.z * scale.z)

  record -> Map:
    return {"version": RECORD-VERSION, "offset": [offset.x, offset.y, offset.z],
        "scale": [scale.x, scale.y, scale.z], "field": field, "quality": quality-score}

  static from-record value -> Correction?:
    if value is not Map: return null
    if (value.get "version" --if-absent=(: null)) != RECORD-VERSION: return null
    offset := value.get "offset" --if-absent=(: null)
    scale := value.get "scale" --if-absent=(: null)
    field := value.get "field" --if-absent=(: null)
    quality := value.get "quality" --if-absent=(: null)
    if quality != null and (quality is not int or not 0 <= quality <= 100): return null
    if not vector-record_ offset or not vector-record_ scale or field is not num: return null
    correction/Correction? := null
    error := catch:
      correction = Correction
          (Vector3 offset[0] offset[1] offset[2])
          (Vector3 scale[0] scale[1] scale[2])
          field.to-float
      correction.quality-score = quality
    return error == null ? correction : null

  static vector-record_ value -> bool:
    return value is List and value.size == 3 and value.every (: it is num and it.to-float.is-finite)

/** Bounded training capture. The guide offers at most ten samples per second. */
class Capture:
  samples/List := []
  next_/int := 0
  detail/string := "Collecting readings"

  /** Observed native-axis ranges in microtesla, useful while rotating. */
  spans -> Vector3:
    if samples.is-empty: return Vector3 0 0 0
    low := [samples[0].x, samples[0].y, samples[0].z]
    high := low.copy
    samples.do: | v |
      values := [v.x, v.y, v.z]
      3.repeat:
        low[it] = min low[it] values[it]
        high[it] = max high[it] values[it]
    return Vector3 (high[0] - low[0]) (high[1] - low[1]) (high[2] - low[2])
  add field/Vector3 -> bool:
    // Raw magnitude includes hard-iron offsets; limiting it biases the fit
    // toward orientations with a smaller measured field. The driver rejects
    // clipped readings before they reach this capture.
    if not field.finite or field.length <= 1: return false
    if samples.size < MAX-SAMPLES:
      samples.add field
    else:
      // Let additional turns improve coverage without retaining an unbounded
      // recording or permanently keeping early magnetic disturbances.
      samples[next_] = field
      next_ = (next_ + 1) % MAX-SAMPLES
    return true

  /** Every fifth reading checks consistency without participating in the fit. */
  fit-checked --allow-imperfect/bool=false -> Quality:
    training := Capture
    samples.size.repeat:
      if it % 5 != 0: training.add samples[it]
    correction/Correction? := null
    error := catch: correction = training.fit --allow-imperfect=allow-imperfect
    detail = training.detail
    if error: throw error
    check := Quality correction --min-samples=24 --required-axes=4
    samples.size.repeat:
      if it % 5 == 0: check.add samples[it]
    detail = check.describe
    if not check.good and (not allow-imperfect or check.problem != "FIELD_NOT_STABLE"): throw check.problem
    return check

  fit --allow-imperfect/bool=false -> Correction:
    if samples.size < MIN-SAMPLES:
      detail = "Need more readings"
      throw "MORE_ROTATION_SAMPLES"
    low := [float.INFINITY, float.INFINITY, float.INFINITY]
    high := [-float.INFINITY, -float.INFINITY, -float.INFINITY]
    samples.do: | v |
      low[0] = min low[0] v.x
      low[1] = min low[1] v.y
      low[2] = min low[2] v.z
      high[0] = max high[0] v.x
      high[1] = max high[1] v.y
      high[2] = max high[2] v.z
    radii := List 3: (high[it] - low[it]) / 2
    if radii.any (: it < 10):
      detail = "Need all 3 axes"
      throw "ROTATE_ALL_THREE_AXES"
    radius := (radii[0] + radii[1] + radii[2]) / 3
    offset := Vector3 ((high[0] + low[0]) / 2) ((high[1] + low[1]) / 2) ((high[2] + low[2]) / 2)
    correction := Correction offset (Vector3 (radius / radii[0]) (radius / radii[1]) (radius / radii[2])) radius
    quality := Quality correction
    samples.do: quality.add it
    detail = quality.describe
    if not quality.good and (not allow-imperfect or quality.problem != "FIELD_NOT_STABLE"): throw quality.problem
    return correction

/** Checks signed axis coverage and residual sphere error without refitting. */
class Quality:
  correction/Correction
  count/int := 0
  caps_/int := 0
  energy_/float := 0.0
  outside_/int := 0
  min-samples_/int
  required-axes_/int
  constructor .correction --min-samples/int=MIN-SAMPLES --required-axes/int=6:
    min-samples_ = min-samples
    required-axes_ = required-axes

  add raw/Vector3:
    if not raw.finite: return
    field := correction.apply raw
    norm := field.length
    if norm < 1e-6 or not norm.is-finite: return
    count++
    error := (norm - correction.field) / correction.field
    energy_ += error * error
    if error.abs > 0.2: outside_++
    direction := field.scaled (1 / norm)
    // Wide caps tolerate ordinary hand rotations. Requiring both signs of all
    // three axes still rejects flat circles while accepting coordinate-plane turns.
    if direction.x.abs > 0.7: caps_ |= 1 << (direction.x > 0 ? 0 : 1)
    if direction.y.abs > 0.7: caps_ |= 1 << (direction.y > 0 ? 2 : 3)
    if direction.z.abs > 0.7: caps_ |= 1 << (direction.z > 0 ? 4 : 5)

  coverage -> int:
    result := 0
    6.repeat:
      if (caps_ & (1 << it)) != 0: result++
    return result
  rms-error -> float: return count == 0 ? 1.0 : (energy_ / count).sqrt
  // Heuristic, not an estimate of heading accuracy: 0% residual maps to 100,
  // 50% RMS residual or more maps to zero.
  score -> int: return (max 0 (min 100 (100 - (rms-error * 200).to-int)))
  describe -> string:
    return "Dir $coverage/$required-axes_ Err $((rms-error * 100).to-int)% Bad $outside_/$count"
  good -> bool:
    return problem == null

  problem -> string?:
    if count < min-samples_: return "MORE_ROTATION_SAMPLES"
    if coverage < required-axes_: return "ROTATE_ALL_THREE_AXES"
    if rms-error > 0.12 or outside_ * 20 > count: return "FIELD_NOT_STABLE"
    return null

/** One versioned flash record; failed writes never masquerade as a saved result. */
class CalibrationStore:
  bucket_/any
  constructor .bucket_:
  load -> Correction?:
    return Correction.from-record (bucket_.get "rh2-lis2mdl" --if-absent=(: null))
  save correction/Correction:
    bucket_["rh2-lis2mdl"] = correction.record

  pending-charge-limit -> int?:
    value := bucket_.get "paused-charge-limit" --if-absent=(: null)
    if value != null and (value is not int or not 0 <= value <= 5056):
      throw "Invalid saved charging limit"
    return value

  remember-charge-limit original/int:
    if not 0 <= original <= 5056: throw "Invalid charge current limit"
    if pending-charge-limit != null: throw "Charging recovery is still pending"
    bucket_["paused-charge-limit"] = original
    if pending-charge-limit != original: throw "Charge recovery record was not saved"

  clear-charge-limit:
    bucket_["paused-charge-limit"] = null
    if pending-charge-limit != null: throw "Charge recovery record was not cleared"

charge-limit-request limit/int -> protocol.Message:
  data := protocol.Data
  // P1 requires exactly two bytes, including for zero.
  data.add-data-uint16 messages.ChargerSettings.CHARGE-CURRENT-LIMIT limit
  return messages.ChargerSettings.set-msg --base-data=data

set-charge-limit comms limit/int:
  response := (comms.send (charge-limit-request limit) --now=true --withLatch=true --timeout=(Duration --s=5)).get
  if response == null or response == false: throw "Charge settings SET timed out or failed to send"
  if not response.msg-ok: throw "Charge settings SET rejected: status=$(response.msg-status)"

get-charge-limit comms -> int:
  response := (comms.send messages.ChargerSettings.get-msg --now=true --withLatch=true --timeout=(Duration --s=5)).get
  if response == null or response == false: throw "Charge settings GET timed out or failed to send"
  if not response.msg-ok: throw "Charge settings GET rejected: status=$(response.msg-status)"
  if response.type != messages.ChargerSettings.MT or not (response.data.has-data messages.ChargerSettings.CHARGE-CURRENT-LIMIT):
    throw "Charge settings response lacks the current limit"
  return response.data.get-data-uint messages.ChargerSettings.CHARGE-CURRENT-LIMIT
