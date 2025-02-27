import ..protocol as protocol

class DeviceTime extends protocol.Data:
  static MT := 36
  static UNIX_TIME := 1
  static YEAR := 2
  static MONTH := 3
  static DATE := 4
  static WEEKDAY := 5
  static HOUR := 6
  static MINUTE := 7
  static SECOND := 8

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  unixTime -> int:
    return getDataUint32 UNIX_TIME

  year -> int:
    return getDataUint16 YEAR

  month -> int:
    return getDataUint8 MONTH

  date -> int:
    return getDataUint8 DATE

  weekday -> int:
    return getDataUint8 WEEKDAY

  hour -> int:
    return getDataUint8 HOUR

  minute -> int:
    return getDataUint8 MINUTE

  second -> int:
    return getDataUint8 SECOND

  stringify -> string:
    return {
      "Unix Time": unixTime,
      "Year": year,
      "Month": month,
      "Date": date,
      "Weekday": weekday,
      "Hour": hour,
      "Minute": minute,
      "Second": second,
    }.stringify
