// Tests shared I2C bus synchronization and transport behavior.
// Run as part of the RH2 motion host test suite.

import lightbug.devices.i2c-device show I2C
import lightbug.devices.fake-device show Fake
import monitor
import log
import serial.device as serial
import serial.registers as serial
import lightbug.devices.i2c as transport

class Device extends I2C:
  constructor:
    super --connect-now=false --startComms=false
    connected_ = true
  // Use the actual transport mutex to model P1's command/sleep/read sequence.
  p1-transaction [action]: return i2c-mutex_.do action

// The existing Lightbug fake has no physical I2C registers. This adapter adds
// the serial interface needed to exercise Writer's real bus-locking behavior.
class BlockedPeer extends Fake implements serial.Device:
  registers_ := BlockedRegisters
  constructor:
    super --open=false --start-inbound=false
  registers -> serial.Registers: return registers_
  read size/int -> ByteArray: throw "Unexpected read"
  write bytes/ByteArray -> none: throw "Unexpected write"

class BlockedRegisters extends serial.Registers:
  ready/bool := false
  polled := monitor.Latch
  written/ByteArray := #[]
  read-bytes command/int size/int -> ByteArray:
    if command != transport.I2C-COMMAND-LIGHTBUG-WRITEABLE_BYTES or size != 2: throw "Unexpected command"
    if not ready: polled.set true
    return ready ? #[8, 0] : #[0, 0]
  write-bytes command/int data/ByteArray -> none:
    if command != transport.I2C-COMMAND-LIGHTBUG-WRITE: throw "Unexpected command"
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
  peer.registers_.polled.get
  with-timeout --ms=40:
    device.with-i2c: peer.registers_.ready = true
  if writer-done.get != 2 or peer.registers_.written != #[2, 12, 34]: throw "Blocked writer failed to resume"
  // Check return values survive the guard and disconnected access is rejected.
  if (device.with-i2c: 42) != 42: throw "Transaction result lost"
  device.connected_ = false
  if (catch: device.with-i2c: 42) == null: throw "Accepted disconnected access"
  print "Shared sensor/V3 transaction guard tests passed"
