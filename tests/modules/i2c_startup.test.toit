import io
import log
import monitor
import lightbug.devices.i2c-device show I2C DeviceDetectionHandler
import lightbug.modules.comms show Comms
import lightbug.modules.comms.transport show V3Transport
import lightbug.protocol as protocol
import lightbug.messages as messages
import lightbug.modules.comms.link-router show LinkRouter
import lightbug.modules.wifi.handler show WiFiHandler
import lightbug.modules.ble.handler show BLEHandler

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
  set-scanners wifi/WiFiHandler ble/BLEHandler:
    wifi-handler_ = wifi
    ble-handler_ = ble

// Exercise the real I2C Comms factory without opening MCU peripherals.
class HandlerDevice extends I2C:
  wire := Transport
  constructor:
    super --connect-now=false --startComms=false --open=false --reinit-on-comms-start=false
  prefix -> bool: return false
  connected -> bool: return true
  in -> io.Reader: return wire.in
  out -> io.Writer: return wire.out

class SlowWiFi extends WiFiHandler:
  gate := monitor.Latch
  constructor device: super device --logger=log.default
  perform-wifi-scan generation/int duration/int? interval/int id/int? route/int?:
    gate.get

class SlowBLE extends BLEHandler:
  gate := monitor.Latch
  constructor device: super device --logger=log.default
  perform-ble-scan generation/int duration/int? active/bool interval/int window/int reporting/int id/int? route/int?:
    gate.get

main:
  test-capability-retry
  test-capability-status
  test-scan-handler-wiring
  test-scan-sleep-veto
  print "I2C capability and scan handler wiring tests passed"

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

test-scan-handler-wiring:
  // A forwarded unsubscribe safely exercises both real scan handlers on the
  // host. Its ACK must return to cloud, unlike Comms' generic receipt ACK.
  scanning := HandlerDevice
  scan-comms := scanning.comms
  router := LinkRouter --p1=scan-comms
  [messages.WiFiScan.MT, messages.BLEScan.MT].do: | mt |
    before-frames := scanning.wire.writer.frames.size
    request := protocol.Message.with-method mt protocol.Header.METHOD_UNSUBSCRIBE
    request.header-add-data-uint32 protocol.Header.TYPE_MESSAGE_ID mt
    request.header-add-data-uint8 protocol.Header.TYPE_FORWARDED_FOR 0
    if mt == messages.WiFiScan.MT:
      request.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO 1
    scanning.wire.reader.frames.send request.bytes
    with-timeout --ms=200:
      while scanning.wire.writer.frames.size == before-frames: sleep --ms=1
    if scanning.wire.writer.frames.size != before-frames + 1: throw "Duplicate scan acknowledgement"
    ack := scanning.wire.writer.frames[before-frames]
    if ack.type != messages.ACK.MT or ack.response-to != mt or ack.msg-status != 0:
      throw "Scan handler did not acknowledge unsubscribe"
    if not ack.header-has-data protocol.Header.TYPE_FORWARD_TO:
      throw "Scan ACK lost the cloud return route for MT$mt"
    if (ack.header-get-data-uint protocol.Header.TYPE_FORWARD_TO) != 0:
      throw "Scan ACK has the wrong return route"
  scan-comms.pause-inbound

test-scan-sleep-veto:
  device := Device
  transport := Transport
  device.test-comms = Comms --transport=transport --open=false
  wifi := SlowWiFi device
  ble := SlowBLE device
  device.set-scanners wifi ble
  [wifi, ble].do: | handler |
    mt := handler == wifi ? messages.WiFiScan.MT : messages.BLEScan.MT
    request := protocol.Message.with-method mt protocol.Header.METHOD_SUBSCRIBE
    request.header-add-data-uint32 protocol.Header.TYPE_MESSAGE_ID mt
    if handler.scan-active: throw "Scanner active before subscription"
    if not handler.handle-message request or not handler.scan-active or not device.scan-active:
      throw "Scan did not veto sleep while starting"
    handler.gate.set true
    with-timeout --ms=500:
      while handler.scan-active: sleep --ms=1
    if device.scan-active: throw "Finished scan still vetoes sleep"
    handler.gate = monitor.Latch
    if not handler.handle-message request or not handler.scan-active:
      throw "Second scan did not start"
    stop := protocol.Message.with-method mt protocol.Header.METHOD_UNSUBSCRIBE
    handler.handle-message stop
    with-timeout --ms=500:
      while device.scan-active: sleep --ms=1
  wifi.gate = monitor.Latch
  ble.gate = monitor.Latch
  wifi.handle-message (protocol.Message.with-method messages.WiFiScan.MT protocol.Header.METHOD_SUBSCRIBE)
  ble.handle-message (protocol.Message.with-method messages.BLEScan.MT protocol.Header.METHOD_SUBSCRIBE)
  wifi.handle-message (protocol.Message.with-method messages.WiFiScan.MT protocol.Header.METHOD_UNSUBSCRIBE)
  with-timeout --ms=500:
    while wifi.scan-active: sleep --ms=1
  if not device.scan-active: throw "Stopping WiFi released an active BLE scan"
  ble.handle-message (protocol.Message.with-method messages.BLEScan.MT protocol.Header.METHOD_UNSUBSCRIBE)
  with-timeout --ms=500:
    while device.scan-active: sleep --ms=1
  device.test-comms.pause-inbound
