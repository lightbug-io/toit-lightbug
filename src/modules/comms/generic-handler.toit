import ...modules.comms.message-handler show MessageHandler
import ...protocol as protocol
import log

class GenericHandler implements MessageHandler:
  logger_/log.Logger
  callback_/Lambda?

  constructor --callback/Lambda?=null --logger/log.Logger=(log.default.with-name "generic-handler"):
    logger_ = logger
    callback_ = callback

  handle-message msg/protocol.Message -> bool:
    if callback_:
      callback_.call msg
      return true // assume OK if the callback didn't return
    return false
