import ..protocol as protocol

class HapticsControl extends protocol.Data:
  static MT := 40
  static PATTERN := 1
  static INTENSITY := 2

  constructor.from-data data/protocol.Data:
    super.from-data data
  
  msg -> protocol.Message:
    return protocol.Message.with-data MT this

  pattern -> int:
    return get-data-uint8 PATTERN

  intensity -> int:
    return get-data-uint8 INTENSITY

  stringify -> string:
    return {
        "Pattern": pattern,
        "Intensity": intensity,
    }.stringify
