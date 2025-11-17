import ..protocol as protocol

// Auto generated class for protocol message
class BatteryStatus extends protocol.Data:

  static MT := 43
  static MT_NAME := "BatteryStatus"

  static VOLTAGE := 1
  static PERCENT := 2

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
  static data --voltage/float?=null --percent/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if voltage != null: data.add-data-float VOLTAGE voltage
    if percent != null: data.add-data-uint PERCENT percent
    return data

  /**
   * Creates a GET Request message for Battery Status.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Current battery voltage
   *
   * Unit: V
   */
  voltage -> float:
    return get-data-float VOLTAGE

  /**
   * Current battery percent
   *
   * Unit: %
   */
  percent -> int:
    return get-data-uint PERCENT

  stringify -> string:
    return {
      "voltage": voltage,
      "percent": percent,
    }.stringify
