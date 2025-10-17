import ..protocol as protocol

// Auto generated class for protocol message
class Open extends protocol.Data:

  static MT := 11
  static MT_NAME := "Open"

  static FLAGS := 1
  static DEVICE-TYPE := 10

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
  static data --flags/int?=null --device-type/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if flags != null: data.add-data-uint FLAGS flags
    if device-type != null: data.add-data-uint DEVICE-TYPE device-type
    return data

  /**
   * Creates a Open message without a specific method.
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
   * For future use, if used should currently always be 0
   */
  flags -> int:
    return get-data-uint FLAGS

  /**
   * Type of device, relates to the SN prefix
   */
  device-type -> int:
    return get-data-uint DEVICE-TYPE

  stringify -> string:
    return {
      "Flags": flags,
      "Device Type": device-type,
    }.stringify
