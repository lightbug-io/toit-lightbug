import ..protocol as protocol

class Close extends protocol.Data:
  static MT := 12

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.withData MT this