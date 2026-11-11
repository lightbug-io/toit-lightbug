// Provides quaternion attitude estimation and coordinate helpers.
// Used by the package example and RH2 motion processing.

import math

GRAVITY ::= 9.80665

/** Immutable vector. All sensor inputs must use the same right-handed frame. */
class Vector3:
  x/float ::= ?
  y/float ::= ?
  z/float ::= ?
  constructor x/num y/num z/num:
    this.x = x.to-float
    this.y = y.to-float
    this.z = z.to-float
  length -> float: return (x * x + y * y + z * z).sqrt
  finite -> bool: return x.is-finite and y.is-finite and z.is-finite
  scaled k/num -> Vector3: return Vector3 (x * k) (y * k) (z * k)
  plus v/Vector3 -> Vector3: return Vector3 (x + v.x) (y + v.y) (z + v.z)
  minus v/Vector3 -> Vector3: return Vector3 (x - v.x) (y - v.y) (z - v.z)
  cross v/Vector3 -> Vector3:
    return Vector3 (y * v.z - z * v.y) (z * v.x - x * v.z) (x * v.y - y * v.x)

/**
A signed axis permutation: e.g. (2, -1, 3) maps (x,y,z) to (y,-x,z).
Only proper rotations are accepted, so gyro and vector cross products agree.
*/
class AxisMap:
  axes_/List
  constructor x/int y/int z/int:
    axes_ = [x, y, z]
    if not axes_.every (: 1 <= it.abs <= 3): throw "INVALID_AXES"
    if x.abs == y.abs or y.abs == z.abs or x.abs == z.abs: throw "INVALID_AXES"
    inversions := 0
    if x.abs > y.abs: inversions++
    if x.abs > z.abs: inversions++
    if y.abs > z.abs: inversions++
    sign := x.sign * y.sign * z.sign
    if (inversions % 2 == 0 ? sign : -sign) != 1: throw "LEFT_HANDED_AXES"
  apply v/Vector3 -> Vector3:
    if axes_[0] == 1 and axes_[1] == 2 and axes_[2] == 3: return v
    return Vector3 (component_ v axes_[0]) (component_ v axes_[1]) (component_ v axes_[2])

  component_ v/Vector3 axis/int -> float:
    value := axis.abs == 1 ? v.x : (axis.abs == 2 ? v.y : v.z)
    return axis < 0 ? -value : value

/** Unit Hamilton quaternion (w,x,y,z), rotating body vectors into world axes. */
class Quaternion:
  w/float ::= ?
  x/float ::= ?
  y/float ::= ?
  z/float ::= ?
  constructor w/num x/num y/num z/num:
    norm := (w * w + x * x + y * y + z * z).sqrt
    if not norm.is-finite or norm < 1e-12: throw "INVALID_QUATERNION"
    this.w = w / norm
    this.x = x / norm
    this.y = y / norm
    this.z = z / norm
  /** Rotates $v from body to world. */
  rotate v/Vector3 -> Vector3:
    // Scalar intermediates avoid temporary vectors in the 104 Hz hot path.
    tx := 2 * (y * v.z - z * v.y)
    ty := 2 * (z * v.x - x * v.z)
    tz := 2 * (x * v.y - y * v.x)
    return Vector3 (v.x + w * tx + y * tz - z * ty)
        (v.y + w * ty + z * tx - x * tz)
        (v.z + w * tz + x * ty - y * tx)
  /** World +Z expressed in the body frame. */
  up -> Vector3:
    return Vector3 (2 * (x * z - w * y)) (2 * (y * z + w * x)) (1 - 2 * (x * x + y * y))

/**
Quaternion complementary filter with proportional gravity and optional heading
  feedback. Gyro is rad/s, acceleration m/s^2, magnetic field microtesla, dt seconds.
World +Z is up; yaw is arbitrary without a calibrated magnetometer. There is no
  automatic gyro bias learning: calibrate while stationary before calling update.
*/
class Fusion:
  attitude/Quaternion := Quaternion 1 0 0 0
  acceleration-used/bool := false
  magnetic-used/bool := false
  gravity-gain_/float
  heading-gain_/float

  constructor --gravity-gain/float=2.0 --heading-gain/float=1.0:
    if not gravity-gain.is-finite or gravity-gain < 0 or
        not heading-gain.is-finite or heading-gain < 0: throw "INVALID_GAIN"
    gravity-gain_ = gravity-gain
    heading-gain_ = heading-gain

  /** Seeds tilt from a stationary accelerometer; yaw remains arbitrary. */
  reset acceleration/Vector3:
    if not acceleration.finite or acceleration.length < 1e-6: throw "INVALID_ACCELERATION"
    a := acceleration.scaled (1 / acceleration.length)
    attitude = a.z < -0.999999 ? (Quaternion 0 1 0 0) : (Quaternion (1 + a.z) a.y (-a.x) 0)
    acceleration-used = false
    magnetic-used = false

  update acceleration/Vector3 gyro/Vector3 dt/float --magnetic/Vector3?=null -> Quaternion:
    if not acceleration.finite or not gyro.finite: throw "INVALID_SENSOR_DATA"
    if not dt.is-finite or not 0 < dt <= 0.1: throw "INVALID_DT"
    omega := gyro
    acceleration-length := acceleration.length
    acceleration-used = (acceleration-length - GRAVITY).abs <= 0.15 * GRAVITY
    if acceleration-used:
      measured-up := acceleration.scaled (1 / acceleration-length)
      error := measured-up.cross attitude.up
      omega = omega.plus (error.scaled gravity-gain_)
    magnetic-used = false
    if magnetic != null and magnetic.finite and 20 <= magnetic.length <= 70:
      world := attitude.rotate magnetic
      // A nearly vertical field does not constrain yaw.
      if (world.x * world.x + world.y * world.y).sqrt > 5:
        heading-error := math.atan2 world.y world.x
        omega = omega.plus (attitude.up.scaled (-heading-gain_ * heading-error))
        magnetic-used = true
    q := attitude
    half-dt := dt * 0.5
    attitude = Quaternion
        (q.w + (-q.x * omega.x - q.y * omega.y - q.z * omega.z) * half-dt)
        (q.x + (q.w * omega.x + q.y * omega.z - q.z * omega.y) * half-dt)
        (q.y + (q.w * omega.y - q.x * omega.z + q.z * omega.x) * half-dt)
        (q.z + (q.w * omega.z + q.x * omega.y - q.y * omega.x) * half-dt)
    return attitude

  /** Specific force rotated into world axes, with stationary +g removed. */
  linear-acceleration acceleration/Vector3 -> Vector3:
    world := attitude.rotate acceleration
    return Vector3 world.x world.y (world.z - GRAVITY)
