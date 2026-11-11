// Tests sensor lifecycle, app switching and cleanup.
// Run as part of the RH2 motion host test suite.

import ...examples.motion.settings as mode
import ...examples.motion.session show Session
import ...examples.motion.acquisition show Sampler
import lsm6ds3 as imu
import lis2mdl as compass

class Registers:
  id/int := 0
  writes/List := []
  fail/bool := false
  constructor .id:
  read-reg address/int size/int -> ByteArray:
    if address == 0x0f or address == 0x4f: return ByteArray 1 --initial=id
    return ByteArray size
  write data/ByteArray:
    writes.add data
    if fail: throw "SHUTDOWN_NACK"

class Bus:
  accelerometer := Registers 0x69
  magnetometer := Registers 0x40
  device address/int: return address == imu.ADDRESS-HIGH ? accelerometer : magnetometer

class Device:
  i2c-bus := Bus
  with-i2c [action]: return action.call

class Screen:
  modes/List := []
  resume:
  configure-app selected/int: modes.add selected

class Controls:
  clear:

class Runner extends Sampler:
  profiles/List := []
  fail-app/bool := false
  constructor dev sensor magnetic:
    super dev sensor magnetic
  run:
    if fail-app:
      dev_.i2c-bus.accelerometer.fail = true
      throw "APP_FAILED"
    profiles.add [spectrum-enabled_, autocorrelation-enabled_, peaks-enabled_, compass-enabled_]
    calibrated_ = true

class TestSession extends Session:
  setups/int := 0
  constructor dev screen controls:
    super dev screen controls
  create-sampler_ -> Sampler:
    setups++
    return Runner dev_ imu_ mag_

main:
  dev := Device
  screen := Screen
  session := TestSession dev screen (Controls)
  if session.setups != 0 or not dev.i2c-bus.accelerometer.writes.is-empty or not dev.i2c-bus.magnetometer.writes.is-empty:
    throw "Constructing the menu session started sensors or calibration"
  if (catch: session.run -1) == null or session.setups != 0:
    throw "Invalid app initialized hardware or calibration"
  session.run mode.TIME-DOMAIN
  runner := session.sampler_ as Runner
  bias := runner.bias_
  session.run mode.FREQUENCY-DOMAIN
  if session.setups != 1 or runner.bias_ != bias or not runner.calibrated_:
    throw "Switching apps repeated startup calibration"
  session.run mode.COMPASS
  if runner.profiles != [[false, true, true, false], [true, false, false, false], [false, false, false, true]]: throw "App processing profiles"
  if dev.i2c-bus.magnetometer.writes.last != #[0x60, 0x02]: throw "Compass stayed active in menu"
  if dev.i2c-bus.accelerometer.writes.last != #[0x11, 0]: throw "IMU stayed active in menu"
  runner.fail-app = true
  stops-before := dev.i2c-bus.magnetometer.writes.size
  if (catch: session.run mode.TIME-DOMAIN) != "APP_FAILED": throw "Cleanup hid the original app error"
  if dev.i2c-bus.magnetometer.writes.size <= stops-before or dev.i2c-bus.magnetometer.writes.last != #[0x60, 0x02]:
    throw "IMU shutdown failure prevented magnetic shutdown"
  broken := Device
  broken.i2c-bus.magnetometer.id = 0
  partial := TestSession broken (Screen) (Controls)
  if (catch: partial.run mode.TIME-DOMAIN) != "LIS2MDL_ID_MISMATCH": throw "Lost initialization error"
  if broken.i2c-bus.accelerometer.writes.last != #[0x11, 0] or broken.i2c-bus.magnetometer.writes.last != #[0x60, 2]:
    throw "Partial initialization skipped sensor cleanup"
  print "Motion session shared calibration, profile switching, and sensor cleanup tests passed"
