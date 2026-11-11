// Defines the demo’s mounting, sampling, logging and app settings.
// Used throughout the RH2 motion example.

import motion-fusion show AxisMap Vector3

// App selection determines which features run. Logging is optional.
LOG-FEATURES ::= true
LOG-DIAGNOSTICS ::= false

// Upright RH2: IMU +X down, +Y right, +Z forward. Body axes initially match it.
// This proper rotation applies to accel, gyro, and the aligned magnetic field.
imu-axes -> AxisMap: return AxisMap 1 2 3

// Upright RH2: LIS2MDL +X down, +Y left, +Z forward. Its native frame is
// left-handed (ST's convention). Correct that before applying imu-axes;
// a Y-only sign change is not an AxisMap rotation or a gyro-axis transform.
magnetic-to-imu field/Vector3 -> Vector3:
  return Vector3 field.x (-field.y) field.z

// The fixed demo profile is shared by integration, analysis and timing. Changing
// it also requires updating Session's hardware ODR and validating FIFO/bus load.
SAMPLE-RATE ::= 104

// Startup calibration requires two quiet seconds, with a 30 second timeout.
CALIBRATION-SAMPLES ::= 2 * SAMPLE-RATE
CALIBRATION-TIMEOUT-US ::= 30_000_000
WARMUP-SAMPLES ::= 2 * SAMPLE-RATE

// Drain moderate backlog; discard only when more than two seconds behind.
MAX-BACKLOG-FRAMES ::= 2 * SAMPLE-RATE

// Menu order and processing profiles share these IDs. Keep Back outside NAMES.
TIME-DOMAIN ::= 0
FREQUENCY-DOMAIN ::= 1
COMPASS ::= 2
NAMES := ["Time domain", "Frequency Domain", "Compass"]

name selected/int -> string:
  if not 0 <= selected < NAMES.size: throw "Unknown motion app"
  return NAMES[selected]
