import lightbug.protocol as protocol

assert-eq-int label/string got/int want/int -> none:
  if got != want:
    throw "$label failed. Got=$got Want=$want"

assert-eq-bytes label/string got/ByteArray want/ByteArray -> none:
  if got != want:
    throw "$label failed. Got=$got Want=$want"

length-from-header bytes/ByteArray -> int:
  return (bytes[2] << 8) + bytes[1]

checksum-from-trailer bytes/ByteArray -> int:
  return (bytes[bytes.size - 1] << 8) + bytes[bytes.size - 2]

validate-built-message label/string message/protocol.Message -> none:
  encoded := message.bytes-for-protocol

  assert-eq-int "$label encoded-size" encoded.size message.size
  assert-eq-int "$label header-length" (length-from-header encoded) encoded.size

  expected-checksum := checksum-from-trailer encoded
  assert-eq-int "$label checksum-calc" (message.checksum-calc) expected-checksum

  reparsed := protocol.Message.from-bytes encoded
  assert-eq-bytes "$label reparse-roundtrip" reparsed.bytes-for-protocol encoded

validate-direct-writer-offset label/string message/protocol.Message -> none:
  encoded := message.bytes-for-protocol
  target := ByteArray encoded.size + 8
  end := message.write-bytes-for-protocol-into target 4
  assert-eq-int "$label write-end" end (4 + encoded.size)

  target[end - 2] = encoded[encoded.size - 2]
  target[end - 1] = encoded[encoded.size - 1]

  assert-eq-bytes "$label direct-write" target[4..end] encoded

validate-parsed-mutation label/string message/protocol.Message -> none:
  encoded := message.bytes-for-protocol
  parsed := protocol.Message.from-bytes encoded

  parsed.header-add-data-uint16 protocol.Header.TYPE-MESSAGE_STATUS protocol.Header.STATUS_FAILED_WILL_RETRY
  parsed.data.add-data-uint32 77 0x12345678

  mutated := parsed.bytes-for-protocol
  reparsed := protocol.Message.from-bytes mutated

  assert-eq-int "$label mutated-status" reparsed.msg-status protocol.Header.STATUS_FAILED_WILL_RETRY
  assert-eq-int "$label mutated-payload" (reparsed.data.get-data-uint32 77) 0x12345678
  assert-eq-int "$label mutated-length" (length-from-header mutated) mutated.size
  assert-eq-int "$label mutated-checksum" (reparsed.checksum-calc) (checksum-from-trailer mutated)

validate-parsed-remove label/string message/protocol.Message -> none:
  encoded := message.bytes-for-protocol
  parsed := protocol.Message.from-bytes encoded

  parsed.header-remove-data protocol.Header.TYPE-MESSAGE_ID
  parsed.data.remove-data 1

  mutated := parsed.bytes-for-protocol
  reparsed := protocol.Message.from-bytes mutated

  assert-eq-int "$label removed-header" (reparsed.header.data.has-data protocol.Header.TYPE-MESSAGE_ID ? 1 : 0) 0
  assert-eq-int "$label removed-payload" (reparsed.data.has-data 1 ? 1 : 0) 0
  assert-eq-int "$label remove-length" (length-from-header mutated) mutated.size
  assert-eq-int "$label remove-checksum" (reparsed.checksum-calc) (checksum-from-trailer mutated)

validate-header-helpers label/string message/protocol.Message -> none:
  parsed := protocol.Message.from-bytes message.bytes-for-protocol

  assert-eq-int "$label helper-has" (parsed.header-has-data protocol.Header.TYPE-MESSAGE_ID ? 1 : 0) 1
  assert-eq-int "$label helper-uint" (parsed.header-get-data-uint protocol.Header.TYPE-MESSAGE_ID) 55
  assert-eq-int "$label helper-uint16" (parsed.header-get-data-uint16 protocol.Header.TYPE-FORWARDED_FOR) 99

  parsed.header-add-data-uint8 protocol.Header.TYPE-MESSAGE_STATUS protocol.Header.STATUS_OK
  parsed.header-add-data-ascii 50 "hdr"
  assert-eq-int "$label helper-status" parsed.msg-status protocol.Header.STATUS_OK
  assert-eq-int "$label helper-ascii-has" (parsed.header-has-data 50 ? 1 : 0) 1

  encoded := parsed.bytes-for-protocol
  reparsed := protocol.Message.from-bytes encoded
  assert-eq-int "$label helper-reparsed-status" reparsed.msg-status protocol.Header.STATUS_OK
  assert-eq-int "$label helper-reparsed-ascii" ((reparsed.header-get-data-ascii 50) == "hdr" ? 1 : 0) 1

main:
  empty := protocol.Message.with-data 0 (protocol.Data)
  validate-built-message "empty" empty
  validate-direct-writer-offset "empty" empty

  header-heavy-data := protocol.Data
  header-heavy-data.add-data-uint8 40 7
  header-heavy-data.add-data-uint16 41 0x4567
  header-heavy-data.add-data-uint32 42 0x89ABCDEF

  header-heavy := protocol.Message.with-method 222 protocol.Header.METHOD-SUBSCRIBE header-heavy-data
  header-heavy.header-add-data-uint32 protocol.Header.TYPE-MESSAGE_ID 34567
  header-heavy.header-add-data-uint16 protocol.Header.TYPE-SUBSCRIPTION_INTERVAL 500
  header-heavy.header-add-data-uint16 protocol.Header.TYPE-SUBSCRIPTION_DURATION 600
  validate-built-message "header-heavy" header-heavy
  validate-direct-writer-offset "header-heavy" header-heavy

  payload := protocol.Data
  payload.add-data-uint8 1 1
  payload.add-data-uint16 2 2
  payload.add-data-uint32 3 3
  payload.add-data 4 #[10, 11, 12, 13, 14, 15, 16]

  mixed := protocol.Message.with-data 19 payload
  mixed.header-add-data-uint32 protocol.Header.TYPE-RESPONSE_TO_MESSAGE_ID 1234567
  mixed.header-add-data-uint16 protocol.Header.TYPE-FORWARDED_FOR 99
  mixed.header-add-data-uint16 protocol.Header.TYPE-MESSAGE_ID 55
  validate-built-message "mixed" mixed
  validate-direct-writer-offset "mixed" mixed
  validate-parsed-mutation "mixed" mixed
  validate-parsed-remove "mixed" mixed
  validate-header-helpers "mixed" mixed

  print "✅ Message build tests passed"
