// Demonstrates tilt initialization and gravity removal using motion-fusion.

import motion-fusion show Fusion Vector3 GRAVITY

// Host example: the device's +Y axis points up while it is stationary.
main:
  filter := Fusion
  acceleration := Vector3 0 GRAVITY 0
  filter.reset acceleration
  filter.update acceleration (Vector3 0 0 0) 0.01
  q := filter.attitude
  linear := filter.linear-acceleration acceleration
  print "body-to-world quaternion w,x,y,z: $(q.w),$(q.x),$(q.y),$(q.z)"
  print "world linear acceleration m/s^2: $(linear.x),$(linear.y),$(linear.z)"
