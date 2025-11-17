import ..protocol as protocol

// Auto generated class for protocol message
class Config extends protocol.Data:

  static MT := 14
  static MT_NAME := "Config"

  static KEY := 7
  static PAYLOAD := 9
  static PAYLOAD_RTKMINUSABLESATDB := 19
  static PAYLOAD_RTKMINELEVATION := 20

  static PAYLOAD_STRINGS := {
    19: "RtkMinUsableSatDb",
    20: "RtkMinElevation",
  }

  static payload-from-int value/int -> string:
    return PAYLOAD_STRINGS.get value --if-absent=(: "unknown")


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
  static data --key/int?=null --payload/ByteArray?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if key != null: data.add-data-uint KEY key
    if payload != null: data.add-data PAYLOAD payload
    return data

  /**
   * Creates a Config message without a specific method.
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
   * Key
   */
  key -> int:
    return get-data-uint KEY

  /**
   * Payload for the config
   *
   * Valid values:
   * - PAYLOAD_RTKMINUSABLESATDB (19): Minimum usable satellite db
   * - PAYLOAD_RTKMINELEVATION (20): RtkMinElevation
   */
  payload -> ByteArray:
    return get-data PAYLOAD

  stringify -> string:
    return {
      "key": key,
      "payload": payload,
    }.stringify
