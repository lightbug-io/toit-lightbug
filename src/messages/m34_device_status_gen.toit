import ..protocol as protocol

// Auto generated class for protocol message
class DeviceStatus extends protocol.Data:

  static MT := 34
  static MT_NAME := "DeviceStatus"

  static BATTERY := 1
  static SIGNAL-STRENGTH := 2
  static MODE := 3
  static MODE_SLEEP := 0
  static MODE_AWAKE := 1

  static MODE_STRINGS := {
    0: "Sleep",
    1: "Awake",
  }

  static mode-from-int value/int -> string:
    return MODE_STRINGS.get value --if-absent=(: "unknown")

  static NETWORK-TYPE := 4
  static NETWORK-TYPE_NO-NETWORK := 0
  static NETWORK-TYPE_GSM := 2
  static NETWORK-TYPE_WCDMA := 3
  static NETWORK-TYPE_LTE := 4

  static NETWORK-TYPE_STRINGS := {
    0: "No network",
    2: "GSM (2G)",
    3: "WCDMA (3G)",
    4: "LTE (4G)",
  }

  static network-type-from-int value/int -> string:
    return NETWORK-TYPE_STRINGS.get value --if-absent=(: "unknown")

  static NETWORK-MNC := 5
  static NETWORK-MCC := 6
  static FIRMWARE-VERSION := 7

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --battery/int?=null --signal-strength/int?=null --mode/int?=null --network-type/int?=null --network-mnc/int?=null --network-mcc/int?=null --firmware-version/int?=null -> protocol.Data:
    data := protocol.Data
    if battery != null: data.add-data-uint BATTERY battery
    if signal-strength != null: data.add-data-uint SIGNAL-STRENGTH signal-strength
    if mode != null: data.add-data-uint MODE mode
    if network-type != null: data.add-data-uint NETWORK-TYPE network-type
    if network-mnc != null: data.add-data-uint NETWORK-MNC network-mnc
    if network-mcc != null: data.add-data-uint NETWORK-MCC network-mcc
    if firmware-version != null: data.add-data-uint FIRMWARE-VERSION firmware-version
    return data

  // GET
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  battery -> int:
    return get-data-uint BATTERY

  signal-strength -> int:
    return get-data-uint SIGNAL-STRENGTH

  mode -> int:
    return get-data-uint MODE

  network-type -> int:
    return get-data-uint NETWORK-TYPE

  network-mnc -> int:
    return get-data-uint NETWORK-MNC

  network-mcc -> int:
    return get-data-uint NETWORK-MCC

  firmware-version -> int:
    return get-data-uint FIRMWARE-VERSION

  stringify -> string:
    return {
      "Battery": battery,
      "Signal Strength": signal-strength,
      "Mode": mode,
      "Network type": network-type,
      "Network MNC": network-mnc,
      "Network MCC": network-mcc,
      "Firmware Version": firmware-version,
    }.stringify
