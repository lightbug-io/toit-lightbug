import ..protocol as protocol

class HapticsControl extends protocol.Data:
  static MT := 40
  static PATTERN := 1
  static INTENSITY := 2

  static PATTERN-1 := 1
  static PATTERN-2 := 2
  static PATTERN-3 := 3

  static INTENSITY-LOW := 0
  static INTENSITY-MEDIUM := 1
  static INTENSITY-HIGH := 2

  static do-msg pattern/int intensity/int -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data-uint8 PATTERN pattern
    msg.data.add-data-uint8 INTENSITY intensity
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  pattern -> int:
    return get-data-uint8 PATTERN

  intensity -> int:
    return get-data-uint8 INTENSITY

  stringify -> string:
    return {
        "Pattern": pattern,
        "Intensity": intensity,
    }.stringify
