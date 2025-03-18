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

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  battery -> int:
    return getDataUint8 BATTERY

  signalStrength -> int:
    return getDataUint8 SIGNAL-STRENGTH

  deviceMode -> int:
    return getDataUint8 DEVICE-MODE

  networkType -> int:
    return getDataUint8 NETWORK-TYPE

  networkMnc -> int:
    return getDataUint16 NETWORK-MNC

  networkMcc -> int:
    return getDataUint16 NETWORK-MCC

  firmwareVersion -> int:
    return getDataUint32 FIRMWARE-VERSION

  stringify -> string:
    return {
      "Battery": battery,
      "Signal Strength": signalStrength,
      "Device Mode": deviceMode,
      "Network Type": networkType,
      "Network MNC": networkMnc,
      "Network MCC": networkMcc,
      "Firmware Version": firmwareVersion,
    }.stringify
