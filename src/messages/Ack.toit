import ..protocol as protocol

class Ack extends protocol.Data:
  static MT := 5

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.withData MT this
