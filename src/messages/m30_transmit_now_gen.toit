import ..protocol as protocol

// Auto generated class for protocol message
class TransmitNow extends protocol.Data:

  static MT := 30
  static MT_NAME := "TransmitNow"

  static GPS-SEARCH := 1
  static PAYLOAD := 2
  static RETRIES := 3
  static PRIORITY := 4

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
  static data --gps-search/bool?=null --payload/ByteArray?=null --retries/int?=null --priority/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if gps-search != null: data.add-data-bool GPS-SEARCH gps-search
    if payload != null: data.add-data PAYLOAD payload
    if retries != null: data.add-data-uint RETRIES retries
    if priority != null: data.add-data-uint PRIORITY priority
    return data

  /**
   * Creates a DO Request message for Transmit Now.
   */
  
  /**
   * Returns: A Message ready to be sent
   */
  static do-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-DO base-data

  /**
   * GPS Search
   */
  gps-search -> bool:
    return get-data-bool GPS-SEARCH

  /**
   * Data to send, can be up to 200 bytes
   */
  payload -> ByteArray:
    return get-data PAYLOAD

  /**
   * 0 - 10
   */
  retries -> int:
    return get-data-uint RETRIES

  /**
   * 0 - 1
   */
  priority -> int:
    return get-data-uint PRIORITY

  stringify -> string:
    return {
      "GPS Search": gps-search,
      "Payload": payload,
      "Retries": retries,
      "Priority": priority,
    }.stringify
