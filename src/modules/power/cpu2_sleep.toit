import esp32
import ...messages show CPU2Sleep ButtonPress Open
import ...protocol as protocol

/** One owner coordinates P1's lease, reader shutdown and P2 deep sleep.
    Other containers/producers must be quiescent before calling deep-sleep. */
class Cpu2Sleep:
  comms_ /any
  wake-message-types_ /List
  timeout_ /Duration
  prepare-timeout_ /Duration
  rejection-retry_ /Duration
  next-prepare-us_ /int := 0

  constructor comms --wake-message-types/List=[38, 48]
      --timeout/Duration=(Duration --s=5)
      --prepare-timeout/Duration=(Duration --ms=500)
      --rejection-retry/Duration=(Duration --s=5):
    comms_ = comms
    wake-message-types_ = wake-message-types
    timeout_ = timeout
    prepare-timeout_ = prepare-timeout
    rejection-retry_ = rejection-retry

  require-ok_ msg/protocol.Message --timeout/Duration?=null -> protocol.Message:
    if timeout == null: timeout = timeout_
    // Bound the write/backoff and reply together, independently of Comms'
    // two-second timeout sweep. A missing boot reply must not stall startup.
    reply := with-timeout timeout:
      (comms_.send msg --now=true --withLatch=true --timeout=timeout).get
    if reply == null: throw "CPU2 sleep request timed out"
    if reply.msg-status == null or reply.msg-status != 0:
      throw "CPU2 sleep request rejected: $(reply.msg-status)"
    return reply

  /** Request retained power before discovery can block. Retrying OPEN is safe
      after a lost ACK; AWAKE still waits until capabilities are available. */
  start-awake device --startup-timeout/Duration=(Duration --s=1):
    require-ok_ (Open.msg --data=null) --timeout=startup-timeout
    comms_.heartbeats.start
    device.request-type --timeout=startup-timeout
    awake

  awake:
    require-ok_ CPU2Sleep.awake-msg
    if wake-message-types_.contains ButtonPress.MT:
      sub := ButtonPress.subscribe-msg
      sub.header-add-data-uint8 15 10 // S_RAM, default subId, no expiry.
      require-ok_ sub

  /** Notify P1 before sleep. Honour a NACK; ACK or silence permits sleep.
      Only an ACK confirms P1 accepted the retention/wake contract. */
  prepare -> bool:
    msg := CPU2Sleep.prepare-deep-sleep-msg --wake-message-types=wake-message-types_
    sent := false
    reply := null
    error := catch:
      with-timeout prepare-timeout_:
        latch := comms_.send msg --now=true --withLatch=true --timeout=prepare-timeout_
        sent = true
        reply = latch.get
    // Silence is permitted only after sending PREPARE. A blocked/failed write
    // aborts the attempt, rather than entering sleep without notifying P1.
    if error and (error != DEADLINE-EXCEEDED-ERROR or not sent): throw error
    return reply == null or reply.msg-status == null or reply.msg-status == 0

  deep-sleep device --duration/Duration=(Duration --h=1)
      --can-sleep/Lambda=(:: true) -> bool:
    // A powered P1 may veto sleep for hours. Leave the reader and heartbeat
    // schedule alone while waiting to ask again; UART work continues normally.
    if Time.monotonic-us < next-prepare-us_: return false
    // Configure before PREPARE: unsupported targets must remain awake.
    configure-wakeup_
    if not can-sleep.call: return false
    heartbeats-were-running := comms_.heartbeats.is-running
    error := catch:
      if not prepare:
        next-prepare-us_ = Time.monotonic-us + rejection-retry_.in-us
        return false
      next-prepare-us_ = 0
      // Preserve normal heartbeats until P1 permits sleep.
      comms_.heartbeats.stop
      comms_.pause-inbound
      if not can-sleep.call:
        comms_.resume-inbound
        awake
        if heartbeats-were-running: comms_.heartbeats.start
        return false
      device.disconnect
      enter-sleep_ duration
    if error:
      try:
        device.connect
        comms_.resume-inbound
        awake
      finally:
        if heartbeats-were-running: comms_.heartbeats.start
      throw error
    return true // deep-sleep does not return on hardware.

  configure-wakeup_:
    esp32.enable-external-wakeup (1 << 7) false

  enter-sleep_ duration/Duration:
    esp32.deep-sleep duration
