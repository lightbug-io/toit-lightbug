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

  static set-msg --gps-enable/int --rtk-enable-correction/int --start-mode/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data-uint8 GPS-ENABLE gps-enable
    msg.data.add-data-uint8 RTK-ENABLE-CORRECTION rtk-enable-correction
    if start-mode != null:
      msg.data.add-data-uint8 START-MODE start-mode
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  constructor --gps/bool --rtk/bool:
    this.add-data-uint8 GPS-ENABLE (if gps: 1 else: 0)
    this.add-data-uint8 RTK-ENABLE-CORRECTION (if rtk: 1 else: 0)

  gps-enable -> int:
    return get-data-uint8 GPS-ENABLE

  rtk-enable-correction -> int:
    return get-data-uint8 RTK-ENABLE-CORRECTION

  start-mode -> int:
    return get-data-uint8 START-MODE

  stringify -> string:
    return {
      "GPS Enable": gps-enable,
      "RTK Enable Correction": rtk-enable-correction,
      "Start Mode": start-mode,
    }.stringify
