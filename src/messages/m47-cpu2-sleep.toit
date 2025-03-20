import ..protocol as protocol

class CPU2Sleep extends protocol.Data:
  static MT := 47
  static INTERVAL := 1
  static WAKE-ON-EVENT := 2

  static do-msg --interval/int --wake-on-event/bool=false -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data-uint32 INTERVAL interval
    msg.data.add-data-uint8 WAKE-ON-EVENT (wake-on-event ? 1 : 0)
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  constructor --interval/int --wake-on-event/int:
    this.add-data-uint32 INTERVAL interval
    this.add-data-uint8 WAKE-ON-EVENT wake-on-event

  interval -> int:
    return get-data-uint32 INTERVAL

  wake-on-event -> int:
    return get-data-uint8 WAKE-ON-EVENT

  stringify -> string:
    return {
      "Interval": interval,
      "Wake on Event": wake-on-event,
    }.stringify
