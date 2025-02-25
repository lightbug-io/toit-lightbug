import ..protocol as protocol

class GPSControl extends protocol.Data:
  static MT := 39
  static GPS_ENABLE := 1
  static RTK_ENABLE_CORRECTION := 2

  constructor --gps/bool --rtk/bool:
    this.addDataUint8 GPS_ENABLE (if gps: 1 else: 0)
    this.addDataUint8 RTK_ENABLE_CORRECTION (if rtk: 1 else: 0)

  constructor.fromData data/protocol.Data:
    super.fromData data

  msg -> protocol.Message:
    msg := protocol.Message.withData MT this
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD-SET
    return msg
