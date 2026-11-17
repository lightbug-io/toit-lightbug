// Tests magnetometer calibration fitting and quality checks.
// Run as part of the RH2 motion host test suite.

import math
import motion-fusion show Vector3
import .magnetic-fixture show points
import ...examples.motion.calibration show offer-sample axis-bar
import lis2mdl show Sample
import io.byte-order show LITTLE-ENDIAN
import ...examples.motion.calibration show Capture Correction Quality CalibrationStore MAX-SAMPLES

class Store:
  data/any := null
  writes/int := 0
  fail/bool := false
  get key [--if-absent]: return data == null ? if-absent.call key : data
  operator []= key value:
    if fail: throw "FLASH_UNAVAILABLE"
    writes++
    data = value


main:
  readings := Capture
  bytes := ByteArray 6
  LITTLE-ENDIAN.put-int16 bytes 0 200
  if not (offer-sample readings (Sample bytes true)): throw "Overrun discarded the latest calibration reading"
  LITTLE-ENDIAN.put-int16 bytes 0 32767
  if offer-sample readings (Sample bytes false): throw "Accepted clipped calibration reading"
  readings.add (Vector3 -10 20 30)
  span := readings.spans
  if span.x != 40 or span.y != 20 or span.z != 30: throw "Incorrect displayed axis spans"
  if (axis-bar 0.0) != "-----" or (axis-bar 8.0) != "##---" or (axis-bar 25.0) != "#####": throw "Incorrect axis progress bars"
  capture := Capture
  (points).do: capture.add it
  correction := capture.fit
  if (correction.offset.minus (Vector3 8 -12 5)).length > 1e-8: throw "Hard-iron fit"
  if (correction.scale.minus (Vector3 (1/1.2) (1/0.8) 1)).length > 1e-8: throw "Diagonal scale fit"
  quality := Quality correction
  (points 0.07).do: quality.add it
  if not quality.good or quality.rms-error > 1e-8: throw "Independent sphere check failed"
  checked := capture.fit-checked
  if not checked.good: throw "Held-out consistency check failed"
  // An internally consistent field above 70 uT can be calibrated; the
  // fitted radius is not an absolute Earth-field measurement.
  stronger := Capture
  (points).do: stronger.add (it.scaled 1.7)
  if not stronger.fit-checked.good: throw "Rejected consistent larger field"
  // A large fixed offset puts some valid readings above 200 uT. All
  // orientations must participate in the fit and independent check.
  offset-field := Capture
  (points).do: | v |
    raw-offset := v.plus (Vector3 125 -110 105)
    if not (offset-field.add raw-offset): throw "Rejected an offset-field sample"
  if not (offset-field.samples.any (: it.length > 200)): throw "Fixture lacks high-magnitude readings"
  if not offset-field.fit-checked.good: throw "Rejected consistent offset field"
  // Three ordinary rotation circles cover each signed axis without visiting
  // every octant. Their zero components must not invalidate good calibration.
  circles := Capture
  3.repeat: | plane |
    72.repeat: | i |
      a := 45 * (math.cos (2 * math.PI * i / 72))
      b := 45 * (math.sin (2 * math.PI * i / 72))
      x := plane == 2 ? 0.0 : a
      y := plane == 1 ? 0.0 : (plane == 2 ? a : b)
      z := plane == 0 ? 0.0 : b
      circles.add (Vector3 (8 + 1.2 * x) (-12 + 0.8 * y) (5 + z))
  if not circles.fit-checked.good: throw "Rejected full-axis rotation circles"
  changed-check := Capture
  raw := points
  raw.size.repeat:
    changed-check.add (it % 5 == 0 ? (raw[it].plus (Vector3 30 0 0)) : raw[it])
  if (catch: changed-check.fit-checked) == null: throw "Held-out disturbance was fitted away"
  fuzzy := changed-check.fit-checked --allow-imperfect
  if fuzzy.score >= 100 or fuzzy.score < 0: throw "Fuzzy score did not reflect imperfect fit"
  changed := Quality correction
  (points 0.07).do: changed.add (it.plus (Vector3 30 0 0))
  if changed.good: throw "Accepted changed magnetic environment"
  flat := Capture
  200.repeat:
    flat.add (Vector3 (45 * (math.cos it.to-float)) (45 * (math.sin it.to-float)) 20)
  if (catch: flat.fit) == null: throw "Accepted 2D rotation"
  too-few := Capture
  too-few.add (Vector3 30 0 0)
  if (catch: too-few.fit) == null: throw "Accepted insufficient samples"
  no-coverage := Quality correction
  200.repeat: no-coverage.add (Vector3 62 -12 5)
  if no-coverage.good: throw "Accepted stationary validation"
  skewed := Capture
  (points).do: | v |
    skewed.add (Vector3 (v.x + v.y*0.8) v.y v.z)
  if (catch: skewed.fit) == null: throw "Accepted uncorrectable cross-axis distortion"
  1000.repeat: capture.add (Vector3 30 20 10)
  if capture.samples.size != MAX-SAMPLES: throw "Unbounded calibration capture"
  2.repeat:
    (points).do: capture.add it
  if not capture.fit-checked.good: throw "Extra rotations did not replace an unsuitable capture"
  if capture.add (Vector3 float.NAN 0 0): throw "Accepted nonfinite data"
  correction.quality-score = 37
  restored := Correction.from-record correction.record
  if restored == null or restored.quality-score != 37: throw "Saved quality was lost"
  if restored == null or (restored.apply (Vector3 62 -12 5)).x != 45: throw "Record round trip"
  old := correction.record
  old["version"] = 1
  if (Correction.from-record old) != null: throw "Accepted calibration from previous sensor driver"
  [null, {:}, {"version": 99}, {"version": 1, "offset": [], "scale": [1,1,1], "field": 45}].do:
    if (Correction.from-record it) != null: throw "Accepted corrupt calibration record"
  storage := Store
  cache := CalibrationStore storage
  if cache.load != null: throw "Found nonexistent record"
  cache.save correction
  if storage.writes != 1 or cache.load == null: throw "Calibration not persisted"
  storage.fail = true
  if (catch: cache.save correction) != "FLASH_UNAVAILABLE": throw "Hidden save error"
  if storage.writes != 1: throw "Failed save changed record"
  print "Magnetic fit, coverage, validation, bounds, and persistence tests passed"
