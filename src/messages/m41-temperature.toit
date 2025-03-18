import ..protocol as protocol

class Temperature extends protocol.Data:
  static MT := 41
  static TEMPERATURE := 1

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  temperature -> float:
    return get-data-float32 TEMPERATURE

  stringify -> string:
    return {
      "Temperature": temperature,
    }.stringify
