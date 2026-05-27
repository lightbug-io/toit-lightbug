import log
import lightbug.devices as devices
import lightbug.cust.vending show Vending
import lightbug.cust.vending_updater show VendingUpdater

POLL-EVERY ::= (Duration --s=60)
MIN-RESPONSE-DELAY ::= (Duration --ms=500)

// A basic example of a vending app that listens for UART commands
// and responds with cached temperature/voltage data, which is updated periodically
// from the device using the VendingUpdater.
main:
  device := devices.I2C
    --background=true // So as not to block termination, if the app below fails
    --open=false
    --startComms=false
    --connect-now=false // We'll manage connection manually

  real-pin := 19

  comms := device.comms
  vending := Vending --tx-pin=0 --rx-pin=real-pin --min-response-delay=MIN-RESPONSE-DELAY
  vending-updater := VendingUpdater 

  task --background=true::
    while true:
      log.debug "Starting vending update cycle"
      // We only open the I2C bus to avoid low level timing and delay issues during the vending commands
      device.connect
      vending-updater.update-vending-cache-from-device comms vending
      device.disconnect
      sleep POLL-EVERY
  
  // Start UART vending processing.
  vending.process-loop
