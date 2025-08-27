import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.modules.comms.message-handler show MessageHandler
import lightbug.modules.strobe.strobe show Strobe
import lightbug.protocol as protocol
import log

/**
 * Example message handler that prints a heart emoji when heartbeat messages are received.
 * Demonstrates how to create and register a custom message handler.
 */
class HeartbeatHandler implements MessageHandler:
  logger_/log.Logger
  heartbeat-count_/int := 0
  strobe_/Strobe

  constructor --logger/log.Logger=(log.default.with-name "heartbeat-handler") --strobe/Strobe:
    logger_ = logger
    strobe_ = strobe

  /**
   * Handle incoming messages - look for heartbeats (message type 13).
   */
  handle-message msg/protocol.Message -> bool:
    if msg.type == 13:  // Heartbeat message type
      heartbeat-count_++
      print "💓 Heartbeat #$heartbeat-count_ received!"
      logger_.debug "Heartbeat message handled"
      strobe_.red
      sleep --ms=50
      strobe_.off
      return true  // Message was handled
    return false  // Not a heartbeat, let other handlers process it

  /**
   * Get the current heartbeat count.
   */
  heartbeat-count -> int:
    return heartbeat-count_

main:
  device := devices.RtkHandheld2

  heartbeat-handler := HeartbeatHandler --strobe=device.strobe
  device.comms.register-handler heartbeat-handler

  print "Heartbeat handler registered - will show 💓 for each heartbeat"
  print "Device will send heartbeats automatically..."

  while true:
    sleep --ms=11000
    print "Still listening for heartbeats... (💓 count: $(heartbeat-handler.heartbeat-count))"
