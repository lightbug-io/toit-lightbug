import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages as messages
import log

// A simple application waits for button press messages, and changes the strobe based on them
main:
  // Setup the Toit logger with the INFO log level
  log.set-default (log.default.with-level log.INFO-LEVEL)

  // This example is setup to work with the RH2 device
  device := devices.RtkHandheld2

  // Setup the comms service, which allows communication with the Lightbug device
  comms := services.Comms --device=device

  // Draw a new page with instructions, and to replace any existing page
  latch := comms.send (messages.TextPage.to-msg
    --page-id=3001
    --page-title="Strobe Example"
    --line2="Press the buttons"
    --line3="to change the strobe"
    --redraw-type=2 // FullRedraw
  )
    --now=true
    --withLatch=true
    --preSend=(:: print "💬 Sending instruction page to device")
    --postSend=(:: print "💬 Instruction page sent")
    --onAck=(:: print "✅ Instruction page ACKed")
    --onNack=(:: print "❌ Instruction page NACKed")
    --onError=(:: print "❌ Instruction page error")

  // Subscribe to button presses
  if not ( comms.send (messages.ButtonPress.subscribe-msg) --now=true
    --preSend=(:: print "💬 Sending button press subscribe")
    --onAck=(:: print "✅ Subscription ACKed")
    --onNack=(:: if it.msg-status != null: log.warn "Button not yet subscribed, state: $(it.msg-status)" else: log.warn "Button not yet subscribed" )
    --timeout=(Duration --s=5)
  ).get:
    throw "📟❌ Failed to subscribe to button press events"

  // Open an inbox to receive button press messages (and all other messages)
  inbox := comms.inbox "button-strobe"
  while true:
    msg := inbox.receive
    e := catch --trace:
      if msg.type == messages.ButtonPress.MT:
        log.info "Received button press: $msg"
        buttonData := messages.ButtonPress.from-data msg.data
        if buttonData.duration >= 1000:
          device.strobe.set false false false
        else:
          if buttonData.button-id == 1:
            device.strobe.set true false false
          else if buttonData.button-id == 0:
            device.strobe.set false true false
          else if buttonData.button-id == 2:
            device.strobe.set false false true
      else:
        log.info "Received message: $msg"
    if e != null:
      log.error "Error processing message: $e"
      continue