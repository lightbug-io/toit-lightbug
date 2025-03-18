import ..protocol as protocol

class GPSControl extends protocol.Data:
  static MT := 39
  static GPS_ENABLE := 1
  static RTK_ENABLE_CORRECTION := 2
  static START_MODE := 3

  static START_MODE_NORMAL := 1
  static START_MODE_COLD := 2
  static START_MODE_WARM := 3
  static START_MODE_HOT := 4

  static setMsg --gpsEnable/int --rtkEnableCorrection/int --startMode/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addDataUint8 GPS_ENABLE gpsEnable
    msg.data.addDataUint8 RTK_ENABLE_CORRECTION rtkEnableCorrection
    if startMode != null:
      msg.data.addDataUint8 START_MODE startMode
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_SET
    return msg

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  constructor --gps/bool --rtk/bool:
    this.addDataUint8 GPS_ENABLE (if gps: 1 else: 0)
    this.addDataUint8 RTK_ENABLE_CORRECTION (if rtk: 1 else: 0)

  gpsEnable -> int:
    return getDataUint8 GPS_ENABLE

  rtkEnableCorrection -> int:
    return getDataUint8 RTK_ENABLE_CORRECTION

  startMode -> int:
    return getDataUint8 START_MODE

  stringify -> string:
    return {
      "GPS Enable": gpsEnable,
      "RTK Enable Correction": rtkEnableCorrection,
      "Start Mode": startMode,
    }.stringify
