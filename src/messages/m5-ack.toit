import ..protocol as protocol

class Ack extends protocol.Data:
  static MT := 5
  static ACKED-TYPE := 1

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.withData MT this

  ackedType -> int:
    return getDataUint16 ACKED-TYPE

  stringify -> string:
    return {
      "ACKed Type": ackedType,
    }.stringify
