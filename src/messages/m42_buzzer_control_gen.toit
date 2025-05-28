import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class BuzzerControl extends protocol.Data:

  static MT := 42

  static DURATION := 1
  static SOUND-TYPE := 2
  static INTENSITY := 3
  static RUN-COUNT := 4
  static FREQUENCY := 5

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // GET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static get-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static set-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  // SUBSCRIBE to a message with an optional interval in milliseconds
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static subscribe-msg --ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    if ms != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL ms
    return msg

  // UNSUBSCRIBE
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static unsubscribe-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // DO
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static do-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  duration -> int:
    return get-data-uint DURATION

  sound-type -> int:
    return get-data-uint SOUND-TYPE

  intensity -> int:
    return get-data-uint INTENSITY

  run-count -> int:
    return get-data-uint RUN-COUNT

  frequency -> float:
    return get-data-float FREQUENCY

  stringify -> string:
    return {
      "Duration": duration,
      "Sound Type": sound-type,
      "Intensity": intensity,
      "Run Count": run-count,
      "Frequency": frequency,
    }.stringify
