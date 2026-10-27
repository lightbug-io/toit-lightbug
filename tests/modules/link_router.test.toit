import io
import lightbug.protocol as protocol
import lightbug.messages as messages
import lightbug.modules.comms show Comms
import lightbug.modules.comms.transport show V3Transport
import lightbug.modules.comms.link-router show LinkRouter

class Writer extends io.Writer with io.OutMixin:
  frames /List := []
  try-write_ data/io.Data from/int to/int -> int:
    bytes := ByteArray.from data
    frames.add bytes[from..to]
    return to - from

class Transport implements V3Transport:
  writer := Writer
  prefixed /bool
  constructor .prefixed=false:
  in -> io.Reader: return io.Reader #[]
  out -> io.Writer: return writer
  prefix -> bool: return prefixed
  connected -> bool: return true
  connect:
  disconnect:
  last -> protocol.Message:
    bytes := writer.frames[writer.frames.size - 1]
    return protocol.Message.from-bytes (prefixed ? bytes[2..] : bytes)

link transport/Transport id/int -> Comms:
  return Comms --transport=transport --link-id=id --open=false --startInbound=false

request id/int destination/int -> protocol.Message:
  msg := messages.DeviceIDs.get-msg
  msg.header-add-data-uint32 protocol.Header.TYPE_MESSAGE_ID id
  msg.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO destination
  return msg

reply id/int -> protocol.Message:
  msg := messages.ACK.msg --data=null
  msg.header-add-data-uint32 protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID id
  return msg

main:
  p1-wire := Transport
  usb-wire := Transport
  rs232-wire := Transport true
  p1 := link p1-wire 3
  usb := link usb-wire 7
  rs232 := link rs232-wire 8
  router := LinkRouter --p1=p1
  router.add-link usb
  router.add-link rs232
  local := messages.DeviceIDs.get-msg
  latch := p1.send local --now=true --withLatch=true
  usb.receive-message (request local.msgId 3)
  usb-id := p1-wire.last.msgId
  rs232.receive-message (request local.msgId 3)
  rs232-id := p1-wire.last.msgId
  if usb-id == rs232-id or usb-id == local.msgId or rs232-id == local.msgId:
    throw "Forwarded IDs collide with each other or local tracking"
  p1.receive-message (reply usb-id)
  check "USB response ID restored" usb-wire.last.response-to local.msgId
  check "no RS232 cross-talk" rs232-wire.writer.frames.size 0
  check "local tracker untouched" latch.has-value false
  p1.receive-message (reply usb-id)
  check "later response keeps original correlation" usb-wire.last.response-to local.msgId
  check "later response still isolated" rs232-wire.writer.frames.size 0
  p1.receive-message (reply rs232-id)
  check "RS232 response ID restored" rs232-wire.last.response-to local.msgId
  check "RS232 prefix" rs232-wire.writer.frames[0][..2] #[0x4c, 0x42]
  p1.receive-message (reply local.msgId)
  check "local reply tracked" latch.has-value true

  // An unsolicited cloud command needs no preceding request from the UART.
  cloud := request 42 1
  cloud.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO 8
  cloud.header-add-data-uint8 protocol.Header.TYPE_FORWARDED_FOR 0
  p1.receive-message cloud
  external-id := rs232-wire.last.msgId
  check "both destination hops consumed" (rs232-wire.last.header-has-data protocol.Header.TYPE_FORWARD_TO) false
  rs232.receive-message (reply external-id)
  check "cloud response ID restored" p1-wire.last.response-to 42
  check "reply returns through P1 to cloud" (p1-wire.last.header-get-data-uint protocol.Header.TYPE_FORWARD_TO) 0

  nested := request 43 8
  nested.header-add-data-uint32 protocol.Header.TYPE_FORWARD_TO 700004
  p1.receive-message nested
  check "remaining client hop preserved" (rs232-wire.last.header-get-data-uint protocol.Header.TYPE_FORWARD_TO) 700004

  rs232.receive-message (request 50 0)
  check "P1 must consume cloud hop" (p1-wire.last.header-get-data-uint protocol.Header.TYPE_FORWARD_TO) 0
  check "origin is RS232" (p1-wire.last.header-get-data-uint protocol.Header.TYPE_FORWARDED_FOR) 8
  rs232.receive-message (request 51 99)
  check "unknown route rejected" rs232-wire.last.msg-status protocol.Header.STATUS_NOT_SUPPORTED
  malformed := messages.DeviceIDs.get-msg
  malformed.header-add-data-uint32 protocol.Header.TYPE_MESSAGE_ID 52
  malformed.header-add-data protocol.Header.TYPE_FORWARD_TO #[]
  rs232.receive-message malformed
  check "empty destination rejected" rs232-wire.last.msg-status protocol.Header.STATUS_INVALID_PARAMETER
  print "V3 multi-link routing tests passed"

check label/string actual expected:
  if actual != expected: throw "$label: expected $expected, got $actual"
