import lightbug.protocol as protocol
import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.services as services
import lightbug.util.docs show message-to-docs-url
import lightbug.util.resilience show catch-and-restart
import lightbug show Coordinate

import io.byte-order show LITTLE-ENDIAN
import log
import monitor show Channel
import system.storage
import system
import esp32
import system.assets
import encoding.tison
import net
import net.modules.dns

// A WORK IN PROGRESS example that demonstrates how to use a Lightbug RTK device
// to detect when you are in a geofence, and display a message on the screen,
// changing the strobe colour to indicate if you are inside or outside of the fence, and making a noise.

// From an RH1 survey of the LB office (carpark), and slightly altered
// Open https://www.keene.edu/campus/maps/tool/?coordinates=-2.5419470%2C%2051.4700650%0A-2.5418540%2C%2051.4696260%0A-2.5415100%2C%2051.4695860%0A-2.5414360%2C%2051.4700180
// And zoom out once to see sat view
LB_OFFICE_FENCE := [
  Coordinate 51.4700650 -2.5419470,
  Coordinate 51.4696260 -2.5418540,
  Coordinate 51.4695867 -2.5415191,
  Coordinate 51.4700144 -2.5414521,
]

USED_FENCE := LB_OFFICE_FENCE

// Global state
device /devices.RtkHandheld2:= ?
io /services.Comms := ?
logLevel := log.INFO-LEVEL
logger := (log.default.with-level logLevel).with-name "fences"

main:
  log.set-default (log.default.with-level logLevel) // Set any other loggers to the same level

  device = devices.RtkHandheld2
  io = services.Comms --device=device

  logger.info "App initialized, loop starting"
  task:: catch-and-restart "mainLoop" (:: mainLoop)

mainLoop:
  loopOK := true

  // We may have already sent an open when initiating comms
  // But send one at the start of our main loop too incase we crash and recover it
  if not (io.send messages.Open.msg --now=true --withLatch=true
      --preSend=(:: logger.info "📟💬 Sending Open")
      --onAck=(:: logger.info "📟✅ Link open ACKed")
      --timeout=(Duration --s=5)
  ).get:
      throw "📟❌ Failed to open link"
  
  drawPresetNow

  // Subscribe to button presses
  btPushSub := protocol.Message 38 // button press, toit gen needs updating..
  btPushSub.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
  if not ( io.send btPushSub --now=true
              --preSend=(:: logger.info "📟💬 Sending button subscribe")
              --onAck=(:: logger.info "📟✅ Button subscribe" )
              --onNack=(:: if it.msg-status != null: logger.warn "Button not yet subscribed, state: $(it.msg-status)" else: logger.warn "Button not yet subscribed" )
              --timeout=(Duration --s=5)
          ).get:
      throw "📟❌ Failed to subscribe to button presses"

  // Request that the device turns on RTK
  if not (io.send (messages.GPSControl.set-msg --data=(messages.GPSControl.data --corrections-enabled=1)) --now=true
              --preSend=(:: logger.info "📟💬 Sending RTK on")
              --onAck=(:: logger.info "📟✅ RTK on")
              --onNack=(:: if it.msg-status != null: logger.warn "RTK not yet on, state: $(it.msg-status)" else: logger.warn "RTK not yet on" )
              --timeout=(Duration --s=5)
          ).get:
      throw "📟❌ Failed to turn on RTK"
  
  // Subscribe to location data
  if not ( io.send (messages.Position.subscribe-msg --ms=500) --now=true
              --preSend=(:: logger.info "📟💬 Sending location subscribe")
              --onAck=(:: logger.info "📟✅ Location subscribe")
              --onNack=(:: if it.msg-status != null: logger.warn "Location not yet subscribed, state: $(it.msg-status)" else: logger.warn "Location not yet subscribed" )
              --timeout=(Duration --s=5)
          ).get:
      throw "📟❌ Failed to subscribe to location data"

  // Now that we are setup, create an inbox to cycle through
  inbox := io.inbox "lb/fence-demo" --size=20

  // Request device status updates
  task::
    while true:
      io.send (messages.DeviceStatus.get-msg) --now=true
        --timeout=(Duration --ms=15000)
      sleep --ms=15000

  // Main loop processing inbound messages
  while loopOK:
    msg := inbox.receive
    yield
    e := catch --trace:
      if msg.type == messages.Position.MT:
        data := messages.Position.from-data msg.data
        logger.info "📟💬 Position: $data"
        processLastPosition msg
        continue
      if msg.type == 38: // Button press message
        data := messages.ButtonPress.from-data msg.data
        // field 1 is the button id (wrong in autogen)
        pressed := data.get-data-uint 1
        logger.info "📟💬 Button pressed: $pressed"
        if pressed == 1: // left
          muted = not muted // toggle muted
        if pressed == 0: // middle
          if isPreset:
            // Yellow LEDs indicate that the device is starting up, and not processing locations yet
            device.strobe.set true true false
            // Display an initial page
            io.send (messages.TextPage.msg --data=(messages.TextPage.data
              --page-id=2001
              --page-title="Workplace detection"
              --line-3="Starting up..."
              --redraw-type=2 // FullRedraw
            )) --now=true
          else:
            // Yellow LEDs indicate that the device is starting up, and not processing locations yet
            device.strobe.set false false false
            drawPresetNow
          isPreset = not isPreset // toggle preset record
        if pressed == 2: // right
        continue
      if msg.type == messages.DeviceStatus.MT:
        data := messages.DeviceStatus.from-data msg.data
        logger.info "📟💬 Device status: $data"
        continue
      if msg.type == messages.Heartbeat.MT:
        logger.info "📟❤️ Receive heartbeat"
        continue
      // Provide some useful output for messages that are not handled
      if msg.type != messages.ACK.MT:
        logger.info "📟❓ Unhandled device message: $(msg.msgType) $(message-to-docs-url msg)"
    if e != null:
      logger.error "Error processing message: $e"
      continue

  throw "Main loop exited unexpectedly"

drawPresetNow:
  presetPageMsg := messages.PresetPage.msg
  presetPageMsg.data.add-data-uint8 3 1 // page-id -> home page
  if not ( io.send presetPageMsg --now=true
              --preSend=(:: logger.info "📟💬 Requesting preset page")
              --onAck=(:: logger.info "📟✅ Preset page")
              --onNack=(:: if it.msg-status != null: logger.warn "Preset page not yet available, state: $(it.msg-status)" else: logger.warn "Preset page not yet available" )
              --timeout=(Duration --s=5)
          ).get:
      throw "📟❌ Failed to request preset page"

nextScreenDraw := Time.now
muted := true
isPreset := true

processLastPosition msg/protocol.Message:
  data := messages.Position.from-data msg.data
  coordinate := Coordinate data.latitude data.longitude

  // Process geofences
  inZone := coordinate.in-polygon USED_FENCE
  if inZone:
    logger.debug "🌐📍 Inside of the known fence"
    if not isPreset:
      device.strobe.set true false false // red
  else:
    logger.debug "🌐📍 Outside of the known fence"
    if not isPreset:
      device.strobe.set false true false // green

  // Update the screen with the current location, onces every 10 seconds
  if Time.now > nextScreenDraw:
    nextScreenDraw = Time.now + (Duration --s=1)

    bottomLine := ""
    // TODO, really home, actually needs to be disarm...
    if muted:
      bottomLine = " unmute        home"
    else:
      bottomLine = "  mute         home"

    // logger.info "🌐🖼️ Drawing screen update"
    if inZone:
      if not isPreset:
        io.send (messages.TextPage.msg --data=(messages.TextPage.data
          --page-id=2001
          --page-title="Coworkers Ahead!"
          --line-1="Approach with coffee in hand,"
          --line-2="enter at your own risk!"
          --line-3=""
          --line-4="$(data.accuracy-raw)cm ($(messages.Position.type-from-int data.type))"
          --line-5=bottomLine
        )) --now=true
      if not muted:
        io.send (messages.BuzzerControl.do-msg --data=(messages.BuzzerControl.data --duration=2000 --frequency=4.0)) --now=true
    else:
      if not isPreset:
        io.send (messages.TextPage.msg --data=(messages.TextPage.data
          --page-id=2001
          --page-title=""
          --line-1=""
          --line-2=""
          --line-3=""
          --line-4="$(data.accuracy-raw)cm ($(messages.Position.type-from-int data.type))"
          --line-5=bottomLine
        )) --now=true
