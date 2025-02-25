import ..protocol as protocol

class HapticsControl extends protocol.Data:
  static MT := 40
  static PATTERN := 1
  static INTENSITY := 2

  constructor.fromData data/protocol.Data:
    super.fromData data
  
  msg -> protocol.Message:
    return protocol.Message.withData MT this

  pattern -> int:
    return getDataUint8 PATTERN

  intensity -> int:
    return getDataUint8 INTENSITY

  stringify -> string:
    return {
        "Pattern": pattern,
        "Intensity": intensity,
    }.stringify
