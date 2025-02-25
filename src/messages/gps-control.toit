import ..protocol as protocol

class GPSControl extends protocol.Data:
  static MT := 39
  static GPS-ENABLE := 1
  static RTK-ENABLE-CORRECTION := 2

  constructor --gps/bool --rtk/bool:
    this.add-data-uint8 GPS-ENABLE (gps ? 1 : 0)
    this.add-data-uint8 RTK-ENABLE-CORRECTION (rtk ? 1 : 0)

  constructor.from-data data/protocol.Data:
    super.from-data data

  msg -> protocol.Message:
    msg := protocol.Message.with-data MT this
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg
