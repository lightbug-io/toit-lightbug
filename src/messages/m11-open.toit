import ..protocol as protocol

class Open extends protocol.Data:
  static MT := 11

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.withData MT this
