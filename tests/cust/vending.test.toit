import io
import lightbug.cust.vending show Vending
import lightbug.cust.vending_protocol show VendingProtocol

class RecordingWriter extends io.Writer with io.OutMixin:
  frames /List := []
  times /List := []

  try-write_ data/io.Data from/int to/int -> int:
    bytes := data is ByteArray ? data : ByteArray.from data
    frames.add bytes[from..to]
    times.add (Time.monotonic-us --since-wakeup)
    return to - from

class RecordingPort:
  out := RecordingWriter

class TestVending extends Vending:
  recording-port := RecordingPort
  rx-count /int := 0
  tx-count /int := 0

  constructor --response-count/int=1 --delay/Duration=(Duration --ms=100):
    super --rx-pin=19 --tx-pin=0 --response-count=response-count --min-response-delay=delay

  set-port-rx:
    port = recording-port
    rx-count++

  set-port-tx:
    tx-count++

  start-request -> int:
    _last-request-start-us = Time.monotonic-us --since-wakeup
    return _last-request-start-us

assert-equals label/string actual expected:
  if actual != expected:
    throw "$label: expected $expected, got $actual"

assert-transmissions vending/TestVending frame/ByteArray count/int start-us/int delay-us/int:
  writer := vending.recording-port.out
  assert-equals "response count" writer.frames.size count
  assert-equals "TX switches" vending.tx-count count
  assert-equals "RX restored after every response" vending.rx-count (count + 1)
  previous-us := start-us
  count.repeat: | i |
    assert-equals "response bytes" writer.frames[i] frame
    if writer.times[i] - previous-us < delay-us:
      throw "response $i sent before minimum delay"
    previous-us = writer.times[i]

main:
  request := VendingProtocol.build-command-frame VendingProtocol.Cmd_GetStat
  payload := VendingProtocol.command-payload-from-frame request
  if payload == null:
    throw "invalid test request"
  expected := VendingProtocol.response-for-command-frame request Vending.VENDING_ID_DEFAULT 20 3.7
  if expected == null:
    throw "missing test response"

  vending := TestVending --response-count=3
  start-us := vending.start-request
  vending.process-command payload
  assert-transmissions vending expected 3 start-us 100_000

  single := TestVending
  start-us = single.start-request
  single.process-command payload
  assert-transmissions single expected 1 start-us 100_000

  errors := TestVending --response-count=3
  start-us = errors.start-request
  errors.process-command #[0xa2, 0x00]
  assert-transmissions errors "ERROR\r\n".to-byte-array 3 start-us 100_000

  immediate := TestVending --response-count=3 --delay=(Duration --ms=0)
  start-us = immediate.start-request
  immediate.process-command payload
  assert-transmissions immediate expected 3 start-us 0

  unsupported := TestVending --response-count=3
  unsupported.process-command #[0xa1, 0x9b]
  assert-equals "unsupported command ignored" unsupported.recording-port.out.frames.size 0

  [0, -1].do: | count |
    error := catch:
      TestVending --response-count=count
    assert-equals "invalid count rejected" error "response-count must be at least 1"

  print "vending response tests passed"
