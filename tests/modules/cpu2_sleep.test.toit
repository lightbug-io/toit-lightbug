import monitor
import lightbug.protocol as protocol
import lightbug.messages show CPU2Sleep ButtonPress
import lightbug.modules.power show Cpu2Sleep
import lightbug.cust.vending_buttons show VendingButtons

assert-equals actual expected:
  if actual != expected: throw "expected $expected, got $actual"

class Heartbeats:
  is-running := true
  stops /int := 0
  starts /int := 0
  stop:
    stops++
    is-running = false
  start:
    starts++
    is-running = true

class Comms:
  sent /List := []
  trace /List := []
  heartbeats := Heartbeats
  reject /bool := false
  timeout /bool := false
  paused /bool := false
  charging /bool := false
  external-power /bool := false
  delayed-reject /bool := false
  drop-open-count /int := 0
  block-open /bool := false
  reject-open /bool := false
  block-prepare /bool := false
  drop-awake /bool := false

  send msg/protocol.Message --now/bool --withLatch/bool --timeout/Duration:
    sent.add msg
    data := protocol.Data
    reply := protocol.Message.with-data 5 data
    status := 0
    if msg.type == 11:
      trace.add "open"
      if block-open: sleep --ms=60_000 // Exercise a stalled transport write.
      if drop-open-count > 0:
        drop-open-count--
        return monitor.Latch
      if reject-open: status = 5
    if msg.type == 47 and (msg.data.get-data-uint 11) == 1:
      trace.add "prepare"
      if block-prepare: sleep --ms=60_000
      if reject or charging or external-power: status = 5 // InvalidState.
      if this.timeout:
        return monitor.Latch // Genuine silence, not an already expired request.
    else if msg.type == 47:
      trace.add "awake"
      if drop-awake: return monitor.Latch
    reply.header-add-data-uint8 4 status
    latch := monitor.Latch
    if delayed-reject:
      task::
        sleep --ms=5
        latch.set reply
      return latch
    latch.set reply
    return latch

  pause-inbound:
    trace.add "pause"
    paused = true

  resume-inbound:
    trace.add "resume"
    paused = false

class Device:
  trace /List
  connected /bool := true
  fail-close /bool := false
  fail-type /bool := false

  constructor .trace:

  request-type --timeout/Duration:
    trace.add "type"
    if fail-type:
      with-timeout timeout: (monitor.Latch).get

  disconnect:
    trace.add "disconnect"
    connected = false
    if fail-close: throw "close failed"

  connect:
    trace.add "connect"
    connected = true

class Sleep extends Cpu2Sleep:
  trace /List
  entered /bool := false

  constructor comms/Comms --rejection-retry/Duration=(Duration --s=5):
    trace = comms.trace
    super comms --timeout=(Duration --ms=30) --prepare-timeout=(Duration --ms=30) --rejection-retry=rejection-retry

  configure-wakeup_:
    trace.add "configure"

  enter-sleep_ duration/Duration:
    trace.add "enter"
    entered = true

test-wire:
  msg := CPU2Sleep.prepare-deep-sleep-msg
  parsed := protocol.Message.from-bytes msg.bytes
  assert-equals parsed.type 47
  assert-equals (parsed.header-get-data-uint 5) 1
  assert-equals (parsed.data.get-data 3) #[38, 0, 48, 0]
  assert-equals (parsed.data.get-data-uint 11) 1
  assert-equals (parsed.data.get-data-uint 12) 0
  msg = CPU2Sleep.awake-msg
  parsed = protocol.Message.from-bytes msg.bytes
  assert-equals parsed.type CPU2Sleep.MT
  assert-equals (parsed.header-get-data-uint 5) 1
  assert-equals (parsed.data.get-data-uint CPU2Sleep.SLEEP-TRANSITION) CPU2Sleep.AWAKE
  error := catch: CPU2Sleep.prepare-deep-sleep-msg --wake-message-types=[]
  if error == null: throw "empty wake selection accepted"

test-setup:
  comms := Comms
  sleep := Cpu2Sleep comms
  sleep.awake
  assert-equals comms.sent.size 2
  assert-equals comms.sent[1].type ButtonPress.MT
  assert-equals (comms.sent[1].header-get-data-uint 15) 10
  assert-equals (comms.sent[1].header-has-data 7) false

test-startup:
  // Lost OPEN ACK, stalled write and lost capability reply must all be bounded.
  ["open-reply", "open-write", "type-reply", "open-nack"].do: | failure |
    comms := Comms
    comms.heartbeats.is-running = false
    comms.drop-open-count = failure == "open-reply" ? 1 : 0
    comms.block-open = failure == "open-write"
    comms.reject-open = failure == "open-nack"
    device := Device comms.trace
    device.fail-type = failure == "type-reply"
    sleep := Cpu2Sleep comms
    start := Time.monotonic-us
    error := catch:
      sleep.start-awake device --startup-timeout=(Duration --ms=30)
    if error == null: throw "startup ignored $failure"
    if Time.monotonic-us - start > 500_000: throw "startup blocked on $failure"
    assert-equals comms.sent[0].type 11
    assert-equals comms.sent.size 1 // No AWAKE before successful discovery.
    assert-equals comms.heartbeats.is-running (failure == "type-reply")
    // Retry the complete handshake after the transient fault clears.
    comms.block-open = false
    comms.reject-open = false
    device.fail-type = false
    sleep.start-awake device --startup-timeout=(Duration --ms=30)
    assert-equals comms.sent[1].type 11
    assert-equals (comms.sent[2].data.get-data-uint 11) 0
    assert-equals comms.sent[3].type ButtonPress.MT
    assert-equals comms.heartbeats.is-running true
    assert-equals device.connected true

test-lifecycle:
  comms := Comms
  device := Device comms.trace
  sleep := Sleep comms
  assert-equals (sleep.deep-sleep device) true
  expected := ["configure", "prepare", "pause", "disconnect", "enter"]
  expected.size.repeat: | index |
    assert-equals comms.trace[index] expected[index]
  assert-equals comms.sent.size 1 // PREPARE only; no Power Info query.
  assert-equals device.connected false
  assert-equals comms.heartbeats.stops 1

test-rejection:
  comms := Comms
  comms.reject = true
  device := Device comms.trace
  sleep := Sleep comms
  assert-equals (sleep.deep-sleep device) false
  assert-equals comms.paused false
  assert-equals device.connected true
  assert-equals sleep.entered false
  assert-equals comms.heartbeats.is-running true
  assert-equals comms.heartbeats.stops 0
  assert-equals comms.heartbeats.starts 0

test-rejection-retry:
  comms := Comms
  comms.reject = true
  device := Device comms.trace
  coordinator := Sleep comms --rejection-retry=(Duration --s=1)
  assert-equals (coordinator.deep-sleep device) false
  10.repeat:
    assert-equals (coordinator.deep-sleep device) false
  assert-equals comms.sent.size 1 // Calls during the cooldown do no I2C work.
  assert-equals comms.heartbeats.stops 0
  assert-equals comms.heartbeats.starts 0
  assert-equals comms.paused false
  assert-equals device.connected true
  // P1 permits sleep after removal; the next attempt succeeds when due.
  comms.reject = false
  sleep --ms=1010
  assert-equals (coordinator.deep-sleep device) true
  assert-equals comms.sent.size 2
  assert-equals coordinator.entered true
  assert-equals comms.heartbeats.stops 1

test-race:
  comms := Comms
  device := Device comms.trace
  sleep := Sleep comms
  checks := 0
  allowed := (:: checks++; checks == 1)
  assert-equals (sleep.deep-sleep device --can-sleep=allowed) false
  assert-equals comms.paused false
  assert-equals device.connected true
  assert-equals sleep.entered false
  assert-equals (comms.sent[1].data.get-data-uint 11) 0

test-recovery:
  comms := Comms
  device := Device comms.trace
  device.fail-close = true
  sleep := Sleep comms
  error := catch: sleep.deep-sleep device
  assert-equals error "close failed"
  assert-equals device.connected true
  assert-equals comms.paused false
  assert-equals sleep.entered false
  assert-equals (comms.sent[1].data.get-data-uint 11) 0

test-recovery-without-awake-reply:
  comms := Comms
  comms.drop-awake = true
  device := Device comms.trace
  device.fail-close = true
  coordinator := Sleep comms
  error := catch: coordinator.deep-sleep device
  if error == null: throw "failed recovery was not reported"
  assert-equals device.connected true
  assert-equals comms.paused false
  assert-equals comms.heartbeats.is-running true
  assert-equals coordinator.entered false

test-silence:
  comms := Comms
  comms.timeout = true
  device := Device comms.trace
  sleep := Sleep comms
  start := Time.monotonic-us
  assert-equals (sleep.deep-sleep device) true
  elapsed := Time.monotonic-us - start
  if elapsed < 30_000 or elapsed > 500_000: throw "reply wait was not bounded: $elapsed us"
  assert-equals sleep.entered true
  assert-equals device.connected false

test-blocked-prepare:
  comms := Comms
  comms.block-prepare = true
  device := Device comms.trace
  coordinator := Sleep comms
  start := Time.monotonic-us
  error := catch: coordinator.deep-sleep device
  if error == null or Time.monotonic-us - start > 500_000:
    throw "blocked PREPARE write did not abort promptly"
  assert-equals coordinator.entered false
  assert-equals device.connected true
  assert-equals comms.paused false
  assert-equals comms.heartbeats.is-running true
  assert-equals comms.sent[1].type CPU2Sleep.MT
  assert-equals (comms.sent[1].data.get-data-uint CPU2Sleep.SLEEP-TRANSITION) CPU2Sleep.AWAKE

test-delayed-nack:
  comms := Comms
  comms.reject = true
  comms.delayed-reject = true
  device := Device comms.trace
  sleep := Sleep comms
  assert-equals (sleep.deep-sleep device) false
  assert-equals sleep.entered false
  assert-equals device.connected true
  assert-equals comms.heartbeats.is-running true
  assert-equals comms.heartbeats.stops 0
  assert-equals comms.heartbeats.starts 0

test-power:
  [[true, false], [false, true]].do: | state |
    comms := Comms
    comms.charging = state[0]
    comms.external-power = state[1]
    device := Device comms.trace
    sleep := Sleep comms
    assert-equals (sleep.deep-sleep device) false
    assert-equals sleep.entered false
    assert-equals comms.paused false
    assert-equals device.connected true
    assert-equals comms.sent.size 1
    assert-equals comms.sent[0].type CPU2Sleep.MT

test-buttons:
  store := {:}
  buttons := VendingButtons store
  [10, 10, 11].do: | sequence |
    data := ButtonPress.data --button-id=0 --duration=123
    data.add-data-uint32 5 sequence
    msg := protocol.Message.with-data 38 data
    assert-equals (buttons.handle-message msg) false
  assert-equals buttons.last-button-id 0
  assert-equals buttons.last-duration-ms 123
  assert-equals store["last-button-sequence"] 11
  duplicate := ButtonPress.data --button-id=1 --duration=456
  duplicate.add-data-uint32 5 11
  buttons.handle-message (protocol.Message.with-data 38 duplicate)
  assert-equals buttons.last-button-id 0
  assert-equals buttons.last-duration-ms 123
  // Recreate the handler to simulate a new process after deep sleep.
  resumed := VendingButtons store
  data := ButtonPress.data --button-id=0 --duration=123
  data.add-data-uint32 5 11
  resumed.handle-message (protocol.Message.with-data 38 data)
  assert-equals resumed.last-button-id null
  assert-equals resumed.last-duration-ms null

main:
  test-wire
  test-setup
  test-startup
  test-lifecycle
  test-rejection
  test-rejection-retry
  test-race
  test-recovery
  test-recovery-without-awake-reply
  test-silence
  test-delayed-nack
  test-blocked-prepare
  test-power
  test-buttons
  print "CPU2 sleep protocol/lifecycle/button tests passed"
