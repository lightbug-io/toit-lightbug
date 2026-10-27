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
  status /int? := 0
  requests /int := 0
  frames /List := []

  try-write_ data/io.Data from/int to/int -> int:
    requests++
    request := protocol.Message.from-bytes (ByteArray.from data)[from..to]
    frames.add request
    if respond:
      task::
        sleep --ms=5
        payload := protocol.Data
        rejected := status != null and status > 0
        if valid and not rejected: payload.add-data-uint8 10 54
        reply := protocol.Message.with-data (rejected ? 5 : 34) payload
        reply.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request.msgId
        if status != null:
          reply.header-add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS status
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
  test-capability-retry
  test-capability-status
  print "I2C capability tests passed"

test-capability-retry:
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

test-capability-status:
  [null, 5].do: | status |
    device := Device
    transport := Transport
    comms := Comms --transport=transport --open=false
        --handlers=[DeviceDetectionHandler device --logger=log.default]
    device.test-comms = comms
    transport.writer.respond = true
    transport.writer.status = status
    error := catch: device.request-type --timeout=(Duration --ms=100)
    if status == null:
      if error != null or device.type != 54: throw "omitted status rejected"
    else:
      if error == null or device.type-known: throw "capability NACK accepted"
    comms.pause-inbound

