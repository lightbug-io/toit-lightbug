import ...services as services
import ...util.resilience show catch-and-restart
import ...devices as devices
import log
import monitor

class MsgPrinter:

  inbox /monitor.Channel

  constructor device/devices.Device --inboxSize/int=20:
    inbox = device.comms.inbox "lb/MsgPrinter" --size=inboxSize
    task:: catch-and-restart "lightbug-MsgPrinter::run" (:: run)

  run:
    while true:
      msg := inbox.receive
      // Try to process the message, catching any errors that occur, printing if successful
      e := catch --trace:
        print "Message: $(msg.msgType) $(msg)"
      if e != null:
        log.error "Error processing message: $e"
        continue
      yield // yield after processing each message
