import ..protocol as protocol

class Pressure extends protocol.Data:
  static MT := 44
  static PRESSURE := 1

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  pressure -> float:
    return get-data-float32 PRESSURE

  stringify -> string:
    return {
      "Pressure": pressure,
    }.stringify
