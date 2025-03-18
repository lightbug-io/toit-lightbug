import ..protocol as protocol

class BatteryStatus extends protocol.Data:
  static MT := 43
  static VOLTAGE := 1
  static PERCENT := 2

  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  voltage -> float:
    return get-data-float32 VOLTAGE

  percent -> int:
    return get-data-uint8 PERCENT

  stringify -> string:
    return {
      "Voltage": voltage,
      "Percent": percent,
    }.stringify
