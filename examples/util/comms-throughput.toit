/**
Comms throughput profiler.

Measures the real end-to-end throughput of the Comms layer in both directions
using an in-memory loopback device — no I2C or hardware required.

Three phases are timed per message size:
  - RX: a background feeder task streams N serialised messages through a
        channel-backed PipeReader; Comms parses, validates checksums, dispatches
        to handlers, and we count deliveries.
  - TX: N messages are sent via comms.send --now=true into a NullWriter
        (bytes are counted but immediately discarded).
  - MEM: process-stats are captured around each phase so allocation pressure
         per message can be compared.

PipeReader feeds messages in individual message-sized chunks which mirrors the
real I2C framing behaviour and avoids io.InMixin internal-buffer overflow that
occurs when all bytes are dumped at once.
*/

import lightbug.devices as devices
import lightbug.devices.fake-device show FakeReader
import lightbug.modules.comms show Comms
import lightbug.modules.comms.message-handler show MessageHandler
import lightbug.messages.messages_gen as messages
import lightbug.protocol as protocol
import io
import monitor
import system

// ---------------------------------------------------------------------------
//  PipeReader: channel-backed streaming reader.
//  Each push delivers one chunk; read_ blocks until data is available.
// ---------------------------------------------------------------------------

class PipeReader extends io.Reader with io.InMixin:
  channel_ /monitor.Channel

  constructor --capacity/int=256:
    channel_ = monitor.Channel capacity

  push bytes/ByteArray -> none:
    channel_.send bytes

  read_ -> ByteArray?:
    return channel_.receive

// ---------------------------------------------------------------------------
//  NullWriter: discards all bytes but counts them.
// ---------------------------------------------------------------------------

class NullWriter extends io.Writer with io.OutMixin:
  bytes-written_ /int := 0

  try-write_ data/io.Data from/int to/int -> int:
    bytes-written_ += to - from
    return to - from

  bytes-written -> int:
    return bytes-written_

// ---------------------------------------------------------------------------
//  CountingHandler: signals completion when target message count is reached.
// ---------------------------------------------------------------------------

class CountingHandler implements MessageHandler:
  received_ /int := 0
  target_ /int
  done_ /monitor.Latch := monitor.Latch

  constructor .target_:

  handle-message msg/protocol.Message -> bool:
    received_ += 1
    if received_ >= target_:
      e := catch: done_.set true
    return false

  received -> int:
    return received_

  wait -> none:
    done_.get

// ---------------------------------------------------------------------------
//  Helpers
// ---------------------------------------------------------------------------

print-stats label/string stats/List -> none:
  print "$label: bytes-alloc=$(stats[system.STATS-INDEX-BYTES-ALLOCATED-IN-OBJECT-HEAP]) gc=$(stats[system.STATS-INDEX-GC-COUNT]) alloc=$(stats[system.STATS-INDEX-ALLOCATED-MEMORY])"

print-delta label/string before/List after/List -> none:
  print "$label: bytes-alloc-delta=$(after[system.STATS-INDEX-BYTES-ALLOCATED-IN-OBJECT-HEAP] - before[system.STATS-INDEX-BYTES-ALLOCATED-IN-OBJECT-HEAP]) gc-delta=$(after[system.STATS-INDEX-GC-COUNT] - before[system.STATS-INDEX-GC-COUNT]) alloc-delta=$(after[system.STATS-INDEX-ALLOCATED-MEMORY] - before[system.STATS-INDEX-ALLOCATED-MEMORY])"

// ---------------------------------------------------------------------------
//  Main
// ---------------------------------------------------------------------------

main:
  rx-count := 10_000
  tx-count := 10_000

  // Build a typical small message (arm command).
  cmd-data := messages.Command.data --arm-mode=1
  small-msg := messages.Command.set-msg --base-data=cmd-data
  small-bytes := small-msg.bytes-for-protocol

  // Build a larger, realistic message (similar to v3-profile complex message).
  long-string := "x" * 200
  large-d := protocol.Data
  large-d.add-data-string 99 "hello-world-payload"
  large-d.add-data-string 98 "another-field-with-data"
  large-d.add-data-string 97 ("large-binary-chunk" + long-string)
  large-d.add-data-uint32 5 0x12345678
  large-d.add-data-uint16 6 0xABCD
  large-d.add-data-uint8 7 42
  large-msg := protocol.Message.with-data 8766 large-d
  large-msg.header.data.add-data-uint16 protocol.Header.TYPE-FORWARDED_FOR 777
  large-msg.header.data.add-data-uint16 protocol.Header.TYPE-SUBSCRIPTION_INTERVAL 5000
  large-msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
  large-bytes := large-msg.bytes-for-protocol

  print "=== Comms throughput profile ==="
  print "small message: $(small-bytes.size) bytes  large message: $(large-bytes.size) bytes"
  print "rx-count=$rx-count  tx-count=$tx-count"
  print ""

  run-rx-phase "RX small" small-bytes rx-count
  print ""
  run-rx-phase "RX large" large-bytes rx-count
  print ""
  run-tx-phase "TX small" small-msg small-bytes tx-count
  print ""
  run-tx-phase "TX large" large-msg large-bytes tx-count

  // Brief pause lets the scheduler drain background task teardown before exit,
  // preventing spurious UNEXPECTED_END_OF_READER noise in the output.
  sleep --ms=200

// ---------------------------------------------------------------------------
//  RX phase: stream N serialised messages through Comms and count deliveries.
// ---------------------------------------------------------------------------

run-rx-phase label/string msg-bytes/ByteArray count/int -> none:
  print "--- $label ---"
  total-bytes := msg-bytes.size * count

  handler := CountingHandler count
  pipe := PipeReader --capacity=512
  writer := NullWriter

  // open=false so no M11 Open/heartbeat tasks are spawned.
  // reinitOnStart=false so no reinit write happens.
  // background=true so the inbound task and feeder task interleave correctly.
  device := devices.Fake --open=false --in=pipe --out=writer
  comms := Comms
      --device=device
      --handlers=[handler]
      --open=false
      --reinitOnStart=false
      --startInbound=true
      --asyncHandlerDispatch=false
      --yieldBetweenInboundPolls=false
      --inboundYieldEveryMessages=0
      --inboundYieldAtLeastEvery=(Duration --ms=2)
      --background=true

  // Background feeder: push one message-sized chunk at a time.
  task --background=true::
    count.repeat:
      pipe.push msg-bytes

  before := system.process-stats --gc=true
  start-us := Time.monotonic-us

  handler.wait

  elapsed-us := Time.monotonic-us - start-us
  after := system.process-stats --gc=true

  elapsed-ms := elapsed-us / 1000
  msgs-per-sec := count * 1_000_000 / elapsed-us
  bytes-per-sec := total-bytes * 1_000_000 / elapsed-us

  print "  $count messages in $(elapsed-ms) ms"
  print "  throughput:  $msgs-per-sec msgs/sec  |  $bytes-per-sec bytes/sec"
  print "  per-message: $(elapsed-us / count) us"
  print-stats "  before" before
  print-delta "  delta" before after
  print "  received: $(handler.received)"

// ---------------------------------------------------------------------------
//  TX phase: send N messages through Comms (--now=true) to a NullWriter.
// ---------------------------------------------------------------------------

run-tx-phase label/string msg/protocol.Message msg-bytes/ByteArray count/int -> none:
  print "--- $label ---"

  writer := NullWriter
  reader := FakeReader  // no inbound data

  // startInbound=false: no inbound task; we only measure the outbound path.
  device := devices.Fake --open=false --in=reader --out=writer
  comms := Comms
      --device=device
      --open=false
      --reinitOnStart=false
      --startInbound=false
      --asyncHandlerDispatch=false
      --yieldBetweenInboundPolls=false
      --inboundYieldEveryMessages=0
      --inboundYieldAtLeastEvery=(Duration --ms=2)
      --background=false

  before := system.process-stats --gc=true
  start-us := Time.monotonic-us

  count.repeat:
    comms.send msg --now=true

  elapsed-us := Time.monotonic-us - start-us
  after := system.process-stats --gc=true

  total-bytes := writer.bytes-written
  elapsed-ms := elapsed-us / 1000
  msgs-per-sec := count * 1_000_000 / elapsed-us
  bytes-per-sec := total-bytes * 1_000_000 / elapsed-us

  print "  $count messages in $(elapsed-ms) ms"
  print "  throughput:  $msgs-per-sec msgs/sec  |  $bytes-per-sec bytes/sec"
  print "  per-message: $(elapsed-us / count) us"
  print "  bytes written: $total-bytes"
  print-stats "  before" before
  print-delta "  delta" before after
