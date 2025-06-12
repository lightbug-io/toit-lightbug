import ..protocol as protocol

// Auto generated class for protocol message
class GSMRequestOwnership extends protocol.Data:

  static MT := 32
  static MT_NAME := "GSMRequestOwnership"

  static DURATION := 2
  static REQUEST-CONTROL := 4

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // SET
  static set-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  duration -> int:
    return get-data-uint DURATION

  request-control -> int:
    return get-data-uint REQUEST-CONTROL

  stringify -> string:
    return {
      "Duration": duration,
      "Request Control": request-control,
    }.stringify
