import ..protocol as protocol

class Pressure extends protocol.Data:
  static MT := 44
  static PRESSURE := 1

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  pressure -> float:
    return getDataFloat PRESSURE

  stringify -> string:
    return {
      "Pressure": pressure,
    }.stringify
