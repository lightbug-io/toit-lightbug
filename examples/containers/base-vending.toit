import esp32
import log
import system.storage
import lightbug.devices as devices
import lightbug.cust.vending show Vending
import lightbug.cust.vending_updater show VendingUpdater
import lightbug.cust.vending_buttons show VendingButtons
import lightbug.cust.vending_identity show VendingIdentity
import lightbug.modules.power show Cpu2Sleep
import lightbug.modules.comms.mixed-serial show MixedSerial
import lightbug.modules.comms.link-router show LinkRouter
import lightbug.modules.comms.usb-console show UsbConsole ConsoleDeviceStatusHandler

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
// A host keeps a QC session awake with V3 traffic/heartbeats. An abandoned
// session releases its sleep veto after this lease, rather than staying on.
V3-IDLE-LEASE-US ::= 60_000_000

// This container owns P2 sleep. Other containers must agree to whole-chip
// deep sleep before installing it. No REINIT is sent across a sleep wake.
main:
  startup-start-us := Time.monotonic-us --since-wakeup
  // Deep-sleep wakes should serve their event and return to sleep promptly.
  startup-grace-us := esp32.reset-reason == esp32.RESET-DEEPSLEEP ? 0 : STARTUP-GRACE.in-us
  cache := storage.Bucket.open --ram "lightbug/vending"
  identity := VendingIdentity (storage.Bucket.open --flash "lightbug/vending")
  serial := MixedSerial --tx-pin=0 --rx-pin=19
  // Restore identity before I2C setup so early kiosk requests use the saved ID.
  vending := Vending
      --tx-pin=0
      --rx-pin=19
      --min-response-delay=MIN-RESPONSE-DELAY
      --response-count=RESPONSE-COUNT
      --vending-id=identity.vending-id
      --transmit=(:: | frame | serial.transmit frame)
  device := devices.I2C
      --connect-now=false
      --background=true
      --open=false
      --startComms=false
      --reinit-on-comms-start=false
      --with-default-handlers=false
  // Return the configured shared SCL pin from RTC to I2C before opening the bus.
  esp32.ext1-wakeup-status (1 << device.i2c-scl)
  device.connect
  comms := device.comms
  router := LinkRouter --p1=comms
  router.add-link serial.comms
  serial.comms.register-handler (ConsoleDeviceStatusHandler serial.comms log.default)
  // USB and RS232 have separate V3 identities and share the single P1 link.
  usb := UsbConsole --startInbound=false
  router.add-link usb.comms
  usb.comms.resume-inbound
  buttons := VendingButtons cache
  comms.register-handler buttons
  power := Cpu2Sleep comms
  updater := VendingUpdater --logger=(log.default.with-level log.ERROR-LEVEL) --identity-cache=identity

  task --background=true::
    can-sleep := ::
      now-us := Time.monotonic-us --since-wakeup
      rs232-idle := serial.comms.last-activity-us == 0 or now-us - serial.comms.last-activity-us >= V3-IDLE-LEASE-US
      usb-idle := usb.comms.last-activity-us == 0 or now-us - usb.comms.last-activity-us >= V3-IDLE-LEASE-US
      not vending.busy and not serial.busy and rs232-idle and usb-idle and now-us - serial.last-receive-us >= IDLE-BEFORE-SLEEP-US and now-us - serial.last-activity-us >= IDLE-BEFORE-SLEEP-US
    ready := false
    next-setup-us := 0
    next-update-us := 0
    while true:
      now-us := Time.monotonic-us --since-wakeup
      if not ready and now-us >= next-setup-us:
        setup-error := catch:
          power.start-awake device
          ready = true
        if setup-error:
          // Older P1 firmware can reject the sleep contract. Keep serving
          // vending/cache requests while leaving deep sleep disabled.
          next-setup-us = (Time.monotonic-us --since-wakeup) + 5_000_000
          log.warn "CPU2 sleep setup/recovery: $setup-error"
      error := catch:
        now-us = Time.monotonic-us --since-wakeup
        if now-us >= next-update-us:
          updater.update-vending-cache-from-device comms vending
          // Missing identity retries promptly; the UART remains serviced.
          next-update-us = now-us + (vending.vending-id == Vending.VENDING_ID_DEFAULT ? 1_000_000 : POLL-EVERY.in-us)
        // Keep Jaguar reachable even when P1 reports no external power.
        grace-complete := (Time.monotonic-us --since-wakeup) - startup-start-us >= startup-grace-us
        if ready and grace-complete and vending.vending-id != Vending.VENDING_ID_DEFAULT:
          power.deep-sleep device --duration=RECOVERY-WAKE --can-sleep=can-sleep
      if error:
        // Setup/teardown errors keep P2 awake; a silent PREPARE is handled above.
        ready = false
        if not vending.busy: log.warn "CPU2 sleep setup/recovery: $error"
      sleep --ms=500

  serial.run: | frame started-us |
    vending.handle-frame frame started-us
