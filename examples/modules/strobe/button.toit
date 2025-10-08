import lightbug.devices as devices
import lightbug.messages.messages_gen as messages
import log

/**
A simple example demonstrating the new buttons module with error handling.

This example shows the synchronous subscription pattern with proper error handling.
*/
main:
  device := devices.I2C --background=false

  // Subscribe to button presses with error handling.
  e := catch:
    success := device.buttons.subscribe --callback=:: |button-data|
      log.info "Button press: ID=$(button-data.button-id), Duration=$(button-data.duration)ms"
      
      if button-data.duration >= 1000:
        // Long press - turn off strobe.
        device.strobe.off
        log.info "Long press detected - strobe off"
      else:
        // Short press - cycle through strobe colors based on button ID.
        if button-data.button-id == 0:
          device.strobe.red
          log.info "Button 0 pressed - red strobe"
        else if button-data.button-id == 1:
          device.strobe.green
          log.info "Button 1 pressed - green strobe"
        else if button-data.button-id == 2:
          device.strobe.blue
          log.info "Button 2 pressed - blue strobe"
        else:
          device.strobe.white
          log.info "Button $(button-data.button-id) pressed - white strobe"

    if not success:
      throw "Failed to subscribe to button press events"

  if e:
    log.error "🚨 Button setup failed: $e"
    throw e