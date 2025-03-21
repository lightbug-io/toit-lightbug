import ..protocol as protocol

class Open extends protocol.Data:
  static MT := 11

  constructor:
    super

  static msg -> protocol.Message:
    msg := protocol.Message MT
    return msg
