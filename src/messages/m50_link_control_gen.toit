import ..protocol as protocol

// Auto generated class for protocol message
class LinkControl extends protocol.Data:

  static MT := 50
  static MT_NAME := "LinkControl"

  static IP-ADDRESS := 1
  static PORT := 2
  static ENABLE := 3
  static FQDN := 4

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
  static data --ip-address/string?=null --port/int?=null --enable/bool?=null --fqdn/string?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if ip-address != null: data.add-data-ascii IP-ADDRESS ip-address
    if port != null: data.add-data-uint PORT port
    if enable != null: data.add-data-bool ENABLE enable
    if fqdn != null: data.add-data-ascii FQDN fqdn
    return data

  /**
   * Creates a GET Request message for Link Control.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a SET Request message for Link Control.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * IP Address of the link, if not using FQDN
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

  /**
   * FQDN of the link, if not using IP address
   */
  fqdn -> string:
    return get-data-ascii FQDN

  stringify -> string:
    return {
      "ip": ip-address,
      "port": port,
      "enable": enable,
      "fqdn": fqdn,
    }.stringify
