import ..protocol as protocol

class DeviceIds extends protocol.Data:
  static MT := 35
  static ID := 1
  static IMEI := 2
  static ICCID := 3

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  id -> int:
    return get-data-uint ID

  imei -> string:
    return get-data-ascii IMEI

  iccid -> string:
    return get-data-ascii ICCID

  stringify -> string:
    return {
      "ID": id,
      "IMEI": imei,
      "ICCID": iccid,
    }.stringify
