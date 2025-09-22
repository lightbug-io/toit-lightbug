import ..protocol as protocol

// Auto generated class for protocol message
class Temperature extends protocol.Data:

  static MT := 41
  static MT_NAME := "Temperature"

  static TEMPERATURE := 1

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
  static data --temperature/float?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if temperature != null: data.add-data-float TEMPERATURE temperature
    return data

  /**
   * Creates a GET Request message for Temperature.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Temperature in Celsius
   *
   * Unit: C
   */
  temperature -> float:
    return get-data-float TEMPERATURE

  stringify -> string:
    return {
      "Temperature": temperature,
    }.stringify
