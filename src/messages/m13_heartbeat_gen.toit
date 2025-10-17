import ..protocol as protocol

// Auto generated class for protocol message
class Heartbeat extends protocol.Data:

  static MT := 13
  static MT_NAME := "Heartbeat"

  static BATTERY-PERCENT := 6

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
  static data --battery-percent/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if battery-percent != null: data.add-data-uint BATTERY-PERCENT battery-percent
    return data

  /**
   * Creates a Heartbeat message without a specific method.
   *
   * This is used for messages that don't require a specific method type
   * (like GET, SET, SUBSCRIBE) but still need to carry data.
   *
   * Parameters:
   * - data: Optional protocol.Data object containing message payload
   *
   * Returns: A Message ready to be sent
   */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
   * Devices send battery percentage in heartbeats
   */
  battery-percent -> int:
    return get-data-uint BATTERY-PERCENT

  stringify -> string:
    return {
      "Battery Percent": battery-percent,
    }.stringify
