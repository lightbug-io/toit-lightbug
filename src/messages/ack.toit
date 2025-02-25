import ..protocol as protocol

class Ack extends protocol.Data:
  // Do users need this constant?
  // Should it be private instead? `MT_`
  // Same for the other messages.
  static MT := 5

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.with-data MT this
