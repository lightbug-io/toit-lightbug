import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages as messages
import log

// A simple application that sets up a Lightbug device and starts sending messages
// Demonstrates both synchronous and asynchronous message sending.
main:
  log.set-default (log.default.with-level log.INFO-LEVEL)

  // Do not send an open or heartbeat messages
  device := devices.I2C --open=false

  while true:
    /**
    Send an asynchronous message to open the device.
    The call to send is non-blocking, and the callback will be called when the response is received within the --timeout
    */
    log.info "Calling send-new (async)..."
    latch := device.comms.send-new messages.Open.msg --async --callback=:: |result|
      if result and result.msg-ok:
        log.info "Device opened successfully (async): $result"
      else if result:
        log.error "Failed to open device (async): $result.msg-status"
      else:
          log.error "Failed to open device (async), no response received"
    log.info "Called send-new (async), waiting for response..."

    // We don't have to wait for this, but we will do it anyway, so we don't conflict with the sync example below
    latch.get

    /**
    Send a synchronous message to open the device.
    This will block until the response is received or the --timeout is reached.
    */
    log.info "Calling send-new (sync)..."
    result := device.comms.send-new messages.Open.msg
    if result and result.msg-ok:
      log.info "Device opened successfully (sync): $result"
    else if result:
      log.error "Failed to open device (sync): $result.msg-status"
    else:
        log.error "Failed to open device (sync), no response received"
    log.info "Called send-new (sync)..."