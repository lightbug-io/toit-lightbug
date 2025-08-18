import ..protocol as protocol

// Auto generated class for protocol message
class BuzzerControl extends protocol.Data:

  static MT := 42
  static MT_NAME := "BuzzerControl"

  static DURATION := 1
  static SOUND-TYPE := 2
  static SOUND-TYPE_SOLID := 0
  static SOUND-TYPE_SIREN := 1
  static SOUND-TYPE_BEEP-BEEP := 2
  static SOUND-TYPE_AMBULANCE := 3
  static SOUND-TYPE_FIRETRUCK := 4
  static SOUND-TYPE_POSITIVE1 := 5
  static SOUND-TYPE_SLOWBEEP := 6
  static SOUND-TYPE_ALARM := 7

  static SOUND-TYPE_STRINGS := {
    0: "Solid",
    1: "Siren",
    2: "Beep Beep",
    3: "Ambulance",
    4: "FireTruck",
    5: "Positive1",
    6: "SlowBeep",
    7: "Alarm",
  }

  static sound-type-from-int value/int -> string:
    return SOUND-TYPE_STRINGS.get value --if-absent=(: "unknown")

  static INTENSITY := 3
  static RUN-COUNT := 4
  static FREQUENCY := 5

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --duration/int?=null --sound-type/int?=null --intensity/int?=null --run-count/int?=null --frequency/float?=null -> protocol.Data:
    data := protocol.Data
    if duration != null: data.add-data-uint DURATION duration
    if sound-type != null: data.add-data-uint SOUND-TYPE sound-type
    if intensity != null: data.add-data-uint INTENSITY intensity
    if run-count != null: data.add-data-uint RUN-COUNT run-count
    if frequency != null: data.add-data-float FREQUENCY frequency
    return data

  // GET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static set-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
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
  static unsubscribe-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // DO
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static do-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  // Creates a message with no method set
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

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
