import ..protocol as protocol

class Config extends protocol.Data:
  static MT := 14
  static KEY := 7
  static PAYLOAD := 9

  constructor.from-data data/protocol.Data:
    super.from-data data

  msg -> protocol.Message:
    return protocol.Message.with-data MT this

  key -> int:
    return get-data-uintn KEY

  payload -> ByteArray:
    return get-data PAYLOAD
