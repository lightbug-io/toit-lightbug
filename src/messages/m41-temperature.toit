import ..protocol as protocol

class Temperature extends protocol.Data:
  static MT := 41
  static TEMPERATURE := 1

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  temperature -> float:
    return getDataFloat32 TEMPERATURE

  stringify -> string:
    return {
      "Temperature": temperature,
    }.stringify
