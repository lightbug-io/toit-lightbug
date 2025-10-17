import ..protocol as protocol

// Auto generated class for protocol message
class DeviceIDs extends protocol.Data:

  static MT := 35
  static MT_NAME := "DeviceIDs"

  static ID := 1
  static IMEI := 2
  static ICCID := 3

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
  static data --id/int?=null --imei/string?=null --iccid/string?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if id != null: data.add-data-uint ID id
    if imei != null: data.add-data-ascii IMEI imei
    if iccid != null: data.add-data-ascii ICCID iccid
    return data

  /**
   * Creates a GET Request message for Device IDs.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Unique ID for the device which is used in the cloud API.
   * uint32 or uint64 only
   */
  id -> int:
    return get-data-uint ID

  /**
   * IMEI - 15 characters
   */
  imei -> string:
    return get-data-ascii IMEI

  /**
   * ICCID - 19 to 22 characters
   */
  iccid -> string:
    return get-data-ascii ICCID

  stringify -> string:
    return {
      "ID": id,
      "IMEI": imei,
      "ICCID": iccid,
    }.stringify
