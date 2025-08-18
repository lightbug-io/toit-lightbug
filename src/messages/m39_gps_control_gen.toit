import ..protocol as protocol

// Auto generated class for protocol message
class GPSControl extends protocol.Data:

  static MT := 39
  static MT_NAME := "GPSControl"

  static GPS-IS-ON := 1
  static CORRECTIONS-ENABLED := 2
  static CORRECTIONS-ENABLED_DISABLED := 0
  static CORRECTIONS-ENABLED_FULL-RTCM-STREAM := 1

  static CORRECTIONS-ENABLED_STRINGS := {
    0: "Disabled",
    1: "Full RTCM stream",
  }

  static corrections-enabled-from-int value/int -> string:
    return CORRECTIONS-ENABLED_STRINGS.get value --if-absent=(: "unknown")

  static START-MODE := 3
  static START-MODE_NORMAL := 1
  static START-MODE_COLD := 2
  static START-MODE_WARM := 3
  static START-MODE_HOT := 4

  static START-MODE_STRINGS := {
    1: "Normal",
    2: "Cold",
    3: "Warm",
    4: "Hot",
  }

  static start-mode-from-int value/int -> string:
    return START-MODE_STRINGS.get value --if-absent=(: "unknown")


  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --corrections-enabled/int?=null --start-mode/int?=null -> protocol.Data:
    data := protocol.Data
    if corrections-enabled != null: data.add-data-uint CORRECTIONS-ENABLED corrections-enabled
    if start-mode != null: data.add-data-uint START-MODE start-mode
    return data

  // GET
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  static set-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  gps-is-on -> bool:
    return get-data-bool GPS-IS-ON

  corrections-enabled -> int:
    return get-data-uint CORRECTIONS-ENABLED

  start-mode -> int:
    return get-data-uint START-MODE

  stringify -> string:
    return {
      "GPS is on": gps-is-on,
      "Corrections Enabled": corrections-enabled,
      "Start Mode": start-mode,
    }.stringify
