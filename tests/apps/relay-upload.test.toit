import lightbug.apps.relay-upload show RelayUpload
import lightbug.messages.messages_gen as messages
import lightbug.modules.comms as comms
import lightbug.modules.comms.transport show V3Transport
import lightbug.protocol as protocol
import io
import io.byte-order show LITTLE-ENDIAN
import monitor

check condition/bool label/string:
  if not condition: throw label

location text/string mode/int=RelayUpload.L1 -> protocol.Message?:
  return RelayUpload.location-message text.to-byte-array 42 mode

class TestReader extends io.Reader with io.InMixin:
  read_ -> ByteArray?:
    return null

class TestWriter extends io.Writer with io.OutMixin:
  frames/List := []

  try-write_ data/io.Data from/int to/int -> int:
    frames.add (data as ByteArray)[from..to]
    return to - from

class TestTransport implements V3Transport:
  writer/TestWriter := TestWriter
  in -> io.Reader:
    return TestReader
  out -> io.Writer:
    return writer
  prefix -> bool:
    return false
  connected -> bool:
    return true
  connect -> none:
  disconnect -> none:

test-location:
  msg := location "1234567890:51.507351,-0.127758"
  check (msg != null and msg.type == messages.Position.MT) "ordinary Position"
  check (msg.msgId == null) "fresh ID deferred to Comms"
  check ((msg.header-get-data-uint protocol.Header.TYPE_FORWARDED_FOR) == 1234567890) "full remote uint32 ID"
  check ((msg.header-get-data-uint protocol.Header.TYPE_FORWARD_TO) == protocol.Header.LINK_ID_CHASM) "L1 destination"
  pos := messages.Position.from-data msg.data
  check (pos.latitude-raw == 515073510) "latitude scaled by 1e7"
  check (pos.longitude-raw == -1277580) "longitude scaled by 1e7"
  [messages.Position.TIMESTAMP, messages.Position.TYPE, messages.Position.SOURCE,
      messages.Position.ACCURACY, messages.Position.ALTITUDE].do: |field|
    check (not pos.has-data field) "no fabricated metadata $field"
  [protocol.Header.TYPE_CLIENT_ID, protocol.Header.TYPE_STORAGE_LEVEL,
      protocol.Header.TYPE_MESSAGE_METHOD, protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID,
      protocol.Header.TYPE_MESSAGE_LEVEL, 21, 22, 30].do: |field|
    check (not msg.header-has-data field) "no identity/session/control/publish header $field"
  l2 := location "256:90,-180" RelayUpload.L2
  check ((l2.header-get-data-uint protocol.Header.TYPE_FORWARD_TO) == protocol.Header.LINK_ID_LINK2) "L2 destination"
  max-id := location "4294967295:-90,180"
  check ((max-id.header-get-data-uint protocol.Header.TYPE_FORWARDED_FOR) == 0xffff_ffff) "uint32 upper bound"
  check ((location "0:0,0") != null) "numeric zero identity and geographic origin are not missing values"
  check ((location "9:51.507351,-0.127758" RelayUpload.OFF) == null) "Off"
  check ((location "9:51.507351,-0.127758" 99) == null) "unknown mode"
  check ((RelayUpload.location-message "9:1,2".to-byte-array null RelayUpload.L1) == null) "unknown local identity fails closed"

test-reject:
  [
    "", "9", "9:ping", "9:ping:fsk", "9:pong", "9:pong:sf7",
    "9:ack", "9:listening", "9:hello", "1,2", ":1,2", "-1:1,2",
    "+1:1,2", "1.0:1,2", "1e2:1,2", " 1:1,2", "4294967296:1,2",
    "999999999999999999999999:1,2", "9:1,2:extra", "9:1,2,3",
    "9:nan,0", "9:0,nan", "9:inf,0", "9:0,-inf", "9:90.00001,0",
    "9:0,-180.00001", "9:,", "42:51,-1", "00042:51,-1",
    ("9:" + "1" * 64 + ",0"),
  ].do: |text/string|
    check ((location text) == null) "reject $text"
  check ((RelayUpload.location-message #[0xff, 0xfe, 0x00] 42 RelayUpload.L1) == null) "invalid UTF8"
  // There is no arbitrary V3 replay, even for a valid V3 Position.
  [0, 11, 12, 13, 15, 17, 1004, 65535].do: |kind/int|
    v3 := protocol.Message kind
    v3.header-add-data-uint protocol.Header.TYPE_CLIENT_ID 9
    v3.header-add-data-uint protocol.Header.TYPE_MESSAGE_ID 999
    v3.header-add-data-uint protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_SET
    v3.header-add-data-uint 30 1
    v3.data.add-data-int32 messages.Position.LATITUDE 10000000
    v3.data.add-data-int32 messages.Position.LONGITUDE 20000000
    check ((RelayUpload.location-message v3.bytes 42 RelayUpload.L1) == null) "reject V3/control/encrypted $kind"

test-p1-wire:
  transport := TestTransport
  c := comms.Comms --transport=transport --startInbound=false --open=false
  msg := location "1234567890:51.507351,-0.127758"
  c.send msg --now=true
  first-id := msg.msgId
  c.send (location "1234567890:51.507351,-0.127758") --now=true
  check (transport.writer.frames.size == 2) "two P2 to P1 frames"
  first := protocol.Message.from-bytes transport.writer.frames[0]
  second := protocol.Message.from-bytes transport.writer.frames[1]
  check (first-id != null and first-id != second.msgId) "fresh relay ID per attempt"
  check (not first.header-has-data protocol.Header.TYPE_CLIENT_ID) "P1 supplies identity"
  check (not first.header-has-data protocol.Header.TYPE_STORAGE_LEVEL) "no P1 RAM retry"
  check ((first.header-get-data-uint protocol.Header.TYPE_FORWARDED_FOR) == 1234567890) "wire preserves original sender"
  check ((first.header-get-data-uint protocol.Header.TYPE_FORWARD_TO) == 0) "wire targets L1"
  // Simulate only the documented P1 mutation, not firmware transport behavior.
  first.header-remove-data protocol.Header.TYPE_FORWARD_TO
  first.header-add-data-uint protocol.Header.TYPE_FORWARDED_FOR protocol.Header.LINK_ID_ESP32
  first.header-add-data-uint protocol.Header.TYPE_CLIENT_ID 42
  bytes := first.bytes
  parsed := protocol.Message.from-bytes bytes
  check (parsed.checksum-calc == (LITTLE-ENDIAN.uint16 bytes (bytes.size - 2))) "mutated chain checksum"
  check ((parsed.header-get-data-uint protocol.Header.TYPE_FORWARDED_FOR) == 1234567890) "first repeated origin remains remote"
  // Header type table and length-prefixed raw values retain both occurrences.
  check (bytes[5] == 4 and bytes[6] == 0) "four header fields after P1 mutation"
  check (bytes[7] == 10 and bytes[8] == 1 and bytes[9] == 10 and bytes[10] == 2) "ordered repeated headers"
  check (bytes[11] == 4 and (LITTLE-ENDIAN.uint32 bytes 12) == 1234567890) "large origin encoded as uint32"
  check (bytes[21] == 1 and bytes[22] == 1) "P1 appends local ESP32 hop"

wait-idle upload/RelayUpload:
  with-timeout --ms=5000:
    while upload.busy: sleep --ms=1

test-selection-and-failures:
  calls := []
  release := monitor.Latch
  entered := monitor.Latch
  upload := RelayUpload --send=(:: |msg|
    calls.add msg
    entered.set true
    release.get
    null
  )
  payload := "256:1,2".to-byte-array
  check (upload.mode == RelayUpload.OFF and upload.label == "Off") "default Off"
  check (not upload.receive payload 42) "disabled reception"
  upload.cycle
  check (upload.mode == RelayUpload.L1 and upload.label == "L1") "cycle L1"
  check (upload.receive payload 42) "first accepted"
  entered.get
  check (upload.busy) "send runs independently of receive"
  check (not upload.receive payload 42) "busy drop, no queue"
  upload.cycle
  check (upload.mode == RelayUpload.L2 and upload.label == "L2") "cycle L2"
  check (not upload.receive payload 42) "selection change does not multiply workers"
  release.set true
  wait-idle upload
  check (calls.size == 1) "timeout has no retry"
  check ((calls[0].header-get-data-uint protocol.Header.TYPE_FORWARD_TO) == 0) "in-flight destination unchanged"
  upload.cycle
  check (upload.mode == RelayUpload.OFF) "cycle back to Off"
  upload.select RelayUpload.L1
  check (upload.receive payload 42) "scheduled for cancellation"
  upload.stop
  wait-idle upload
  check (calls.size == 1) "stop before task send cancels it"
  check (not upload.receive payload 42) "stop disables future uploads"

  failure-calls := 0
  failing := RelayUpload --send=(:: |msg|
    failure-calls++
    throw "test P1 write failure"
  )
  failing.select RelayUpload.L2
  2.repeat:
    check (failing.receive payload 42) "retry only on a new received sample"
    wait-idle failing
  check (failure-calls == 2) "send exception contained, capacity released"
  negative := protocol.Message 0
  negative.header-add-data-uint protocol.Header.TYPE_MESSAGE_STATUS protocol.Header.STATUS_NO_DATA
  responses := 0
  rejected := RelayUpload --send=(:: |msg|
    responses++
    negative
  )
  rejected.select RelayUpload.L1
  check (rejected.receive payload 42) "negative response accepted for attempt"
  wait-idle rejected
  check (responses == 1) "NACK does not retry or crash"
  check ((catch: rejected.select 99) != null) "unknown selection rejected"
  check (rejected.mode == RelayUpload.L1) "bad selection preserves mode"

test-blocked-write-deadline:
  bus := monitor.Mutex
  released := false
  upload := RelayUpload --timeout=(Duration --ms=10) --send=(:: |msg|
    bus.do:
      try:
        // Mirrors the yielding wait for P1 I2C write capacity.
        while true: sleep --ms=1
      finally:
        released = true
    null
  )
  upload.select RelayUpload.L1
  check (upload.receive "256:1,2".to-byte-array 42) "blocked writer accepted"
  wait-idle upload
  check released "deadline unwinds writer"
  with-timeout --ms=100:
    bus.do: null
  check (not upload.busy) "deadline frees capacity and bus"

main:
  test-location
  test-reject
  test-p1-wire
  test-selection-and-failures
  test-blocked-write-deadline
  print "Relay upload tests passed"
