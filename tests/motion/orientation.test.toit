// Tests RH2 sensor frame mapping and orientation conventions.
// Run as part of the RH2 motion host test suite.

import motion-fusion show AxisMap Fusion Vector3 GRAVITY
import ...examples.motion.settings as settings

close actual/Vector3 expected/Vector3:
  if (actual.minus expected).length > 1e-8: throw "RH2 axis mapping mismatch"

main:
  // Raw LIS2MDL unit fields along down, left, and forward, expressed in IMU
  // axes (down, right, forward). This is a handedness conversion, not rotation.
  close (settings.magnetic-to-imu (Vector3 1 0 0)) (Vector3 1 0 0)
  close (settings.magnetic-to-imu (Vector3 0 1 0)) (Vector3 0 -1 0)
  close (settings.magnetic-to-imu (Vector3 0 0 1)) (Vector3 0 0 1)
  expected := Vector3 15 30 45
  native := Vector3 15 -30 45
  close (settings.imu-axes.apply (settings.magnetic-to-imu native)) expected
  // Both streams must receive the same mounting rotation AFTER alignment.
  mounting := AxisMap 2 -1 3
  close (mounting.apply (settings.magnetic-to-imu native)) (mounting.apply expected)
  if (catch: AxisMap 1 -2 3) == null: throw "Accepted reflection as gyro rotation"
  // Upright RH2 gravity is -X in the IMU frame, while fusion's world up is +Z.
  filter := Fusion
  stationary := settings.imu-axes.apply (Vector3 (-GRAVITY) 0 0)
  filter.reset stationary
  close (filter.attitude.rotate stationary) (Vector3 0 0 GRAVITY)
  close (filter.linear-acceleration stationary) (Vector3 0 0 0)
  print "RH2 handedness, mounting, and upright gravity tests passed"
