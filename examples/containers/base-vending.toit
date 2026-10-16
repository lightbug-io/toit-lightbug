import esp32
import log
import system.storage
import lightbug.devices as devices
import lightbug.cust.vending show Vending
import lightbug.cust.vending_updater show VendingUpdater
import lightbug.cust.vending_buttons show VendingButtons
import lightbug.modules.power show Cpu2Sleep

POLL-EVERY ::= (Duration --s=60)
MIN-RESPONSE-DELAY ::= (Duration --ms=5)
RESPONSE-COUNT ::= 1
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
  // app-start-us := startup-start-us // Development timing temporarily disabled.
  // Deep-sleep wakes should serve their event and return to sleep promptly.
  startup-grace-us := esp32.reset-reason == esp32.RESET-DEEPSLEEP ? 0 : STARTUP-GRACE.in-us
  esp32.ext1-wakeup-status (1 << 7) // Return shared SCL from RTC to I2C use.
  cache := storage.Bucket.open --ram "lightbug/vending"
  cached-id := cache.get "vending-id" --if-absent=(: Vending.VENDING_ID_DEFAULT)
  // Initialise RX/identity before I2C, boot logging, or slow cache requests.
  vending := Vending
      --tx-pin=0
      --rx-pin=19
      --min-response-delay=MIN-RESPONSE-DELAY
      --response-count=RESPONSE-COUNT
      --vending-id=cached-id
  device := devices.I2C
      --background=true
      --open=false
      --startComms=false
      --reinit-on-comms-start=false
  comms := device.comms
  // i2c-ready-us := Time.monotonic-us --since-wakeup
  buttons := VendingButtons cache
  comms.register-handler buttons
  power := Cpu2Sleep comms
  updater := VendingUpdater --logger=(log.default.with-level log.ERROR-LEVEL)

  task --background=true::
    can-sleep := (:: not vending.busy and (Time.monotonic-us --since-wakeup) - vending.last-activity-us >= IDLE-BEFORE-SLEEP-US)
    ready := false
    next-update-us := 0
    // last-report-requests := -1
    // last-report-buttons := -1
    while true:
      error := catch:
        if not ready:
          // OPEN requests retained power before discovery; bounded failures
          // retry this sequence without releasing P1's deep-sleep contract.
          power.start-awake device
              // --app-start-us=app-start-us
              // --uart-ready-us=vending.uart-ready-us
              // --i2c-ready-us=i2c-ready-us
          ready = true
        now-us := Time.monotonic-us --since-wakeup
        if now-us >= next-update-us:
          updater.update-vending-cache-from-device comms vending
          if vending.vending-id != Vending.VENDING_ID_DEFAULT:
            cache["vending-id"] = vending.vending-id
          // Missing identity retries promptly; the UART remains serviced.
          next-update-us = now-us + (vending.vending-id == Vending.VENDING_ID_DEFAULT ? 1_000_000 : POLL-EVERY.in-us)
        // quiet := can-sleep.call
        // if quiet and (last-report-requests != vending.request-count or last-report-buttons != buttons.count):
        //   power.report-timing
        //       --request-count=vending.request-count
        //       --first-request-us=vending.first-request-us
        //       --first-response-us=vending.first-response-us
        //       --first-rx-restored-us=vending.first-rx-restored-us
        //       --tx-flush-to-rx-us=(vending.last-rx-restored-us == null ? null : vending.last-rx-restored-us - vending.last-tx-flushed-us)
        //       --button-count=buttons.count
        //       --last-button-id=buttons.last-button-id
        //       --last-command=vending.last-command
        //   last-report-requests = vending.request-count
        //   last-report-buttons = buttons.count
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
