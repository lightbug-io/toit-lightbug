import ..protocol as protocol

class Status extends protocol.Data:
  static MT := 34
  static BATTERY := 1
  static SIGNAL_STRENGTH := 2
  static DEVICE_MODE := 3
  static NETWORK_TYPE := 4
  static NETWORK_MNC := 5
  static NETWORK_MCC := 6
  static FIRMWARE_VERSION := 7

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD-GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  battery -> int:
    return getDataUint8 BATTERY

  signalStrength -> int:
    return getDataUint8 SIGNAL_STRENGTH

  deviceMode -> int:
    return getDataUint8 DEVICE_MODE

  networkType -> int:
    return getDataUint8 NETWORK_TYPE

  networkMnc -> int:
    return getDataUint16 NETWORK_MNC

  networkMcc -> int:
    return getDataUint16 NETWORK_MCC

  firmwareVersion -> int:
    return getDataUint32 FIRMWARE_VERSION

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
