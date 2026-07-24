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
  static DURATION-HEADER-FIELD := protocol.Header.TYPE-SUBSCRIPTION-DURATION

  logger_/log.Logger
  device_/any
  duration-generation_/int := 0

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
    
    // Every LED control message supersedes any previous timed command.
    duration-generation_ += 1
    generation := duration-generation_
    duration := null
    if msg.header-has-data DURATION-HEADER-FIELD:
      duration = msg.header-get-data-uint DURATION-HEADER-FIELD
      logger_.debug "Strobe duration from header: $(duration)ms"

    // Resolving device_.strobe can request the device type. Do that outside
    // the inbound-handler task so it can process the response to that request.
    task --background=true::
      strobe := device_.strobe
      if generation == duration-generation_:
        strobe.set r g b
        if duration != null:
          sleep --ms=duration
          if generation == duration-generation_:
            strobe.off

    return true
