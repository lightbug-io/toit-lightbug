import ..protocol as protocol

class Status extends protocol.Data:
  static MT := 34
  static BATTERY := 1
  static SIGNAL-STRENGTH := 2
  static DEVICE-MODE := 3
  static NETWORK-TYPE := 4
  static NETWORK-MNC := 5
  static NETWORK-MCC := 6
  static FIRMWARE-VERSION := 7

  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  battery -> int:
    return get-data-uint8 BATTERY

  signal-strength -> int:
    return get-data-uint8 SIGNAL-STRENGTH

  device-mode -> int:
    return get-data-uint8 DEVICE-MODE

  network-type -> int:
    return get-data-uint8 NETWORK-TYPE

  network-mnc -> int:
    return get-data-uint16 NETWORK-MNC

  network-mcc -> int:
    return get-data-uint16 NETWORK-MCC

  firmware-version -> int:
    return get-data-uint32 FIRMWARE-VERSION

  stringify -> string:
    return {
      "Battery": battery,
      "Signal Strength": signal-strength,
      "Device Mode": device-mode,
      "Network Type": network-type,
      "Network MNC": network-mnc,
      "Network MCC": network-mcc,
      "Firmware Version": firmware-version,
    }.stringify
