// Tests compass geometry, display behavior and sampling.
// Run as part of the RH2 motion host test suite.

import ...examples.motion.settings as mode
import math
import io.byte-order show LITTLE-ENDIAN
import lsm6ds3 as imu
import lis2mdl as mag
import ...examples.motion.acquisition show Sampler
import motion-fusion show Quaternion Vector3 Fusion GRAVITY
import lightbug.messages show DrawElement TextPage
import ...examples.motion.compass as compass
import ...examples.motion.display show Screen

check value/bool message/string:
  if not value: throw message

near actual/float? expected/float:
  check (actual != null and (actual - expected).abs < 1e-6) "Compass axis/sign convention"

class Reply:
  msg-ok/bool := true

class Ink:
  elements/List := []
  refreshes/List := []
  failure/string? := null
  batch --important [action] -> bool:
    action.call
    return true
  draw-element --page-id --status-bar-enable --redraw-type --type --x --y
      --width=null --height=null --style=null --fontsize=null --textalign=null --text=null --x2=null --y2=null --bitmap=null --padding=null:
    if failure != null: throw failure
    check (page-id == compass.PAGE and not status-bar-enable) "Wrong compass canvas"
    check (0 <= x <= 248 and 0 <= y <= 121) "Element outside canvas"
    if x2 != null: check (0 <= x2 <= 248 and 0 <= y2 <= 121) "Needle outside canvas"
    if type == DrawElement.TYPE_BITMAP:
      check (bitmap.size <= 255 and bitmap.size == (width / 8) * height and y + height <= 80) "Dial payload or layout"
    if text != null and text != "": check (y + height <= 120 and height >= 20) "Text cropped by firmware font bounds"
    elements.add [type, x, y, x2, y2, redraw-type, text]
    return Reply
  draw-elements elements/List -> bool:
    elements.do: | data |
      draw-element
          --page-id=(data.get-data-uint DrawElement.PAGE-ID)
          --status-bar-enable=false
          --redraw-type=(data.get-data-uint DrawElement.REDRAW-TYPE)
          --type=(data.get-data-uint DrawElement.TYPE)
          --x=(data.get-data-uint DrawElement.X)
          --y=(data.get-data-uint DrawElement.Y)
          --width=(optional data DrawElement.WIDTH)
          --height=(optional data DrawElement.HEIGHT)
          --text=(data.has-data DrawElement.TEXT ? (data.get-data-ascii DrawElement.TEXT) : null)
          --bitmap=(data.has-data DrawElement.BITMAP ? (data.get-data DrawElement.BITMAP) : null)
    return true
  optional data field:
    return data.has-data field ? (data.get-data-uint field) : null
  draw-page --page-id --status-bar-enable --redraw-type:
    refreshes.add redraw-type
    return Reply

class LiveScreen extends Screen:
  updates/int := 0
  magnetic/bool := true
  constructor: super null
  compass-results q/Quaternion valid/bool sample-us/int:
    updates++
    magnetic = valid

main:
  // With the top edge facing magnetic north, yaw must seed immediately even
  // when the gravity-only quaternion starts with arbitrary world yaw.
  q := compass.reference-heading (Quaternion 1 0 0 0) (Vector3 -40 0 20) 1.0
  near (compass.Pose q true).north 0.0
  check ((compass.bearing (compass.Pose q true).heading) == "0") "North bearing wrap"
  tilted := Quaternion 0.7 0.2 -0.3 0.5
  aligned := compass.reference-heading tilted (Vector3 -30 12 15) 1.0
  check ((aligned.up.minus tilted.up).length < 1e-6) "Heading alignment changed tilt"
  field := aligned.rotate (Vector3 -30 12 15)
  check (field.x > 0 and field.y.abs < 1e-6) "Magnetic north not world +X"
  // Every angle stays within the small dial payload, including arrowheads.
  360.repeat: | i | compass.Dial (i * math.PI / 180) true
  flat := compass.Pose (Quaternion 1 0 0 0) true
  near flat.north math.PI
  near flat.heading math.PI
  near flat.pitch 0.0
  near flat.roll 0.0
  east := compass.Pose (Quaternion 1 0 0 1) true
  near east.north (-math.PI / 2)
  near east.heading (math.PI / 2)
  north := compass.Pose (Quaternion 0 0 0 1) true
  near north.north 0.0
  near north.heading 0.0
  upright := compass.Pose (Quaternion 1 0 1 0) true
  check (upright.roll == null) "Vertical pitch roll singularity"
  near upright.pitch (math.PI / 2)
  check (upright.heading == null and upright.north == null) "Upright/projection singularities"
  unavailable := compass.Pose (Quaternion 1 0 0 0) false
  check (unavailable.heading == null and unavailable.north == null) "Unreferenced north shown"
  // Independent physical poses: tilt the top edge around +Y and the side
  // edge around +X, deriving attitude from gravity rather than Euler formulas.
  [-60, -30, 0, 30, 60].do: | degrees/int |
    angle := degrees * math.PI / 180
    filter := Fusion
    filter.reset (Vector3 (-(math.sin angle) * GRAVITY) 0 ((math.cos angle) * GRAVITY))
    pose := compass.Pose filter.attitude false
    near pose.pitch angle
    near pose.roll 0.0
    filter.reset (Vector3 0 ((math.sin angle) * GRAVITY) ((math.cos angle) * GRAVITY))
    pose = compass.Pose filter.attitude false
    near pose.roll angle
    near pose.pitch 0.0
  background := compass.DIAL-BACKGROUND.bits.copy
  // Reconstruct every pixel after incremental updates through a complete turn.
  previous := compass.Dial 0.0 true
  360.repeat: | degree/int |
    next := compass.Dial (degree * math.PI / 180) true
    reconstructed := previous.bits.copy
    (next.patches previous).do: | patch/compass.Patch |
      check (patch.bits.size <= 255) "Patch exceeds V3 field limit"
      stride := patch.width / 8
      patch.height.repeat: | row |
        reconstructed.replace ((patch.y + row) * 7 + patch.x / 8) patch.bits (row * stride) ((row + 1) * stride)
    check (reconstructed == next.bits) "Needle patch left stale pixels or damaged ring"
    previous = next
  check (compass.DIAL-BACKGROUND.bits == background) "A needle modified the shared dial background"
  ink := Ink
  screen := Screen ink
  screen.compass-results (Quaternion 1 0 0 0) true Time.monotonic-us
  screen.draw-pending_
  check (ink.refreshes == [TextPage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR]) "Compass initial clear/refresh"
  count := ink.elements.size
  screen.next-draw-us_ = 0
  screen.compass-results (Quaternion 1 0 0 0) true Time.monotonic-us
  screen.draw-pending_
  check (ink.elements.size == count and ink.refreshes.size == 1) "Unchanged compass retransmitted dials"
  screen.next-draw-us_ = 0
  screen.compass-results (Quaternion 1 0 0 1) true Time.monotonic-us
  screen.draw-pending_
  check (ink.refreshes.last == TextPage.REDRAW-TYPE_PARTIALREDRAW) "Compass live refresh not partial"
  check (ink.elements.size - count == 2) "A heading change should send one needle patch and one label"
  check ((ink.elements[count..].every (: it[5] == DrawElement.REDRAW-TYPE_BUFFERONLY))) "Live compass cleared whole canvas"
  screen.next-draw-us_ = 0
  screen.compass-results (Quaternion 1 0 0 0) true (Time.monotonic-us - 3_000_000)
  screen.draw-pending_
  check (ink.elements.last[6].contains "STALE") "Stale north remained live"
  ink.failure = "REJECTED_DRAW"
  screen.next-draw-us_ = 0
  screen.compass-results (Quaternion 1 0 0 0) true Time.monotonic-us
  error := catch: screen.draw-pending_
  check (error != null and error.to-string.contains "REJECTED_DRAW") "Compass hid underlying draw failure"
  live := LiveScreen
  sampler := Sampler null (imu.Driver null) (mag.Driver null) --screen=live
  sampler.configure-app mode.COMPASS
  sampler.calibrated_ = true
  sampler.prepare-run
  raw := ByteArray 12
  LITTLE-ENDIAN.put-int16 raw 6 -4098
  sample := imu.Sample raw 0
  256.repeat: sampler.consume_ sample null
  check (live.updates == 1 and not live.magnetic) "Live compass cadence or missing heading"
  check (sampler.window_.count == 0 and sampler.ready_.size == 0) "Compass built analysis windows"
  sampler.next-compass-us_ = 0
  sampler.consume_ sample null
  check (live.updates == 2) "Compass waited for a motion window"
  // Sparse 10 Hz magnetic updates must not require many seconds of IMU-rate
  // integration before the first north reference is correct.
  flat-raw := ByteArray 12
  LITTLE-ENDIAN.put-int16 flat-raw 10 4098
  sampler.fusion_.reset (Vector3 0 0 9.80665)
  sampler.consume_ (imu.Sample flat-raw 0) (Vector3 -40 0 20)
  near (compass.Pose sampler.fusion_.attitude true).north 0.0
  print "Compass projection, tilt, missing heading, incremental rendering and staleness tests passed"
