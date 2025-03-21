import ..protocol as protocol

class Close extends protocol.Data:
  static MT := 12

  constructor:
    super

  static msg -> protocol.Message:
    msg := protocol.Message MT
    return msg