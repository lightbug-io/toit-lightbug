import ..protocol as protocol

// Auto generated class for protocol message
class DeviceTime extends protocol.Data:

  static MT := 36
  static MT_NAME := "DeviceTime"

  static UNIX-TIME := 1
  static YEAR := 2
  static MONTH := 3
  static DATE := 4
  static WEEKDAY := 5
  static HOUR := 6
  static MINUTE := 7
  static SECOND := 8

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

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

  unix-time -> int:
    return get-data-uint UNIX-TIME

  year -> int:
    return get-data-uint YEAR

  month -> int:
    return get-data-uint MONTH

  date -> int:
    return get-data-uint DATE

  weekday -> int:
    return get-data-uint WEEKDAY

  hour -> int:
    return get-data-uint HOUR

  minute -> int:
    return get-data-uint MINUTE

  second -> int:
    return get-data-uint SECOND

  stringify -> string:
    return {
      "Unix Time": unix-time,
      "Year": year,
      "Month": month,
      "Date": date,
      "Weekday": weekday,
      "Hour": hour,
      "Minute": minute,
      "Second": second,
    }.stringify
