import esp32
import log
import system.storage
import lightbug.devices as devices
import lightbug.cust.vending show Vending
import lightbug.cust.vending_updater show VendingUpdater
import lightbug.cust.vending_buttons show VendingButtons
import lightbug.cust.vending_identity show VendingIdentity
import lightbug.modules.power show Cpu2Sleep

// Minimum response delay for each request.
// The first response starts no earlier than this minimum response delay.
// Subsequent responses start at least that duration after the previous transmission started.
// Transmission and UART switching may extend the interval.
// Default is 5 ms; increase to delay responses further if needed.
MIN-RESPONSE-DELAY ::= (Duration --ms=5)

// Response count for each request, including errors (`ERROR\r\n`).
// Default is 1; increase to repeat responses more times if needed.
RESPONSE-COUNT ::= 1

// Polling interval for updates from P1 (the primary processor).
// Each poll updates cached information in the vending container from P1.
// Default is 60 s; increase to poll less frequently if needed.
POLL-EVERY ::= (Duration --s=60)

// This Toit runtime requires a timer; keep missed-pulse recovery infrequent.
RECOVERY-WAKE ::= (Duration --h=1)
// For short recovery tests, replace the line above with:
// RECOVERY-WAKE ::= (Duration --s=60)
STARTUP-GRACE ::= (Duration --s=20)
IDLE-BEFORE-SLEEP-US ::= 500_000

// This container owns P2 sleep. Other containers must agree to whole-chip
// deep sleep before installing it. No REINIT is sent across a sleep wake.
main:
  startup-start-us := Time.monotonic-us --since-wakeup
  // Deep-sleep wakes should serve their event and return to sleep promptly.
  startup-grace-us := esp32.reset-reason == esp32.RESET-DEEPSLEEP ? 0 : STARTUP-GRACE.in-us
  cache := storage.Bucket.open --ram "lightbug/vending"
  identity := VendingIdentity (storage.Bucket.open --flash "lightbug/vending")
  // Restore identity before I2C setup so early kiosk requests use the saved ID.
  vending := Vending
      --tx-pin=0
      --rx-pin=19
      --min-response-delay=MIN-RESPONSE-DELAY
      --response-count=RESPONSE-COUNT
      --vending-id=identity.vending-id
  device := devices.I2C
      --connect-now=false
      --background=true
      --open=false
      --startComms=false
      --reinit-on-comms-start=false
  // Return the configured shared SCL pin from RTC to I2C before opening the bus.
  esp32.ext1-wakeup-status (1 << device.i2c-scl)
  device.connect
  comms := device.comms
  buttons := VendingButtons cache
  comms.register-handler buttons
  power := Cpu2Sleep comms
  updater := VendingUpdater --logger=(log.default.with-level log.ERROR-LEVEL) --identity-cache=identity

  task --background=true::
    can-sleep := (:: not vending.busy and (Time.monotonic-us --since-wakeup) - vending.last-activity-us >= IDLE-BEFORE-SLEEP-US)
    ready := false
    next-update-us := 0
    while true:
      error := catch:
        if not ready:
          // OPEN requests retained power before discovery; bounded failures
          // retry this sequence without releasing P1's deep-sleep contract.
          power.start-awake device
          ready = true
        now-us := Time.monotonic-us --since-wakeup
        if now-us >= next-update-us:
          updater.update-vending-cache-from-device comms vending
          // Missing identity retries promptly; the UART remains serviced.
          next-update-us = now-us + (vending.vending-id == Vending.VENDING_ID_DEFAULT ? 1_000_000 : POLL-EVERY.in-us)
        // Keep Jaguar reachable even when P1 reports no external power.
        grace-complete := (Time.monotonic-us --since-wakeup) - startup-start-us >= startup-grace-us
        if grace-complete and vending.vending-id != Vending.VENDING_ID_DEFAULT:
          power.deep-sleep device --duration=RECOVERY-WAKE --can-sleep=can-sleep
      if error:
        // Setup/teardown errors keep P2 awake; a silent PREPARE is handled above.
        ready = false
        if not vending.busy: log.warn "CPU2 sleep setup/recovery: $error"
      sleep --ms=500

  vending.process-loop
