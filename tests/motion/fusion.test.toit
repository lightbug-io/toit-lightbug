// Tests fusion and startup gyro calibration.
// Run as part of the RH2 motion host test suite.

import motion-fusion show *
import ...packages.motion-fusion.tests.fusion-test as fusion
import ...examples.motion.acquisition show Calibration

check condition/bool message/string:
  if not condition: throw message

close actual/float expected/float tolerance/float=1e-5:
  if (actual - expected).abs > tolerance: throw "Expected $expected, got $actual"

main:
  fusion.main
  calibration := Calibration
  ready := false
  208.repeat:
    ready = calibration.add (Vector3 0 0 GRAVITY) (Vector3 0.01 -0.02 0.03)
  check ready "Stationary calibration failed"
  close calibration.bias.x 0.01
  calibration = Calibration
  500.repeat:
    ready = calibration.add (Vector3 0 0 (GRAVITY + (it % 2 == 0 ? 1 : -1))) (Vector3 0 0 0)
    check (not ready) "Calibrated while moving"
  // Constant acceleration magnitude and small angular rates can pass the
  // instantaneous gates; their variance must still reject the moving window.
  calibration = Calibration
  208.repeat:
    a := Vector3 (it % 2 == 0 ? 0.2 : -0.2) 0 (GRAVITY*GRAVITY - 0.04).sqrt
    ready = calibration.add a (Vector3 0 0 0)
  check (not ready and calibration.count == 0) "Accepted changing gravity direction"
  208.repeat:
    ready = calibration.add (Vector3 0 0 GRAVITY) (Vector3 (it % 2 == 0 ? 0.03 : -0.03) 0 0)
  check (not ready and calibration.count == 0) "Accepted gyro variance"
  print "Quaternion, mapping, and calibration tests passed"
