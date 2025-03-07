import ...services as services
import ...util.docs show messageToDocsUrl
import ...util.resilience show catchAndRestart
import log
import monitor

// Hosts a small HTTP server that serves a page for directly sending bytes or messages to a Lightbug device
class MsgPrinter:

  inbox /monitor.Channel

  constructor comms/services.Comms --inboxSize/int=20:
    inbox = comms.inbox "lb/MsgPrinter" --size=inboxSize
    task:: catchAndRestart "lightbug-MsgPrinter::run" (:: run)

  run:
    while true:
      msg := inbox.receive
      // Try to process the message, catching any errors that occur, printing if successful
      e := catch --trace:
        log.info "Message: " + msg.msgType.stringify + " " + (messageToDocsUrl msg)
      if e != null:
        log.error "Error processing message: $e"
        continue
      yield // yield after processing each message
