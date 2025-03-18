import ..protocol as protocol

class Ack extends protocol.Data:
  static MT := 5
  static ACKED-TYPE := 1

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.with-data MT this

  acked-type -> int:
    return get-data-uint16 ACKED-TYPE

  stringify -> string:
    return {
      "ACKed Type": acked-type,
    }.stringify
