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
  gnss := modules.GNSS --device=dev

  // Register a message handler to print and flash when Position messages arrive.
  print "Registering Position message handler"
  position-handler := PositionHandler --strobe=dev.strobe
  dev.comms.register-handler position-handler

  // Enable corrections (RTCM full stream)
  print "Enabling GNSS corrections (RTCM full stream)"
  gnss.set-gps-control --corrections-enabled=messages.GPSControl.CORRECTIONS-ENABLED_FULL-RTCM-STREAM

  // Subscribe to position every 2000 ms for 1 second
  print "Subscribing to Position messages every 1 second"
  gnss.subscribe-position --interval=1000

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

      // Latitude (fixed point 1e7) -> 6 decimals
      rlat := pos.latitude-raw
      negativeLat := rlat < 0
      if negativeLat:
        rlat = -rlat
      latWhole := rlat / 10000000
      latFrac6 := (rlat % 10000000) / 10
      latFrac6s := latFrac6.stringify
      while latFrac6s.size < 6:
        latFrac6s = "0" + latFrac6s
      lat_s := (if pos.latitude-raw < 0: "-" else: "") + latWhole.stringify + "." + latFrac6s

      // Longitude
      rlon := pos.longitude-raw
      negativeLon := rlon < 0
      if negativeLon:
        rlon = -rlon
      lonWhole := rlon / 10000000
      lonFrac6 := (rlon % 10000000) / 10
      lonFrac6s := lonFrac6.stringify
      while lonFrac6s.size < 6:
        lonFrac6s = "0" + lonFrac6s
      lon_s := (if pos.longitude-raw < 0: "-" else: "") + lonWhole.stringify + "." + lonFrac6s

      // Altitude: mm -> meters with 2 decimals
      ralt := pos.altitude-raw
      negativeAlt := ralt < 0
      if negativeAlt:
        ralt = -ralt
      altWhole := ralt / 1000
      altFrac2 := (ralt % 1000) / 10
      altFrac2s := altFrac2.stringify
      if altFrac2s.size < 2:
        altFrac2s = "0" + altFrac2s
      alt_s := (if pos.altitude-raw < 0: "-" else: "") + altWhole.stringify + "." + altFrac2s

      // Accuracy: centi -> two decimals
      racc := pos.accuracy-raw
      negativeAcc := racc < 0
      if negativeAcc:
        racc = -racc
      accWhole := racc / 100
      accFrac2 := racc % 100
      accFrac2s := accFrac2.stringify
      if accFrac2s.size < 2:
        accFrac2s = "0" + accFrac2s
      acc_s := (if pos.accuracy-raw < 0: "-" else: "") + accWhole.stringify + "." + accFrac2s

      type_name := messages.Position.type-from-int pos.type

      // Print a compact human readable location with rounded values.
      print "📍 Position received: lat=$(lat_s) lon=$(lon_s) alt=$(alt_s) acc=$(acc_s) type=$(type_name)"
      // Flash a short green pulse
      strobe_.green
      sleep --ms=50
      strobe_.off
      return true
  // SatelliteData unsupported on this device - removed
    return false
