import ble
import monitor
import log

/**
BLE module for handling Bluetooth Low Energy scan operations.

Provides a clean interface for performing BLE scans with specified duration
and handling the scan results locally on the ESP32.
*/
class BLE:
  logger_/log.Logger
  adapter_/ble.Adapter

  constructor --logger/log.Logger?=null:
    logger_ = logger ? log.default.with-name "lb-ble" : log.default.with-name "lb-ble"
    adapter_ = ble.Adapter

  /**
  Performs a BLE scan synchronously (blocks until response).
  
  Scans for BLE devices locally using the ESP32's BLE adapter and returns
  information about discovered devices.
  
  Parameters:
    --duration: Scan duration in milliseconds
    --filter: Optional filter function to apply to discovered devices
  
  Returns: List of BLEScanResult objects containing scan results
  */
  scan --duration/int --filter/Lambda?=null -> List:
    if duration <= 0:
      logger_.warn "Scan duration must be positive, got: $duration"
      return []

    logger_.debug "Starting BLE scan with duration: $duration ms"
    
    results := []
    scan-duration := Duration --ms=duration
    central := adapter_.central
    
    e := catch:
      central.scan --duration=scan-duration: | device/ble.RemoteScannedDevice |
        scan-result := BLEScanResult.from-device device
        
        // Apply filter if provided
        if filter:
          if filter.call scan-result:
            results.add scan-result
        else:
          results.add scan-result
    
    if e:
      logger_.error "BLE scan failed: $e"
      return []
    
    logger_.debug "BLE scan completed, found $(results.size) devices"
    return results

  /**
  Performs a BLE scan asynchronously.
  
  This method performs the scan in a separate task and calls the provided
  callback with the results.
  
  Parameters:
    --duration: Scan duration in milliseconds  
    --filter: Optional filter function to apply to discovered devices
    --onComplete: Callback to call when scan completes (receives List of results)
    --onError: Optional callback to call if scan fails
  */
  scan --async --duration/int --filter/Lambda?=null --onComplete/Lambda?=null --onError/Lambda?=null:
    if duration <= 0:
      logger_.warn "Scan duration must be positive, got: $duration"
      if onError:
        onError.call "Invalid duration: $duration"
      return

    task::
      e := catch:
        results := scan --duration=duration --filter=filter
        if onComplete:
          onComplete.call results
      
      if e:
        logger_.error "Async BLE scan failed: $e"
        if onError:
          onError.call e.stringify


/**
Container class for BLE scan results.

Represents information about a single discovered BLE device.
*/
class BLEScanResult:
  duration_/int
  device-address_/ByteArray
  device-name_/string
  rssi_/int
  connectable_/bool
  manufacturer-data_/ByteArray
  service-classes_/List

  constructor --duration/int --device-address/ByteArray --device-name/string --rssi/int --connectable/bool --manufacturer-data/ByteArray --service-classes/List:
    duration_ = duration
    device-address_ = device-address
    device-name_ = device-name
    rssi_ = rssi
    connectable_ = connectable
    manufacturer-data_ = manufacturer-data
    service-classes_ = service-classes

  /**
  Creates a BLEScanResult from a ble.RemoteScannedDevice.
  */
  static from-device device/ble.RemoteScannedDevice -> BLEScanResult:
    // Extract manufacturer data for iBeacon detection
    manufacturer-data := device.data.manufacturer-data
    ibeacon-info := null
    service-uuids := device.data.service-classes
    device-name := device.data.name or ""
    device-address := device.address

    // Check if manufacturer data contains iBeacon info
    if manufacturer-data and manufacturer-data.size >= 25:
      manufacturer-id := manufacturer-data[0] + (manufacturer-data[1] << 8)
      if manufacturer-id == 0x004c:  // Apple manufacturer ID
        beacon-type := manufacturer-data[2]
        beacon-length := manufacturer-data[3]
        if beacon-type == 0x02 and beacon-length == 0x15:  // iBeacon
          // Extract iBeacon data
          uuid := manufacturer-data[4..20]
          major := (manufacturer-data[20] << 8) + manufacturer-data[21]
          minor := (manufacturer-data[22] << 8) + manufacturer-data[23]
          tx-power := manufacturer-data[24]
          ibeacon-info = {
            "uuid": uuid,
            "major": major,
            "minor": minor,
            "tx-power": tx-power
          }

    return BLEScanResult
        --duration=0  // Not applicable for this constructor
        --device-address=device.address-bytes or #[]
        --device-name=device-name
        --rssi=device.rssi
        --connectable=device.is-connectable
        --manufacturer-data=manufacturer-data or #[]
        --service-classes=service-uuids or []

  duration -> int: return duration_
  device-address -> ByteArray: return device-address_
  device-name -> string: return device-name_
  rssi -> int: return rssi_
  connectable -> bool: return connectable_
  manufacturer-data -> ByteArray: return manufacturer-data_
  service-classes -> List: return service-classes_

  /**
  Formats the device address as a human-readable MAC address string.
  */
  formatted-address -> string:
    // Handle the case where address might be 7 bytes long
    start-index := device-address_.size > 6 ? 1 : 0
    result := ""
    
    for i := start-index; i < device-address_.size and i < start-index + 6; i++:
      if i > start-index:
        result += ":"
      result += "$(%02x device-address_[i])"
    
    return result

  /**
  Checks if this device has a specific service UUID.
  */
  has-service service-uuid/ble.BleUuid -> bool:
    return service-classes_.contains service-uuid

  /**
  Extracts iBeacon information if this device is an Apple iBeacon.
  
  Returns a Map with keys: uuid, major, minor, tx-power, or null if not an iBeacon.
  */
  ibeacon-info -> Map?:
    if manufacturer-data_.size < 25:
      return null
    
    manufacturer-id := manufacturer-data_[0] + (manufacturer-data_[1] << 8)
    if manufacturer-id != 0x004c:  // Apple manufacturer ID
      return null
      
    sub-type := manufacturer-data_[2]
    if sub-type != 0x02:  // iBeacon type
      return null
    
    proximity-uuid := manufacturer-data_[4..20]
    major := (manufacturer-data_[20] << 8) + manufacturer-data_[21]
    minor := (manufacturer-data_[22] << 8) + manufacturer-data_[23]
    tx-power := manufacturer-data_[24]
    if tx-power > 127:
      tx-power = tx-power - 256
    
    return {
      "uuid": proximity-uuid,
      "major": major,
      "minor": minor,
      "tx-power": tx-power
    }

  stringify -> string:
    return "BLE Device: $(formatted-address) '$(device-name_)' RSSI:$(rssi_)dBm connectable:$(connectable_)"
