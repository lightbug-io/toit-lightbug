import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages
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
  textPageData := messages.TextPage
  textPageData.add-data-uint messages.TextPage.PAGE-ID 3001
  textPageData.add-data-ascii messages.TextPage.PAGE-TITLE "Strobe Example"
  textPageData.add-data-ascii messages.TextPage.LINE-2 "Press the buttons"
  textPageData.add-data-ascii messages.TextPage.LINE-3 "to change the strobe"
  textPageData.add-data-uint messages.TextPage.REDRAW-TYPE 2 // FullRedraw
  
  latch := comms.send (messages.TextPage.do-msg)
    --now=true
    --withLatch=true
    --preSend=(:: print "💬 Sending instruction page to device")
    --postSend=(:: print "💬 Instruction page sent")
    --onAck=(:: print "✅ Instruction page ACKed")
    --onNack=(:: print "❌ Instruction page NACKed")
    --onError=(:: print "❌ Instruction page error")

  // Subscribe to button presses
  if not ( comms.send (messages.ButtonPress.subscribe-msg --ms=1000) --now=true
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
          if buttonData.id == 1:
            device.strobe.set true false false
          else if buttonData.id == 0:
            device.strobe.set false true false
          else if buttonData.id == 2:
            device.strobe.set false false true
      else:
        log.info "Received message: $msg"
    if e != null:
      log.error "Error processing message: $e"
      continue