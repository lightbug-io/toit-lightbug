// Checks quaternion, gravity and magnetic feedback using synthetic inputs.
// Run standalone or through tests/motion/fusion.test.toit.

import math
import motion-fusion show *

check condition/bool message/string:
  if not condition: throw message

close actual/float expected/float tolerance/float=1e-5:
  if (actual - expected).abs > tolerance: throw "Expected $expected, got $actual"

main:
  filter := Fusion
  [Vector3 0 0 GRAVITY, Vector3 0 GRAVITY 0, Vector3 0 0 (-GRAVITY), Vector3 GRAVITY 0 0].do: | a |
    filter.reset a
    linear := filter.linear-acceleration a
    close linear.length 0.0
    up := filter.attitude.up
    close ((up.scaled GRAVITY).minus a).length 0.0
  filter = Fusion
  104.repeat:
    filter.update (Vector3 0 0 0) (Vector3 0 0 (math.PI / 2)) (1.0 / 104)
  rotated := filter.attitude.rotate (Vector3 1 0 0)
  close rotated.x 0.0 0.0001
  close rotated.y 1.0 0.0001
  check (not filter.acceleration-used) "Used zero gravity vector"
  // Gravity feedback must converge with the correct sign.
  filter = Fusion
  600.repeat:
    filter.update (Vector3 0 GRAVITY 0) (Vector3 0 0 0) 0.01
  close (filter.linear-acceleration (Vector3 0 GRAVITY 0)).length 0.0 0.001
  filter.update (Vector3 0 0 (3 * GRAVITY)) (Vector3 0 0 0) 0.01
  check (not filter.acceleration-used) "Trusted impact as tilt"
  filter = Fusion
  filter.attitude = Quaternion 1 0 0 1
  600.repeat:
    filter.update (Vector3 0 0 GRAVITY) (Vector3 0 0 0) 0.01 --magnetic=(Vector3 30 0 10)
  close (filter.attitude.rotate (Vector3 1 0 0)).y 0.0 0.005
  check filter.magnetic-used "Rejected ordinary field"
  filter.update (Vector3 0 0 GRAVITY) (Vector3 0 0 0) 0.01 --magnetic=(Vector3 100 0 0)
  check (not filter.magnetic-used) "Accepted disturbed field strength"
  filter.update (Vector3 0 0 GRAVITY) (Vector3 0 0 0) 0.01 --magnetic=(Vector3 0 0 30)
  check (not filter.magnetic-used) "Accepted degenerate horizontal heading"
  check ((catch: filter.update (Vector3 0 0 GRAVITY) (Vector3 0 0 0) 1.0) != null) "Accepted long dt"
  check ((catch: filter.update (Vector3 float.NAN 0 0) (Vector3 0 0 0) 0.01) != null) "Accepted NaN"
  map := AxisMap 2 -1 3
  v := map.apply (Vector3 1 2 3)
  check (v.x == 2 and v.y == -1 and v.z == 3) "Axis mapping"
  check ((catch: AxisMap 1 1 3) != null) "Duplicate axes"
  check ((catch: AxisMap 1 2 -3) != null) "Left handed mapping"
  print "Quaternion and axis mapping tests passed"
