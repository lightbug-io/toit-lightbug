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

  request_ msg/protocol.Message --timeout/Duration?=null -> protocol.Message:
    if timeout == null: timeout = timeout_
    // Bound the write/backoff and reply together, independently of Comms'
    // two-second timeout sweep. A missing boot reply must not stall startup.
    reply := with-timeout timeout:
      (comms_.send msg --now=true --withLatch=true --timeout=timeout).get
    if reply == null: throw "CPU2 sleep request timed out"
    return reply

  require-ok_ msg/protocol.Message --timeout/Duration?=null -> protocol.Message:
    reply := request_ msg --timeout=timeout
    if reply.msg-status == null or reply.msg-status != 0:
      throw "CPU2 sleep request rejected: $(reply.msg-status)"
    return reply

  /** Request retained power before discovery can block. Retrying OPEN is safe
      after a lost ACK; AWAKE still waits until capabilities are available. */
  // Timing arguments temporarily disabled:
  // start-awake device --app-start-us/int?=null --uart-ready-us/int?=null
  //     --i2c-ready-us/int?=null --startup-timeout/Duration=(Duration --s=1):
  start-awake device --startup-timeout/Duration=(Duration --s=1):
    require-ok_ (Open.msg --data=null) --timeout=startup-timeout
    comms_.heartbeats.start
    device.request-type --timeout=startup-timeout
    // type-ready-us := app-start-us == null ? null : (Time.monotonic-us --since-wakeup)
    // awake
    //     --app-start-us=app-start-us
    //     --uart-ready-us=uart-ready-us
    //     --i2c-ready-us=i2c-ready-us
    //     --type-ready-us=type-ready-us
    awake

  // awake --app-start-us/int?=null --uart-ready-us/int?=null
  //     --i2c-ready-us/int?=null --type-ready-us/int?=null:
  awake:
    // sent-us := app-start-us == null ? null : (Time.monotonic-us --since-wakeup)
    msg := CPU2Sleep.awake-msg
        // --app-start-us=app-start-us
        // --uart-ready-us=uart-ready-us
        // --awake-sent-us=sent-us
        // --reset-reason=(app-start-us == null ? null : esp32.reset-reason)
        // --wake-cause=(app-start-us == null ? null : esp32.wakeup-cause)
        // --i2c-ready-us=i2c-ready-us
        // --type-ready-us=type-ready-us
    require-ok_ msg
    if wake-message-types_.contains ButtonPress.MT:
      sub := ButtonPress.subscribe-msg
      sub.header-add-data-uint8 15 10 // S_RAM, default subId, no expiry.
      require-ok_ sub

  // Development timing queries/reports are temporarily disabled.
  // wake-timing -> Map:
  //   reply := require-ok_ CPU2Sleep.wake-timing-msg
  //   if reply.type != CPU2Sleep.MT or not (reply.data.has-data CPU2Sleep.WAKE-TIMING):
  //     throw "P1 does not support wake timing"
  //   return (CPU2Sleep.from-data reply.data).wake-timing

  // report-timing --request-count/int --first-request-us/int?=null
  //     --first-response-us/int?=null --first-rx-restored-us/int?=null
  //     --tx-flush-to-rx-us/int?=null --button-count/int=0 --last-button-id/int?=null
  //     --last-command/int?=null:
  //   require-ok_ (CPU2Sleep.report-timing-msg
  //       --request-count=request-count
  //       --first-request-us=first-request-us
  //       --first-response-us=first-response-us
  //       --first-rx-restored-us=first-rx-restored-us
  //       --tx-flush-to-rx-us=tx-flush-to-rx-us
  //       --button-count=button-count
  //       --last-button-id=last-button-id
  //       --last-command=last-command)

  /** Notify P1 before sleep. Honour a NACK; ACK or silence permits sleep.
      Only an ACK confirms P1 accepted the retention/wake contract. */
  prepare -> bool:
    msg := CPU2Sleep.prepare-deep-sleep-msg --wake-message-types=wake-message-types_
    latch := comms_.send msg --now=true --withLatch=true --timeout=prepare-timeout_
    deadline := Time.monotonic-us + prepare-timeout_.in-us
    // Comms sweeps expired requests every two seconds; bound this advisory
    // reply wait independently so silence does not hold up sleep that long.
    while not latch.has-value and Time.monotonic-us < deadline:
      sleep --ms=5
    if not latch.has-value: return true
    reply := latch.get
    // Only an explicit NACK vetoes sleep (InvalidState while P1 is powered).
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
      // Stopping before PREPARE restarted an immediate heartbeat on each NACK.
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
      device.connect
      comms_.resume-inbound
      awake
      if heartbeats-were-running: comms_.heartbeats.start
      throw error
    return true // deep-sleep does not return on hardware.

  configure-wakeup_:
    esp32.enable-external-wakeup (1 << 7) false

  enter-sleep_ duration/Duration:
    esp32.deep-sleep duration
