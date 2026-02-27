import lightbug.devices as devices
import lightbug.cust.vending show Vending
import lightbug.cust.vending_updater show VendingUpdater

POLL-EVERY ::= (Duration --s=60)

// A basic example of a vending app that listens for UART commands
// and responds with cached temperature/voltage data, which is updated periodically
// from the device using the VendingUpdater.
main:
  device := devices.I2C
    --open=false
    --background=true // So as not to block termination, if the app below fails
    --startComms=true

  comms := device.comms
  vending := Vending --tx-pin=19 --rx-pin=20
  vending-updater := VendingUpdater 

  task --background=true::
    while true:
      vending-updater.update-vending-cache-from-device comms vending
      sleep POLL-EVERY
  
  // Start UART vending processing.
  vending.process-loop
