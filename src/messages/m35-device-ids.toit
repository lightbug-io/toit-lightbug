import ..protocol as protocol

class DeviceIds extends protocol.Data:
  static MT := 35
  static ID := 1
  static IMEI := 2
  static ICCID := 3

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  id -> int:
    return getDataUint ID

  imei -> string:
    return getDataAscii IMEI

  iccid -> string:
    return getDataAscii ICCID

  stringify -> string:
    return {
      "ID": id,
      "IMEI": imei,
      "ICCID": iccid,
    }.stringify
