import ..protocol as protocol

// Auto generated class for protocol message
class LinkControl extends protocol.Data:

  static MT := 50
  static MT_NAME := "LinkControl"

  static IP-ADDRESS := 1
  static PORT := 2
  static ENABLE := 3

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
  static data --ip-address/string?=null --port/int?=null --enable/bool?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if ip-address != null: data.add-data-ascii IP-ADDRESS ip-address
    if port != null: data.add-data-uint PORT port
    if enable != null: data.add-data-bool ENABLE enable
    return data

  /**
   * Creates a Link Control message without a specific method.
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
   * IP Address of the link
   */
  ip-address -> string:
    return get-data-ascii IP-ADDRESS

  /**
   * UDP Port for the link
   */
  port -> int:
    return get-data-uint PORT

  /**
   * Enable or disable the link
   */
  enable -> bool:
    return get-data-bool ENABLE

  stringify -> string:
    return {
      "IP Address": ip-address,
      "Port": port,
      "Enable": enable,
    }.stringify
