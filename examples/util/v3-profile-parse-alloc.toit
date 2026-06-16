import io.byte-order show LITTLE-ENDIAN
import lightbug.messages.messages_gen as messages
import lightbug.protocol as protocol
import system

measure-us [block] -> int:
  start := Time.monotonic-us
  block.call
  return Time.monotonic-us - start

print-section section/string before/List after/List elapsed-us/int sink/int -> none:
  print "$section: time-ms=$(elapsed-us / 1000) bytes-allocated-delta=$(after[system.STATS-INDEX-BYTES-ALLOCATED-IN-OBJECT-HEAP] - before[system.STATS-INDEX-BYTES-ALLOCATED-IN-OBJECT-HEAP]) gc-delta=$(after[system.STATS-INDEX-GC-COUNT] - before[system.STATS-INDEX-GC-COUNT]) full-gc-delta=$(after[system.STATS-INDEX-FULL-GC-COUNT] - before[system.STATS-INDEX-FULL-GC-COUNT]) live-allocated-delta=$(after[system.STATS-INDEX-ALLOCATED-MEMORY] - before[system.STATS-INDEX-ALLOCATED-MEMORY]) sink=$sink"

main:
  parse-count := 2_000_000

  cmd-data := messages.Command.data --arm-mode=1
  msg := messages.Command.set-msg --base-data=cmd-data
  msg-bytes := msg.bytes-for-protocol
  parsed-header := protocol.Header.from-bytes msg-bytes[1..]
  data-offset := 1 + parsed-header.size

  print "Parse allocation micro-benchmark"
  print "Input bytes: $msg-bytes"
  print "Parse count: $parse-count"

  sink := 0

  before := system.process-stats --gc=true
  elapsed-us := measure-us:
    parse-count.repeat:
      h-slice := msg-bytes[1..]
      sink += h-slice.size
  after := system.process-stats --gc=true
  print-section "parse:slice-header" before after elapsed-us sink

  before = system.process-stats --gc=true
  elapsed-us = measure-us:
    parse-count.repeat:
      sink += (LITTLE-ENDIAN.uint16 msg-bytes 1) + (LITTLE-ENDIAN.uint16 msg-bytes 3)
  after = system.process-stats --gc=true
  print-section "parse:header-len-type-only" before after elapsed-us sink

  before = system.process-stats --gc=true
  elapsed-us = measure-us:
    parse-count.repeat:
      h := protocol.Header.from-bytes msg-bytes[1..]
      sink += h.size
  after = system.process-stats --gc=true
  print-section "parse:header.from-bytes" before after elapsed-us sink

  before = system.process-stats --gc=true
  elapsed-us = measure-us:
    parse-count.repeat:
      h := protocol.Header.from-bytes-at msg-bytes 1
      sink += h.size
  after = system.process-stats --gc=true
  print-section "parse:header.from-bytes-at" before after elapsed-us sink

  before = system.process-stats --gc=true
  elapsed-us = measure-us:
    parse-count.repeat:
      d-slice := msg-bytes[data-offset..]
      sink += d-slice.size
  after = system.process-stats --gc=true
  print-section "parse:slice-main-data" before after elapsed-us sink

  before = system.process-stats --gc=true
  elapsed-us = measure-us:
    parse-count.repeat:
      d := protocol.Data.from-bytes msg-bytes[data-offset..]
      sink += d.size
  after = system.process-stats --gc=true
  print-section "parse:data.from-bytes" before after elapsed-us sink

  before = system.process-stats --gc=true
  elapsed-us = measure-us:
    parse-count.repeat:
      d := protocol.Data.from-bytes-at msg-bytes data-offset
      sink += d.size
  after = system.process-stats --gc=true
  print-section "parse:data.from-bytes-at" before after elapsed-us sink

  before = system.process-stats --gc=true
  elapsed-us = measure-us:
    parse-count.repeat:
      m := protocol.Message.from-bytes msg-bytes
      sink += m.type
  after = system.process-stats --gc=true
  print-section "parse:message.from-bytes" before after elapsed-us sink

  reusable := protocol.Message.with-data 0 (protocol.Data)
  before = system.process-stats --gc=true
  elapsed-us = measure-us:
    parse-count.repeat:
      reusable.parse-into msg-bytes
      sink += reusable.type
  after = system.process-stats --gc=true
  print-section "parse:message.parse-into(reuse)" before after elapsed-us sink

  print "Final sink: $sink"