import ..protocol as protocol

// Auto generated class for protocol message
class CPU2Sleep extends protocol.Data:

  static MT := 47
  static MT_NAME := "CPU2Sleep"

  static INTERVAL := 1
  static WAKE-ON-EVENT := 2

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --interval/int?=null --wake-on-event/bool?=null -> protocol.Data:
    data := protocol.Data
    if interval != null: data.add-data-uint INTERVAL interval
    if wake-on-event != null: data.add-data-bool WAKE-ON-EVENT wake-on-event
    return data

  // DO
  static do-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  interval -> int:
    return get-data-uint INTERVAL

  wake-on-event -> bool:
    return get-data-bool WAKE-ON-EVENT

  stringify -> string:
    return {
      "Interval": interval,
      "Wake on Event": wake-on-event,
    }.stringify
