import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class CPU2Sleep extends protocol.Data:

  static MT := 47

  static INTERVAL := 1
  static WAKE-ON-EVENT := 2

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // DO
  static do-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  interval -> int:
    return get-data-uint INTERVAL

  wake-on-event -> int:
    return get-data-uint WAKE-ON-EVENT

  stringify -> string:
    return {
      "Interval": interval,
      "Wake on Event": wake-on-event,
    }.stringify
