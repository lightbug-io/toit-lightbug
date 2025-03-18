import ..protocol as protocol

class DeviceTime extends protocol.Data:
  static MT := 36
  static UNIX-TIME := 1
  static YEAR := 2
  static MONTH := 3
  static DATE := 4
  static WEEKDAY := 5
  static HOUR := 6
  static MINUTE := 7
  static SECOND := 8

  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  unixTime -> int:
    return get-data-uint32 UNIX-TIME

  year -> int:
    return get-data-uint16 YEAR

  month -> int:
    return get-data-uint8 MONTH

  date -> int:
    return get-data-uint8 DATE

  weekday -> int:
    return get-data-uint8 WEEKDAY

  hour -> int:
    return get-data-uint8 HOUR

  minute -> int:
    return get-data-uint8 MINUTE

  second -> int:
    return get-data-uint8 SECOND

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
