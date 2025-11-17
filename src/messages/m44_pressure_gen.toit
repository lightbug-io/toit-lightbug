import ..protocol as protocol

// Auto generated class for protocol message
class Pressure extends protocol.Data:

  static MT := 44
  static MT_NAME := "Pressure"

  static PRESSURE := 1

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
  static data --pressure/float?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if pressure != null: data.add-data-float PRESSURE pressure
    return data

  /**
   * Creates a GET Request message for Pressure.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Pressure in millibar / hectopascals
   *
   * Unit: hPa
   */
  pressure -> float:
    return get-data-float PRESSURE

  stringify -> string:
    return {
      "pressure": pressure,
    }.stringify
