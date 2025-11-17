import ..protocol as protocol

// Auto generated class for protocol message
class ACK extends protocol.Data:

  static MT := 5
  static MT_NAME := "ACK"

  static ACK-TYPE := 1

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
  static data --ack-type/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if ack-type != null: data.add-data-uint ACK-TYPE ack-type
    return data

  /**
   * Creates a ACK message without a specific method.
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
   * Type of previous message being ACKed
   */
  ack-type -> int:
    return get-data-uint ACK-TYPE

  stringify -> string:
    return {
      "type": ack-type,
    }.stringify
