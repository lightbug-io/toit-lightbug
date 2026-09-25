import ...modules.comms.message-handler show MessageHandler
import ...protocol as protocol
import log

// A callback-only observer for inbound messages. It deliberately never owns a
// protocol response; Comms remains responsible for the normal ACK policy.
class GenericHandler implements MessageHandler:
  logger_/log.Logger
  callback_/Lambda?

  constructor --callback/Lambda?=null --logger/log.Logger=(log.default.with-name "generic-handler"):
    logger_ = logger
    callback_ = callback

  handle-message msg/protocol.Message -> bool:
    if callback_:
      callback_.call msg
    // This is an observing callback, not a transport endpoint. Returning true
    // tells Comms that this handler will reply, which suppresses the normal
    // positive ACK. That left stored P1 ButtonPress packets unacknowledged
    // whenever an unrelated LoRa/Position observer was registered.
    return false
