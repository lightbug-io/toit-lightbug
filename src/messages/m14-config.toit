import ..protocol as protocol

class Config extends protocol.Data:
  static MT := 14
  static KEY := 7
  static PAYLOAD := 9

  constructor.fromData data/protocol.Data:
    super.fromData data
  
  msg -> protocol.Message:
    return protocol.Message.withData MT this

  key -> int:
    return getDataUintn KEY

  payload -> ByteArray:
    return getData PAYLOAD
