import ..protocol as protocol

class BatteryStatus extends protocol.Data:
  static MT := 43
  static VOLTAGE := 1
  static PERCENT := 2

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  voltage -> float:
    return getDataFloat VOLTAGE

  percent -> int:
    return getDataUint8 PERCENT

  stringify -> string:
    return {
      "Voltage": voltage,
      "Percent": percent,
    }.stringify
