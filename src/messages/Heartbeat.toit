import ..protocol as protocol

class Heartbeat extends protocol.Data:
  static MT := 13

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.withData MT this
