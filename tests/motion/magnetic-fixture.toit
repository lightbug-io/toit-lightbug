// Generates synthetic magnetic measurements with offsets and scale errors.
// Used by the magnetometer calibration host tests.

import math
import motion-fusion show Vector3

// Full sphere with axis-aligned gain error and an offset, all in native axes.
points phase/float=0.0 -> List:
  result := []
  13.repeat: | latitude |
    pitch := -math.PI / 2 + latitude * math.PI / 12
    24.repeat: | longitude |
      yaw := longitude * math.PI / 12 + phase
      x := 45 * (math.cos pitch) * (math.cos yaw)
      y := 45 * (math.cos pitch) * (math.sin yaw)
      z := 45 * (math.sin pitch)
      result.add (Vector3 (8 + 1.2*x) (-12 + 0.8*y) (5 + z))
  return result
