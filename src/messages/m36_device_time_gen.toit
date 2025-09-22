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

  /**
   * Creates a protocol.Data object with all available fields for this message type.
   *
   * This is a comprehensive helper that accepts all possible fields.
   * For method-specific usage, consider using the dedicated request/response methods.
   *
   * Returns: A protocol.Data object with the specified field values
   */
  static data --unix-time/int?=null --year/int?=null --month/int?=null --date/int?=null --weekday/int?=null --hour/int?=null --minute/int?=null --second/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if unix-time != null: data.add-data-uint UNIX-TIME unix-time
    if year != null: data.add-data-uint YEAR year
    if month != null: data.add-data-uint MONTH month
    if date != null: data.add-data-uint DATE date
    if weekday != null: data.add-data-uint WEEKDAY weekday
    if hour != null: data.add-data-uint HOUR hour
    if minute != null: data.add-data-uint MINUTE minute
    if second != null: data.add-data-uint SECOND second
    return data

  /**
   * Creates a GET Request message for Device Time.
   */
  
  /**
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Unix time
   */
  unix-time -> int:
    return get-data-uint UNIX-TIME

  /**
   * Year
   */
  year -> int:
    return get-data-uint YEAR

  /**
   * Month
   */
  month -> int:
    return get-data-uint MONTH

  /**
   * Date in month
   */
  date -> int:
    return get-data-uint DATE

  /**
   * Weekday (0 = sunday, 1 = monday etc)
   */
  weekday -> int:
    return get-data-uint WEEKDAY

  /**
   * Hour
   */
  hour -> int:
    return get-data-uint HOUR

  /**
   * Minute
   */
  minute -> int:
    return get-data-uint MINUTE

  /**
   * Second
   */
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
