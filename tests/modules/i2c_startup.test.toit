import io
import log
import monitor
import lightbug.devices.i2c-device show I2C DeviceDetectionHandler
import lightbug.modules.comms show Comms
import lightbug.modules.comms.transport show V3Transport
import lightbug.protocol as protocol

class Reader extends io.Reader with io.InMixin:
  frames := monitor.Channel 8
  read_ -> ByteArray?: return frames.receive

class Writer extends io.Writer with io.OutMixin:
  reader /Reader? := null
  respond /bool := false
  valid /bool := true
  requests /int := 0

  try-write_ data/io.Data from/int to/int -> int:
    requests++
    request := protocol.Message.from-bytes (ByteArray.from data)[from..to]
    if respond:
      task::
        sleep --ms=5
        payload := protocol.Data
        if valid: payload.add-data-uint8 10 54
        reply := protocol.Message.with-data 34 payload
        reply.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request.msgId
        reply.header-add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS 0
        reader.frames.send reply.bytes
    return to - from

class Transport implements V3Transport:
  reader := Reader
  writer := Writer
  constructor:
    writer.reader = reader
  in -> io.Reader: return reader
  out -> io.Writer: return writer
  prefix -> bool: return false
  connected -> bool: return true
  connect:
  disconnect:

class Device extends I2C:
  test-comms /Comms? := null
  constructor:
    super --connect-now=false --startComms=false
  comms -> Comms: return test-comms

main:
  device := Device
  transport := Transport
  comms := Comms --transport=transport --open=false
      --handlers=[DeviceDetectionHandler device --logger=log.default]
  device.test-comms = comms
  start := Time.monotonic-us
  error := catch: device.request-type --timeout=(Duration --ms=30)
  if error == null or Time.monotonic-us - start > 500_000:
    throw "lost capability reply did not time out promptly"
  if device.type-known: throw "silence established a device type"
  transport.writer.respond = true
  transport.writer.valid = false
  error = catch: device.request-type --timeout=(Duration --ms=30)
  if error == null: throw "incomplete capability response accepted"
  transport.writer.valid = true
  device.request-type --timeout=(Duration --ms=30)
  if device.type != 54: throw "capability retry did not restore type"
  device.request-type --timeout=(Duration --ms=30)
  if transport.writer.requests != 3: throw "known type was queried again"
  comms.pause-inbound
  print "I2C capability timeout/retry tests passed"
