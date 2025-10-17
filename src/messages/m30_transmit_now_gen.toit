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
   * Creates a Transmit Now message without a specific method.
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
   * 0 = no gps fix required
   * 1 = wait for GPS lock (or timeout) before send
   */
  gps-search -> bool:
    return get-data-bool GPS-SEARCH

  /**
   * Data to send, can be up to 200 bytes.
   * Only supported by devices that support uart_blob sensorReading type. (Currently only Vipers)
   */
  payload -> ByteArray:
    return get-data PAYLOAD

  /**
   * Number of retries [0-10]. Exponential backoff (10 = 25h)
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
