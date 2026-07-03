import lightbug.protocol as protocol

main:
  testBytesAreReusedUntilMutation
  print "message byte cache ok"

testBytesAreReusedUntilMutation:
  msg := protocol.Message.with-data 1234 (protocol.Data)
  msg.data.add-data-string 99 "hello"

  first := msg.bytes-for-protocol
  second := msg.bytes-for-protocol
  assert-same-bytes first second "unchanged message bytes"

  msg.data.add-data-string 98 "world"
  third := msg.bytes-for-protocol
  if third.size <= first.size:
    throw "expected regenerated message to include additional field"
  assert-different-bytes first third "data mutation"

  msg.header-add-data-uint8 protocol.Header.TYPE_MESSAGE_STATUS protocol.Header.STATUS_OK
  fourth := msg.bytes-for-protocol
  assert-different-bytes third fourth "header mutation"

assert-same-bytes a/ByteArray b/ByteArray label/string:
  if a.size != b.size:
    throw "$label size mismatch"
  a.size.repeat: |i|
    if a[i] != b[i]:
      throw "$label differs at $i"

assert-different-bytes a/ByteArray b/ByteArray label/string:
  if a.size != b.size:
    return
  a.size.repeat: |i|
    if a[i] != b[i]:
      return
  throw "$label did not change serialized bytes"
