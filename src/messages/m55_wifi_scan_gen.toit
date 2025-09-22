import ..protocol as protocol

// Auto generated class for protocol message
class WiFiScan extends protocol.Data:

  static MT := 55
  static MT_NAME := "WiFiScan"

  static SSID := 1
  static MAC := 2
  static RSSI := 3
  static CHANNEL := 4

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  /**
  Creates a protocol.Data object with all available fields for this message type.
  
  This is a comprehensive helper that accepts all possible fields.
  For method-specific usage, consider using the dedicated request/response methods.
  
  Returns: A protocol.Data object with the specified field values
  */
  static data --ssid/string?=null --mac/ByteArray?=null --rssi/int?=null --channel/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if ssid != null: data.add-data-ascii SSID ssid
    if mac != null: data.add-data MAC mac
    if rssi != null: data.add-data-int8 RSSI rssi
    if channel != null: data.add-data-uint CHANNEL channel
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
    SSID of the access point
  */
  ssid -> string:
    return get-data-ascii SSID

  /**
    MAC Address of the access point, as 6 bytes
  */
  mac -> ByteArray:
    return get-data MAC

  /**
    Signal strength of the access point
  */
  rssi -> int:
    return get-data-int RSSI

  /**
    WiFi channel of the access point
  */
  channel -> int:
    return get-data-uint CHANNEL

  stringify -> string:
    return {
      "SSID": ssid,
      "MAC": mac,
      "RSSI": rssi,
      "Channel": channel,
    }.stringify
