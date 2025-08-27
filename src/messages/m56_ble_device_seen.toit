import ..protocol as protocol

// Auto generated class for protocol message
class BLEDevice extends protocol.Data:

  static MT := 56
  static MT_NAME := "BLEDevice"

  static MAC-ADDRESS := 1
  static RSSI := 2
  static IS-IBEACON := 3
  static DEVICE-NAME := 4
  static IBEACON-MAJOR := 5
  static IBEACON-MINOR := 6
  static IBEACON-TX-POWER := 7
  static SENSOR-COUNT := 8

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
  static data --mac-address/string?=null --rssi/int?=null --is-ibeacon/bool?=null --device-name/string?=null --ibeacon-major/int?=null --ibeacon-minor/int?=null --ibeacon-tx-power/int?=null --sensor-count/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if mac-address != null: data.add-data-ascii MAC-ADDRESS mac-address
    if rssi != null: data.add-data-int32 RSSI rssi
    if is-ibeacon != null: data.add-data-bool IS-IBEACON is-ibeacon
    if device-name != null: data.add-data-ascii DEVICE-NAME device-name
    if ibeacon-major != null: data.add-data-uint IBEACON-MAJOR ibeacon-major
    if ibeacon-minor != null: data.add-data-uint IBEACON-MINOR ibeacon-minor
    if ibeacon-tx-power != null: data.add-data-int32 IBEACON-TX-POWER ibeacon-tx-power
    if sensor-count != null: data.add-data-uint SENSOR-COUNT sensor-count
    return data

  /**
  Creates a GET Request message for BLE Scan with a duration.
  
  This is the request message that triggers BLE scanning.
  
  Parameters:
  - duration: Scan duration in milliseconds (stored in header field 7)
  
  Returns: A Message ready to be sent
  */
  static get-msg --duration/int=3000 --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-method MT protocol.Header.METHOD-GET base-data
    // Add duration to header field 7
    msg.header.data.add-data-uint32 7 duration
    return msg

  /**
  Creates a response message for BLE Device Seen.
  
  This is the response message with device data.
  
  Parameters:
  - response-to-id: Message ID this is responding to (stored in header field 3)
  
  Returns: A Message ready to be sent
  */
  static response-msg --response-to-id/int --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT base-data
    // Add response-to field in header field 3
    msg.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID response-to-id
    return msg

  /**
    MAC address of the BLE device
  */
  mac-address -> string:
    return get-data-ascii MAC-ADDRESS

  /**
    Signal strength of the device
    
    Unit: dBm
  */
  rssi -> int:
    return get-data-int RSSI

  /**
    Whether this device is broadcasting as an iBeacon
  */
  is-ibeacon -> bool:
    return get-data-bool IS-IBEACON

  /**
    Device name if available
  */
  device-name -> string:
    return get-data-ascii DEVICE-NAME

  /**
    iBeacon major identifier (only valid if is-ibeacon is true)
  */
  ibeacon-major -> int:
    return get-data-uint IBEACON-MAJOR

  /**
    iBeacon minor identifier (only valid if is-ibeacon is true)
  */
  ibeacon-minor -> int:
    return get-data-uint IBEACON-MINOR

  /**
    iBeacon transmission power (only valid if is-ibeacon is true)
    
    Unit: dBm
  */
  ibeacon-tx-power -> int:
    return get-data-int IBEACON-TX-POWER

  /**
    Number of services/sensors detected on the device
  */
  sensor-count -> int:
    return get-data-uint SENSOR-COUNT

  stringify -> string:
    return {
      "MAC Address": mac-address,
      "RSSI": rssi,
      "Is iBeacon": is-ibeacon,
      "Device Name": device-name,
      "iBeacon Major": ibeacon-major,
      "iBeacon Minor": ibeacon-minor,
      "iBeacon TX Power": ibeacon-tx-power,
      "Sensor Count": sensor-count,
    }.stringify
