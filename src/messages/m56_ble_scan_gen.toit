import ..protocol as protocol

// Auto generated class for protocol message
class BLEScan extends protocol.Data:

  static MT := 56
  static MT_NAME := "BLEScan"

  static ADVERTISING-DATA := 1
  static MAC := 2
  static RSSI := 3
  static NAME := 4
  static SCAN-RESPONSE := 5
  static ACTIVE-SCAN-REQUEST := 6

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
  static data --advertising-data/ByteArray?=null --mac/ByteArray?=null --rssi/int?=null --name/string?=null --scan-response/ByteArray?=null --active-scan-request/bool?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if advertising-data != null: data.add-data ADVERTISING-DATA advertising-data
    if mac != null: data.add-data MAC mac
    if rssi != null: data.add-data-int8 RSSI rssi
    if name != null: data.add-data-ascii NAME name
    if scan-response != null: data.add-data SCAN-RESPONSE scan-response
    if active-scan-request != null: data.add-data-bool ACTIVE-SCAN-REQUEST active-scan-request
    return data

  // Subscribe to a message with an optional interval in milliseconds
  static subscribe-msg --interval/int?=null --duration/int?=null --timeout/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    // Subscription header options - only add when provided
    if interval != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL interval
    if duration != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-DURATION duration
    if timeout != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-TIMEOUT timeout
    return msg

  /**
   * Advertising Data
   */
  advertising-data -> ByteArray:
    return get-data ADVERTISING-DATA

  /**
   * MAC Address of the access point, as 6 bytes
   */
  mac -> ByteArray:
    return get-data MAC

  /**
   * Signal strength
   */
  rssi -> int:
    return get-data-int RSSI

  /**
   * Device name, if available
   */
  name -> string:
    return get-data-ascii NAME

  /**
   * Raw scan response payload, if available
   */
  scan-response -> ByteArray:
    return get-data SCAN-RESPONSE

  /**
   * Perform an active scan, valid only for SUBSCRIBE
   */
  active-scan-request -> bool:
    return get-data-bool ACTIVE-SCAN-REQUEST

  stringify -> string:
    return {
      "advertisingData": advertising-data,
      "mac": mac,
      "rssi": rssi,
      "name": name,
      "scanResponse": scan-response,
      "activeScanRequest": active-scan-request,
    }.stringify
