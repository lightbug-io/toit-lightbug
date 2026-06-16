import lightbug.protocol as protocol

assert-eq-bytes label/string got/ByteArray want/ByteArray -> none:
  if got != want:
    if got.size != want.size:
      throw "$label failed. Size mismatch Got=$(got.size) Want=$(want.size). Got=$got Want=$want"
    for i := 0; i < got.size; i++:
      if got[i] != want[i]:
        throw "$label failed at index $i. Got=$(got[i]) Want=$(want[i]). Got=$got Want=$want"
    throw "$label failed. Byte arrays differ. Got=$got Want=$want"

assert-eq-int label/string got/int want/int -> none:
  if got != want:
    throw "$label failed. Got=$got Want=$want"

checksum-from-trailer bytes/ByteArray -> int:
  return (bytes[bytes.size - 1] << 8) + bytes[bytes.size - 2]

make-msg-a -> protocol.Message:
  d := protocol.Data
  d.add-data-uint8 1 42
  m := protocol.Message.with-method 17 protocol.Header.METHOD-SET d
  return m

make-msg-b -> protocol.Message:
  d := protocol.Data
  d.add-data-uint16 2 0x1234
  d.add-data-uint32 3 0x87654321
  m := protocol.Message.with-data 33 d
  m.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE_TO_MESSAGE_ID 123456
  return m

validate-roundtrip label/string bytes/ByteArray -> none:
  m := protocol.Message.from-bytes bytes

  // Validate checksum before forcing data materialization.
  got-csum := m.checksum-calc
  want-csum := checksum-from-trailer bytes
  assert-eq-int "$label checksum-calc(lazy)" got-csum want-csum

  // Validate re-encoding.
  reencoded := m.bytes-for-protocol
  assert-eq-bytes "$label from-bytes->bytes-for-protocol" reencoded bytes

  // Validate checksum after materialization too.
  materialized := m.data
  got-csum-2 := m.checksum-calc
  assert-eq-int "$label checksum-calc(materialized)" got-csum-2 want-csum

  // Validate clone path.
  clone := protocol.Message.from-message m
  clone-bytes := clone.bytes-for-protocol
  assert-eq-bytes "$label from-message->bytes-for-protocol" clone-bytes bytes

main:
  // Existing known-good fixture from Message.test.
  fixture-list := [0x03, 0x28, 0x00, 0x05, 0x00, 0x04, 0x00, 0x03, 0x04, 0x01, 0x02, 0x04, 0xe0, 0x7e, 0x7e, 0x87, 0x01, 0x00, 0x04, 0x58, 0x00, 0x00, 0x00, 0x08, 0x56, 0x99, 0x93, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x02, 0x0b, 0x00, 0xc9, 0x35]
  fixture := ByteArray fixture-list.size
  for i := 0; i < fixture-list.size; i++:
    fixture[i] = fixture-list[i]

  validate-roundtrip "fixture" fixture

  msg-a := make-msg-a
  bytes-a := msg-a.bytes-for-protocol
  validate-roundtrip "msg-a" bytes-a

  msg-b := make-msg-b
  bytes-b := msg-b.bytes-for-protocol
  validate-roundtrip "msg-b" bytes-b

  // Reuse-path regression guard: parse different shapes into same instance.
  reusable := protocol.Message.with-data 0 (protocol.Data)
  reusable.parse-into bytes-a
  assert-eq-bytes "reusable parse-into a" reusable.bytes-for-protocol bytes-a
  reusable.parse-into bytes-b
  assert-eq-bytes "reusable parse-into b" reusable.bytes-for-protocol bytes-b
  reusable.parse-into fixture
  assert-eq-bytes "reusable parse-into fixture" reusable.bytes-for-protocol fixture

  print "✅ Message roundtrip regression tests passed"