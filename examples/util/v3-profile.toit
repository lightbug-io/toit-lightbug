import lightbug.messages.messages_gen as messages
import lightbug.protocol as protocol
import system

long-string := ("x" * 200)

make-complex-msg -> protocol.Message:
  d := protocol.Data
  d.add-data-string 99 "hello-world-payload"
  d.add-data-string 98 "another-field-with-data"
  d.add-data-string 97 "large-binary-chunk" + long-string  // 218 bytes
  d.add-data-uint32 5 0x12345678
  d.add-data-uint16 6 0xABCD
  d.add-data-uint8 7 42

  m := protocol.Message.with-data 8766 d
  m.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID 999999
  m.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID 888888
  m.header.data.add-data-uint16 protocol.Header.TYPE-FORWARDED_FOR 777
  m.header.data.add-data-uint16 protocol.Header.TYPE-SUBSCRIPTION_INTERVAL 5000
  m.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
  return m

main:
  count := 1_000_000

  // Make bytes with complex realistic message
  b := null
  start := Time.monotonic-us
  count.repeat: | i |
    b = (make-complex-msg).bytes-for-protocol
  end := Time.monotonic-us
  print "Time to create $(count) complex messages: $((end - start) / 1000) ms"
  print "Last message bytes size: $(b.size)"


  // Parse a message
  m := null
  start = Time.monotonic-us
  count.repeat: | i |
    m = protocol.Message.from-bytes b
  end = Time.monotonic-us
  print "Time to parse $(count) complex messages: $((end - start) / 1000) ms"
  print "Last message: $m"