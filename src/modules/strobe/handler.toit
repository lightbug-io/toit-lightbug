import ...protocol as protocol
import ...messages as messages
import ..comms.message-handler show MessageHandler
import log

/**
 * Handler for Strobe request messages.
 *
 * Clients can ask us to control the strobe attached to the ESP..
 */
class StrobeHandler implements MessageHandler:
  static MESSAGE-TYPE := messages.LEDControl.MT

  logger_/log.Logger
  device_/any

  constructor device/any --logger/log.Logger:
    logger_ = logger
    device_ = device

  handle-message msg/protocol.Message -> bool:
    if msg.type != MESSAGE-TYPE:
      return false
    
    // TODO do actual PWM in the future..
    r := (msg.data.get-data-uint8 messages.LEDControl.RED) > 0
    g := (msg.data.get-data-uint8 messages.LEDControl.GREEN) > 0
    b := (msg.data.get-data-uint8 messages.LEDControl.BLUE) > 0
    
    device_.strobe.set r g b
    return true