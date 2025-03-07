import ..protocol as protocol

class HapticsControl extends protocol.Data:
  static MT := 40
  static PATTERN := 1
  static INTENSITY := 2

  static PATTERN_1 := 1
  static PATTERN_2 := 2
  static PATTERN_3 := 3

  static INTENSITY_LOW := 0
  static INTENSITY_MEDIUM := 1
  static INTENSITY_HIGH := 2

  static doMsg pattern/int intensity/int -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addDataUint8 PATTERN pattern
    msg.data.addDataUint8 INTENSITY intensity
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_DO
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  pattern -> int:
    return getDataUint8 PATTERN

  intensity -> int:
    return getDataUint8 INTENSITY

  stringify -> string:
    return {
        "Pattern": pattern,
        "Intensity": intensity,
    }.stringify
