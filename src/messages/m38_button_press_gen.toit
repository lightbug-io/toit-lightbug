import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class ButtonPress extends protocol.Data:

  static MT := 38

  static ID := 1
  static DURATION := 2

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // SUBSCRIBE to a message with an optional interval in milliseconds
  static subscribe-msg --ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    if ms != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL ms
    return msg

  // UNSUBSCRIBE
  static unsubscribe-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  id -> int:
    return get-data-uint ID

  duration -> int:
    return get-data-uint DURATION

  stringify -> string:
    return {
      "ID": id,
      "Duration": duration,
    }.stringify
