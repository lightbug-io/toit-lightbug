import ble
import io
import monitor
import log
import ...util.bytes as bytes

/**
BLE module for handling Bluetooth Low Energy scan operations.

Provides a clean interface for performing BLE scans with specified duration
and handling the scan results locally on the ESP32.
*/
class BLE:
  logger_/log.Logger
  adapter_/ble.Adapter

  constructor --logger/log.Logger:
    logger_ = logger
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
  raw_/ByteArray
  device-address_/ByteArray
  device-name_/string
  rssi_/int
  connectable_/bool

  constructor --raw/ByteArray --device-address/ByteArray --device-name/string --rssi/int --connectable/bool:
    raw_ = raw
    device-address_ = device-address
    device-name_ = device-name
    rssi_ = rssi
    connectable_ = connectable

  /**
  Creates a BLEScanResult from a ble.RemoteScannedDevice.
  */
  static from-device device/ble.RemoteScannedDevice -> BLEScanResult:
    device-name := device.data.name or ""
    return BLEScanResult
        --raw=device.data.to-raw or #[]
        --device-address=device.address-bytes or #[]
        --device-name=device-name
        --rssi=device.rssi
        --connectable=device.is-connectable

  raw -> ByteArray: return raw_
  device-address -> ByteArray: return device-address_
  device-name -> string: return device-name_
  rssi -> int: return rssi_
  connectable -> bool: return connectable_

  formatted-address -> string:
    return bytes.format-mac device-address_

  /**
  Extract iBeacon information if present in the advertisement.
  Returns a Map with keys: uuid, major, minor, tx-power, or null if not an iBeacon.
  */
  ibeacon-info -> Map?:
    // If there's no raw advertisement, nothing to parse
    if not raw_ or raw_.size == 0: return null

    // Parse the raw advertisement into an Advertisement to access manufacturer-specific block
    adv := ble.Advertisement.raw raw_
    // The SDK's manufacturer-specific API calls the block with (company_id, manufacturer_data)
    result := null
    adv.manufacturer-specific: | company_id m |
      // Expect manufacturer_data length of at least 23 (iBeacon payload)
      if m and m.size >= 23:
        // iBeacon has type 0x02 and length 0x15 in the first two bytes of manufacturer data
        if m[0] == 0x02 and m[1] == 0x15:
          uuid := m[2 .. 17]
          major := (m[18] << 8) + m[19]
          minor := (m[20] << 8) + m[21]
          tx := m[22]
          if tx > 127: tx = tx - 256
          result = {
            "uuid": uuid,
            "major": major,
            "minor": minor,
            "tx-power": tx
          }

    return result

  stringify -> string:
    return "BLE Device: $(formatted-address) '$(device-name_)' RSSI:$(rssi_)dBm connectable:$(connectable_)"
