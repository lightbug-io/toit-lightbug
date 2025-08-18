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

  // Helper to create a data object for this message type.
  static data --unix-time/int?=null --year/int?=null --month/int?=null --date/int?=null --weekday/int?=null --hour/int?=null --minute/int?=null --second/int?=null -> protocol.Data:
    data := protocol.Data
    if unix-time != null: data.add-data-uint UNIX-TIME unix-time
    if year != null: data.add-data-uint YEAR year
    if month != null: data.add-data-uint MONTH month
    if date != null: data.add-data-uint DATE date
    if weekday != null: data.add-data-uint WEEKDAY weekday
    if hour != null: data.add-data-uint HOUR hour
    if minute != null: data.add-data-uint MINUTE minute
    if second != null: data.add-data-uint SECOND second
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
