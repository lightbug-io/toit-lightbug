import lightbug.protocol as protocol
import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.services as services
import lightbug.modules as modules
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
//
// DEMO MODE:
// - Triple-click the middle button to enter/exit DEMO mode
// - In DEMO mode, the device ignores real GPS locations and uses simulated zone state
// - Single-click the middle button in DEMO mode to toggle between "in zone" and "out of zone"
// - The screen will show "[DEMO]" indicator when in demo mode

// From an RH1 survey of the LB office (carpark), and slightly altered
// Open https://www.keene.edu/campus/maps/tool/?coordinates=-2.5419470%2C%2051.4700650%0A-2.5418540%2C%2051.4696260%0A-2.5415100%2C%2051.4695860%0A-2.5414360%2C%2051.4700180
// And zoom out once to see sat view
LB_OFFICE_OUTER := [
  Coordinate 51.4700650 -2.5419470,
  Coordinate 51.4696260 -2.5418540,
  Coordinate 51.4695867 -2.5415191,
  Coordinate 51.4700144 -2.5414521,
]

// And an actual office one dragged by hand on the map
// Open https://www.keene.edu/campus/maps/tool/?coordinates=-2.5421521%2C%2051.4700178%0A-2.5422138%2C%2051.4697588%0A-2.5415996%2C%2051.4696836%0A-2.5415593%2C%2051.4698891%0A-2.5416210%2C%2051.4698941%0A-2.5416076%2C%2051.4699727
// And zoom out once to see sat view
LB_OFFICE_INNER:= [
  Coordinate 51.4700178 -2.5421521,
  Coordinate 51.4697588 -2.5422138,
  Coordinate 51.4696836 -2.5415996,
  Coordinate 51.4698891 -2.5415593,
  Coordinate 51.4698941 -2.5416210,
  Coordinate 51.4699727 -2.5416076,
]

USED_FENCE := LB_OFFICE_OUTER

// Global state
device /devices.RtkHandheld2:= ?
io /modules.Comms := ?
logLevel := log.INFO-LEVEL
logger := (log.default.with-level logLevel).with-name "fences"

// Demo mode state
demoMode := false
demoInZone := false
middleButtonClickCount := 0
lastMiddleButtonPress := Time.epoch
tripleClickTimeout := Time.epoch
TRIPLE_CLICK_WINDOW ::= Duration --ms=2000 // 2 second timeout for triple click detection

main:
  log.set-default (log.default.with-level logLevel) // Set any other loggers to the same level

  device = devices.RtkHandheld2
  io = device.comms

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
  if not (io.send (messages.GPSControl.set-msg --corrections-enabled=1) --now=true
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

  // Task to reset middle button click count after timeout
  task::
    while true:
      if middleButtonClickCount > 0 and Time.now > tripleClickTimeout:
        middleButtonClickCount = 0
      sleep --ms=100

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
        // We want to redraw the menu right away as state is changing
        nextScreenDraw = Time.now
        if pressed == 1: // left
          if muted:
            // we will be unmuting
            nextAlarmEmit = Time.now // allow immediate alarm if in zone
          else:
            // We will be muting
            io.send (messages.Alarm.msg --data=(create-alarm-data 0)) --now=true // stop any alarm
            isAlarmOff = true
            nextAlarmEmit = Time.now // allow immediate alarm if unmuted again
          muted = not muted // toggle muted
        if pressed == 2: // right
          if isPreset:
            device.strobe.yellow // yellow indicates startup...
            io.send (messages.Alarm.msg --data=(create-alarm-data 0)) --now=true
            // Display an initial page
            io.send (messages.TextPage.msg --data=(messages.TextPage.data
              --page-id=2001
              --page-title="Workplace detection"
              --line-3="Starting up..."
              --redraw-type=2 // FullRedraw
            )) --now=true
          else:
            device.strobe.off // off once started up
            drawPresetNow
          isPreset = not isPreset // toggle preset record
        if pressed == 0: // middle
          now := Time.now
          
          // Check if this is part of a potential triple-click sequence
          if now <= tripleClickTimeout:
            middleButtonClickCount++
          else:
            middleButtonClickCount = 1 // Reset count if timeout exceeded
          
          lastMiddleButtonPress = now
          tripleClickTimeout = now + TRIPLE_CLICK_WINDOW
          
          if middleButtonClickCount == 3:
            // Triple click detected - toggle demo mode
            demoMode = not demoMode
            middleButtonClickCount = 0 // Reset counter
            if demoMode:
              logger.info "🎭 Entering DEMO mode"
              device.strobe.blue
              sleep --ms=500
              device.strobe.off
            else:
              logger.info "🎭 Exiting DEMO mode"
              device.strobe.yellow
              sleep --ms=500
              device.strobe.off
            nextScreenDraw = Time.now // Force screen redraw
          else if demoMode and middleButtonClickCount == 1:
            // Single click in demo mode - toggle demo zone state
            demoInZone = not demoInZone
            logger.info "🎭 Demo mode: toggling zone state to $(demoInZone ? "IN" : "OUT")"
            nextScreenDraw = Time.now // Force screen redraw
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
nextAlarmEmit := Time.now
muted := true
isPreset := true
isAlarmOff := true
wasLastInZone := false

processLastPosition msg/protocol.Message:
  data := messages.Position.from-data msg.data
  coordinate := Coordinate data.latitude data.longitude

  // Determine if we're in zone - use demo state if in demo mode, otherwise use real GPS
  inZone := demoMode ? demoInZone : coordinate.in-polygon USED_FENCE
  
  // Process geofences
  if inZone:
    logger.debug "🌐📍 Inside of the known fence"
    if not isPreset:
      device.strobe.red
      device.strobe.sequence --speed-ms=100 --colors=[device.strobe.RED, device.strobe.OFF]
  else:
    logger.debug "🌐📍 Outside of the known fence"
    if not isPreset:
      device.strobe.green
  if inZone != wasLastInZone:
    wasLastInZone = inZone
    nextScreenDraw = Time.now

  // Update the screen with the current location
  if Time.now >= nextScreenDraw:
    nextScreenDraw = Time.now + (Duration --ms=1000) // Update every 1s when only updating precision / menu

    acc := data.accuracy-raw
    accType := data.type
    if demoMode:
      acc = 1 // Simulate perfect accuracy in demo mode
      accType = 10

    bottomLine := ""
    // TODO, really home, actually needs to be disarm...
    if muted:
      bottomLine = " unmute     $(acc.stringify.pad --left 4)cm/$(accType)        home"
    else:
      bottomLine = "  mute       $(acc.stringify.pad --left 4)cm/$(accType)        home"

    // logger.info "🌐🖼️ Drawing screen update"
    if inZone:
      if not isPreset:
        if not muted:
          if Time.now >= nextAlarmEmit:
            nextAlarmEmit = Time.now + (Duration --ms=3000) // Emit every 3s
            isAlarmOff = false
            io.send (messages.Alarm.msg --data=(create-alarm-data 3 4 1)) --now=true //3s siren
        io.send (messages.TextPage.msg --data=(messages.TextPage.data
          --page-id=2001
          --page-title="Coworkers Ahead!!!"
          --line-1=" Approach with coffee in hand,"
          --line-2=" lookout for paperwork,"
          --line-3=" enter at your own risk!"
          --line-4=""
          --line-5=bottomLine
        )) --now=true
    else:
      if not isPreset:
        if not muted and not isAlarmOff:
          nextAlarmEmit = Time.now
          isAlarmOff = true
          io.send (messages.Alarm.msg --data=(create-alarm-data 0)) --now=true //alarm off
        io.send (messages.TextPage.msg --data=(messages.TextPage.data
          --page-id=2001
          --page-title="Workplace detection"
          --line-1=" Final moments of freedom,"
          --line-2=" breathe deeply,"
          --line-3=" workplace ahead!"
          --line-4=""
          --line-5=bottomLine
        )) --now=true

create-alarm-data duration/int buzzer-pattern/int?=null buzzer-intensity/int?=null -> protocol.Data:
  data := protocol.Data
  data.add-data-uint32 messages.Alarm.DURATION duration
  if buzzer-pattern != null:
    data.add-data-uint8 messages.Alarm.BUZZER-PATTERN buzzer-pattern
  if buzzer-intensity != null:
    data.add-data-uint8 messages.Alarm.BUZZER-INTENSITY buzzer-intensity
  return data