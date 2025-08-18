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

  // Helper to create a data object for this message type.
  static data --duration/int?=null --request-control/bool?=null -> protocol.Data:
    data := protocol.Data
    if duration != null: data.add-data-uint DURATION duration
    if request-control != null: data.add-data-bool REQUEST-CONTROL request-control
    return data

  // GET
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  static set-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  duration -> int:
    return get-data-uint DURATION

  request-control -> bool:
    return get-data-bool REQUEST-CONTROL

  stringify -> string:
    return {
      "Duration": duration,
      "Request Control": request-control,
    }.stringify
