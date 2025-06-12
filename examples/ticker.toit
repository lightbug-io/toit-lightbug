import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
import lightbug.protocol as protocol
import log

/**
A simple application that sets up a Lightbug device and initiate I2C communications with it, then sending a single message in a loop

This is easily buildable into a firmware image.

```sh
cp ~/.cache/jaguar/v2.0.0-alpha.184/envelopes/firmware-esp32c6.envelope ./ticker.envelope
jag toit compile --snapshot -o ticker.snapshot ./ticker.toit
jag toit tool firmware -e ticker.envelope container install ticker ticker.snapshot
```

Which is then flashable via `jag toit tool firmware -e ticker.envelope flash`
*/

main:
  // Setup the Toit logger wiht the debug log level, so you can see lower level I2C operations
  log.set-default (log.default.with-level log.DEBUG-LEVEL)

  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

  // Setup the comms service, which allows communication with the Lightbug device
  comms := services.Comms --device=device

  // Write a message to the device quickly, making it tick
  while true:
    buzz_data := protocol.Data
    buzz-data.add-data-uint messages.BuzzerControl.DURATION 5
    buzz-data.add-data-uint messages.BuzzerControl.FREQUENCY 2
    comms.send (messages.BuzzerControl.do-msg --data=buzz-data) --now=true