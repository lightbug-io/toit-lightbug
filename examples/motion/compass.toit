// Computes compass projections and builds the orientation dial graphics.
// Used by acquisition.toit and display.toit in the Compass app.

import math
import motion-fusion show Quaternion Vector3
import lightbug.messages show DrawElement TextPage

PAGE ::= 88

/** Screen top is body -X, screen right +Y, and outward normal +Z.
North is the fusion world's +X. Angles here are display conventions, not
Euler angles in the IMU's native axis order. No declination correction is used.
*/
class Pose:
  roll/float? := null
  pitch/float? := null
  heading/float? := null
  north/float? := null
  status/string := ""
  constructor q/Quaternion magnetic/bool:
    up := q.up
    // Face-up is the useful zero for a handheld compass. At vertical pitch,
    // roll is indeterminate; do not turn tiny gravity errors into a spinning dial.
    side-plane := (up.y * up.y + up.z * up.z).sqrt
    roll = side-plane > 0.15 ? (math.atan2 up.y up.z) : null
    pitch = math.atan2 (-up.x) side-plane
    status = magnetic ? "" : "No magnetic reference"
    if magnetic:
      // Inverse quaternion rotation of world north into the body frame.
      n := Vector3 (1 - 2 * (q.y * q.y + q.z * q.z)) (2 * (q.x * q.y - q.w * q.z)) (2 * (q.x * q.z + q.w * q.y))
      if (n.x * n.x + n.y * n.y).sqrt > 0.15:
        north = math.atan2 n.y (-n.x)
      else:
        status = "Tilt to show north arrow"
      top := q.rotate (Vector3 -1 0 0)
      if (top.x * top.x + top.y * top.y).sqrt > 0.15:
        heading = -(math.atan2 top.y top.x)
        if heading < 0: heading += 2 * math.PI

  mark-stale:
    roll = null
    pitch = null
    heading = null
    north = null
    status = "STALE - waiting for sensors"

  angles -> List: return [north, roll, pitch]
  labels -> List: return ["Bearing $(bearing heading)", "Roll $(degrees roll)", "Pitch $(degrees pitch)"]

degrees angle/float? -> string:
  return angle == null ? "--" : "$((angle * 180 / math.PI).round.to-int) deg"

/** Align world +X with horizontal magnetic north, preserving gravity tilt.
The first accepted reading seeds yaw directly. Later readings blend the shortest
angular correction; the gyro propagates orientation between compass samples.
*/
reference-heading q/Quaternion field/Vector3 weight/float -> Quaternion:
  world := q.rotate field
  angle := -(math.atan2 world.y world.x) * (max 0.0 (min 1.0 weight))
  c := math.cos (angle / 2)
  s := math.sin (angle / 2)
  return Quaternion (c * q.w - s * q.z) (c * q.x - s * q.y) (c * q.y + s * q.x) (c * q.z + s * q.w)

bearing angle/float? -> string:
  return angle == null ? "--" : "$((angle * 180 / math.PI).round.to-int % 360)"

// Initial dials use two strips; live patches cover only changed pixels.
// V3 limits each bitmap field to 255 bytes.
// Row-major bits match RH2 DrawBitMap_Paste: 1 black, 0 white.
DIAL-SIZE ::= 56
DIAL-BACKGROUND := Dial.background
class Dial:
  bits/ByteArray
  constructor.background:
    bits = ByteArray (DIAL-SIZE * DIAL-SIZE / 8)
    x := 25
    y := 0
    error := 1 - x
    while x >= y:
      [[x,y], [y,x], [-y,x], [-x,y], [-x,-y], [-y,-x], [y,-x], [x,-y]].do:
        pixel (28 + it[0]) (28 + it[1])
      y++
      if error < 0:
        error += 2 * y + 1
      else:
        x--
        error += 2 * (y - x) + 1
    line 28 1 28 5

  constructor angle/float? arrow/bool:
    bits = DIAL-BACKGROUND.bits.copy
    if angle != null:
      dx := math.sin angle
      dy := -(math.cos angle)
      tx := 28 + (21 * dx).round.to-int
      ty := 28 + (21 * dy).round.to-int
      line 28 28 tx ty
      if arrow:
        [-1, 1].do: | side |
          line tx ty (tx - (6 * dx + side * 4 * dy).round.to-int)
              (ty - (6 * dy - side * 4 * dx).round.to-int)

  /** Opaque patches include the new white pixels that erase the old needle.
  Byte-aligned X bounds keep packing cheap; all payloads respect V3's limit.
  */
  patches previous/Dial? -> List:
    left := 7
    right := -1
    top := DIAL-SIZE
    bottom := -1
    for index := 0; index < bits.size; index++:
      if previous == null or bits[index] != previous.bits[index]:
        x := index % 7
        y := index / 7
        left = min left x
        right = max right x
        top = min top y
        bottom = max bottom y
    result := []
    if right < left: return result
    stride := right - left + 1
    rows := previous == null ? 28 : 255 / stride
    for y := top; y <= bottom; y += rows:
      height := min rows (bottom - y + 1)
      data := ByteArray (stride * height)
      height.repeat: | row |
        from := (y + row) * 7 + left
        data.replace (row * stride) bits from (from + stride)
      result.add (Patch (left * 8) y (stride * 8) height data)
    return result

  pixel x/int y/int:
    if not 0 <= x < DIAL-SIZE or not 0 <= y < DIAL-SIZE: throw "DIAL_PIXEL_OUTSIDE"
    index := y * 7 + x / 8
    bits[index] = bits[index] | (0x80 >> (x % 8))

  line x/int y/int end-x/int end-y/int:
    dx := (end-x - x).abs
    sx := x < end-x ? 1 : -1
    dy := -(end-y - y).abs
    sy := y < end-y ? 1 : -1
    error := dx + dy
    while true:
      pixel x y
      if x == end-x and y == end-y: break
      twice := 2 * error
      if twice >= dy:
        error += dy
        x += sx
      if twice <= dx:
        error += dx
        y += sy

class Patch:
  x/int
  y/int
  width/int
  height/int
  bits/ByteArray
  constructor .x .y .width .height .bits:

/** A replaceable live snapshot; only changed dials and numbers are sent.
The last successfully drawn image is retained for exact pixel differencing;
failed frames must never become the baseline for the next patch.
*/
class View:
  pose/Pose
  sample-us/int
  dials_/List := [null, null, null]
  constructor .pose .sample-us:

  draw ink/any full/bool previous/View? --on-built/Lambda?=null --on-prepared/Lambda?=null [check]:
    elements := []
    if not full and previous != null: dials_ = previous.dials_.copy
    if full:
      elements.add (DrawElement.data
          --page-id=PAGE
          --status-bar-enable=false
          --redraw-type=DrawElement.REDRAW-TYPE_CLEARDONTDRAW
          --type=DrawElement.TYPE_BOX
          --x=0
          --y=0
          --width=249
          --height=121
          --text="")
      text elements 0 100 249 20 "Top = -X     Middle: apps"
      text elements 1 0 80 20 "North"
    angles := pose.angles
    labels := pose.labels
    old-angles := previous == null ? null : previous.pose.angles
    old-labels := previous == null ? null : previous.pose.labels
    for i := 0; i < 3; i++:
      x := 41 + 83 * i
      if full or old-angles == null or (degrees angles[i]) != (degrees old-angles[i]):
        dial := Dial angles[i] (i == 0)
        old-dial := dials_[i]
        dials_[i] = dial
        (dial.patches old-dial).do: | patch/Patch |
          elements.add (DrawElement.data
              --page-id=PAGE
              --status-bar-enable=false
              --redraw-type=DrawElement.REDRAW-TYPE_BUFFERONLY
              --type=DrawElement.TYPE_BITMAP
              --x=(x - 28 + patch.x)
              --y=(22 + patch.y)
              --width=patch.width
              --height=patch.height
              --bitmap=patch.bits)
      if full or old-labels == null or labels[i] != old-labels[i]:
        text elements (x - 40) 78 80 20 labels[i]
    if full or previous == null or pose.status != previous.pose.status:
      text elements 84 0 165 20 pose.status
    if on-built != null: on-built.call
    if not (ink.draw-elements elements): throw "Compass buffer command was not acknowledged"
    if on-prepared != null: on-prepared.call
    check.call (ink.draw-page
        --page-id=PAGE
        --status-bar-enable=false
        --redraw-type=(full ? TextPage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR : TextPage.REDRAW-TYPE_PARTIALREDRAW))

  text elements/List x/int y/int width/int height/int value/string:
    elements.add (DrawElement.data
        --page-id=PAGE
        --status-bar-enable=false
        --redraw-type=DrawElement.REDRAW-TYPE_BUFFERONLY
        --type=DrawElement.TYPE_BOX
        --x=x
        --y=y
        --width=width
        --height=height
        --fontsize=DrawElement.FONTSIZE_SMALL
        --textalign=DrawElement.TEXTALIGN_MIDDLE
        --padding=0
        --text=value)
