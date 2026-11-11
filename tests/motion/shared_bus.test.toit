// Tests shared I2C bus synchronization and transport behavior.
// Run as part of the RH2 motion host test suite.

import lightbug.devices.i2c-device show I2C
import monitor
import log
import lightbug.devices.i2c as transport

class Device extends I2C:
  constructor:
    super --connect-now=false --startComms=false
    connected_ = true
  // Use the actual transport mutex to model P1's command/sleep/read sequence.
  p1-transaction [action]: return i2c-mutex_.do action

class BlockedPeer:
  ready/bool := false
  polled := monitor.Latch
  written/ByteArray := #[]
  write-read command/ByteArray size/int -> ByteArray:
    if command[0] != transport.I2C-COMMAND-LIGHTBUG-WRITEABLE_BYTES or size != 2: throw "Unexpected command"
    if not ready: polled.set true
    return ready ? #[8, 0] : #[0, 0]
  write-address command/ByteArray data/ByteArray:
    written = data

main:
  device := Device
  entered := monitor.Latch
  finished := monitor.Latch
  events := []
  task::
    device.p1-transaction:
      events.add "p1-command"
      entered.set true
      sleep --ms=10
      events.add "p1-data"
    finished.set true
  entered.get
  device.with-i2c: events.add "sensor"
  finished.get
  if events != ["p1-command", "p1-data", "sensor"]: throw "Sensor interleaved P1 sequence"
  error := catch:
    device.with-i2c: throw "I2C_NACK"
  if error != "I2C_NACK": throw "Transaction error swallowed"
  device.with-i2c: events.add "recovered"
  // A full P1 receive buffer must not hold the bus while the writer waits.
  peer := BlockedPeer
  writer := transport.Writer peer device.i2c-mutex_ --logger=log.default
  writer-done := monitor.Latch
  task:: writer-done.set (writer.try-write_ #[12, 34] 0 2)
  peer.polled.get
  with-timeout --ms=40:
    device.with-i2c: peer.ready = true
  if writer-done.get != 2 or peer.written != #[2, 12, 34]: throw "Blocked writer failed to resume"
  // Check return values survive the guard and disconnected access is rejected.
  if (device.with-i2c: 42) != 42: throw "Transaction result lost"
  device.connected_ = false
  if (catch: device.with-i2c: 42) == null: throw "Accepted disconnected access"
  print "Shared sensor/V3 transaction guard tests passed"
