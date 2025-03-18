import ..protocol as protocol

class GPSControl extends protocol.Data:
  static MT := 39
  static GPS-ENABLE := 1
  static RTK-ENABLE-CORRECTION := 2
  static START-MODE := 3

  static START-MODE-NORMAL := 1
  static START-MODE-COLD := 2
  static START-MODE-WARM := 3
  static START-MODE-HOT := 4

  static setMsg --gpsEnable/int --rtkEnableCorrection/int --startMode/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data-uint8 GPS-ENABLE gpsEnable
    msg.data.add-data-uint8 RTK-ENABLE-CORRECTION rtkEnableCorrection
    if startMode != null:
      msg.data.add-data-uint8 START-MODE startMode
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  constructor --gps/bool --rtk/bool:
    this.add-data-uint8 GPS-ENABLE (if gps: 1 else: 0)
    this.add-data-uint8 RTK-ENABLE-CORRECTION (if rtk: 1 else: 0)

  gpsEnable -> int:
    return get-data-uint8 GPS-ENABLE

  rtkEnableCorrection -> int:
    return get-data-uint8 RTK-ENABLE-CORRECTION

  startMode -> int:
    return get-data-uint8 START-MODE

  stringify -> string:
    return {
      "GPS Enable": gpsEnable,
      "RTK Enable Correction": rtkEnableCorrection,
      "Start Mode": startMode,
    }.stringify
