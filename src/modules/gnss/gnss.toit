import ...protocol as protocol
import ...messages as messages
import ...devices as devices
import log

/**
GNSS module that exposes helpers around Position, SatelliteData, GPSControl,
and UbloxProtectionLevel messages. Provides get/subscribe/unsubscribe helpers
and convenience methods for enabling/disabling corrections.
*/
class GNSS:
  logger_/log.Logger
  device_/devices.Device?

  constructor --device/devices.Device?=null --logger/log.Logger=(log.default.with-name "lb-gnss"):
    device_ = device
    logger_ = logger

  available -> bool:
    // GNSS functionality is available if comms device present.
    return device_ != null

  // Position helpers
  get-position --base-data/protocol.Data?=protocol.Data:
    msg := messages.Position.get-msg --base-data=base-data
    device_.comms.send msg --now=true

  subscribe-position --interval/int?=null --duration/int?=null --timeout/int?=null:
    msg := messages.Position.subscribe-msg --interval=interval --duration=duration --timeout=timeout
    device_.comms.send msg --now=true

  unsubscribe-position --base-data/protocol.Data?=protocol.Data:
    msg := messages.Position.unsubscribe-msg --base-data=base-data
    device_.comms.send msg --now=true

  // Note: SatelliteData is not supported on this device; helper methods removed.

  // GPS Control (enable/disable corrections)
  get-gps-control --base-data/protocol.Data?=protocol.Data:
    msg := messages.GPSControl.get-msg --base-data=base-data
    device_.comms.send msg --now=true

  set-gps-control --corrections-enabled/int?=null --start-mode/int?=null --base-data/protocol.Data?=protocol.Data:
    msg := messages.GPSControl.set-msg --corrections-enabled=corrections-enabled --start-mode=start-mode --base-data=base-data
    device_.comms.send msg --now=true

  // Ublox protection level getters
  get-ublox-protection-level --base-data/protocol.Data?=protocol.Data:
    // The generated messages package exposes this as ProtectionLevel.
    msg := messages.ProtectionLevel.get-msg --base-data=base-data
    device_.comms.send msg --now=true

  stringify -> string:
    return "GNSS module"
