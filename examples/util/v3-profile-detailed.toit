import crypto.crc
import lightbug.messages.messages_gen as messages
import lightbug.protocol as protocol
import lightbug.util.profiler as profiler

long-string := ("x" * 200)

make-complex-msg -> protocol.Message:
  d := protocol.Data
  d.add-data-string 99 "hello-world-payload"
  d.add-data-string 98 "another-field-with-data"
  d.add-data-string 97 ("large-binary-chunk" + long-string)
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
  parse-count := 1_000_000

  p := profiler.Profiler

  msg := make-complex-msg
  msg-bytes := msg.bytes-for-protocol
  header-bytes := msg.header.bytes-for-protocol
  data-bytes := msg.data.bytes-for-protocol

  // Keep values alive to avoid dead-code elimination in tight loops.
  checksum-sink := 0
  size-sink := 0
  byte-sink := 0

  // Create-path breakdown.
  p.measure "create:data.bytes-for-protocol":
    count.repeat:
      b := msg.data.bytes-for-protocol
      size-sink += b.size

  p.measure "create:header.bytes-for-protocol":
    count.repeat:
      h := msg.header.bytes-for-protocol
      size-sink += h.size

  p.measure "create:message.bytes-for-protocol":
    count.repeat:
      m := msg.bytes-for-protocol
      byte-sink = m[0]

  p.measure "create:crc16-range":
    count.repeat:
      checksum := crc.Crc16Xmodem
      checksum.add msg-bytes 0 (msg-bytes.byte-size - 2)
      checksum-sink += checksum.get-as-int

  // Parse-path breakdown.
  p.measure "parse:slice-header-bytes":
    parse-count.repeat:
      h-slice := msg-bytes[1..]
      size-sink += h-slice.size

  p.measure "parse:header.from-bytes":
    parse-count.repeat:
      h := protocol.Header.from-bytes msg-bytes[1..]
      size-sink += h.size

  parsed-header := protocol.Header.from-bytes msg-bytes[1..]
  data-offset := 1 + parsed-header.size

  p.measure "parse:slice-main-data":
    parse-count.repeat:
      d-slice := msg-bytes[data-offset..]
      size-sink += d-slice.size

  p.measure "parse:data.from-bytes":
    parse-count.repeat:
      d := protocol.Data.from-bytes msg-bytes[data-offset..]
      size-sink += d.size

  p.measure "parse:message.from-bytes":
    parse-count.repeat:
      parsed := protocol.Message.from-bytes msg-bytes
      byte-sink = parsed.type

  print "Input message bytes: $msg-bytes"
  print "Sinks: checksum=$checksum-sink size=$size-sink byte=$byte-sink"
  print p.report
