import lightbug.modules as modules
import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.modules.comms.message-handler show MessageHandler
import lightbug.modules.strobe.strobe show Strobe
import lightbug.protocol as protocol
import log

main:
  // Create device stub — examples in this repo often assume a default device
  dev := devices.I2C --log-level=log.WARN-LEVEL

  // Register a message handler to print and flash when Position messages arrive.
  print "Registering Position message handler"
  position-handler := PositionHandler --strobe=dev.strobe
  dev.comms.register-handler position-handler

  // Enable corrections (RTCM full stream)
  print "Enabling GNSS corrections (RTCM full stream)"
  dev.gnss.set-gps-control --corrections-enabled=messages.GPSControl.CORRECTIONS-ENABLED_FULL-RTCM-STREAM

  // Subscribe to position every 2000 ms for 1 second
  print "Subscribing to Position messages every 1 second"
  dev.gnss.subscribe-position --interval=1000

  while true:
    sleep --ms=10000


/**
 * Handler that reacts to incoming Position messages, prints coordinates and
 * briefly flashes the device strobe.
 */
class PositionHandler implements MessageHandler:
  logger_/log.Logger
  strobe_/Strobe

  constructor --logger/log.Logger=(log.default.with-name "position-handler") --strobe/Strobe:
    logger_ = logger
    strobe_ = strobe

  handle-message msg/protocol.Message -> bool:
    if msg.type == messages.Position.MT:
      pos := messages.Position.from-data msg.data

      // Use the converted float fields (already in human units) and
      // Float.stringify to format with the desired precision.
      lat_s := pos.latitude.stringify 6
      lon_s := pos.longitude.stringify 6
      alt_s := pos.altitude.stringify 2
      acc_s := pos.accuracy.stringify 2

      type_name := messages.Position.type-from-int pos.type

      // Print a compact human readable location with rounded values.
      print "📍 Position received: lat=$(lat_s) lon=$(lon_s) alt=$(alt_s) acc=$(acc_s) sats=$(pos.satellites) type=$(type_name)"
      // Flash a short green pulse
      strobe_.green
      sleep --ms=50
      strobe_.off
      return true

    return false

