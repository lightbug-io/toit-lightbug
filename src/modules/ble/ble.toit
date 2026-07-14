import ble
import io
import monitor
import log
import ...util.bytes as bytes

/**
BLE module for handling Bluetooth Low Energy operations.

Provides a clean interface for performing BLE scans with specified duration
and handling the scan results locally on the ESP32, as well as starting
and stopping BLE advertisements.
*/
class BLE:
  logger_/log.Logger
  adapter_/ble.Adapter
  peripheral_/ble.Peripheral? := null
  advertising_/bool := false

  constructor --logger/log.Logger:
    logger_ = logger
    adapter_ = ble.Adapter

  /**
  Performs a BLE scan synchronously (blocks until response).

  Scans for BLE devices locally using the ESP32's BLE adapter and returns
  information about discovered devices.

  In local measurements on Lightbug hardware, BLE scans can overrun the
    requested duration noticeably in dense RF environments. The extra time is
    typically in the BLE stack performing the scan rather than in the callback
    work done by this wrapper. In a 3 second benchmark on current hardware,
    total elapsed time was roughly 5.29 to 6.18 seconds for passive
    list-returning scans, while first discovery inside the scan happened much
    earlier, roughly 0.23 to 0.31 seconds after start. Benchmarking also showed
    that the last callback often arrived well after the requested duration,
    with only about 0.23 seconds of tail after the last callback. In other
    words, the long overrun is mostly not post-scan finalization; the scan is
    still producing discoveries late into the call.

  Parameters:
    --duration: Scan duration in milliseconds.
    --filter: Optional filter function to apply to discovered devices.
    --active: Whether to request scan responses from scannable devices.
    --interval-ms: Optional scan interval in milliseconds.
    --window-ms: Optional scan window in milliseconds.
    --onSeen: Optional callback invoked as devices are discovered during the
      scan, before the final result list is returned.

  Returns: List of BLEScanResult objects containing scan results
  */
  scan --duration/int --filter/Lambda?=null --active/bool=false --interval-ms/int=0 --window-ms/int=0 --onSeen/Lambda?=null -> List:
    results := []
    scan --stream --duration=duration --filter=filter --active=active --interval-ms=interval-ms --window-ms=window-ms --onSeen=(:: | result |
      results.add result
      if onSeen:
        onSeen.call result
    )
    return results

  /**
  Performs a BLE scan and streams devices to a callback as they are discovered.

  This is the lowest-latency BLE scan helper in this module. It is preferable
    for request/response paths that should emit results before the full scan has
    ended.

  Compared with $scan, this mode avoids building and returning a full result
    list, while still using the same lower-level BLE scan primitive.

  In benchmark runs on current hardware, both $scan --duration=... --onSeen=...
    and $scan --stream exposed first results in about 0.23 seconds, which is a
    large improvement in time-to-first-result over waiting for the final list.
    However, total elapsed time remained highly environment-dependent, and
    $scan --stream was not consistently faster than the list-returning forms.
    Treat this mode primarily as a responsiveness improvement, not a guaranteed
    throughput win.

  Parameter sweeps on current hardware also showed that active scanning can
    increase both callback volume and total elapsed time substantially, and that
    forcing interval-ms and window-ms to 100/100 did not reduce elapsed time in
    the measured environment. Treat --active and explicit interval/window tuning
    as experimental controls to benchmark on your target, not as universally
    beneficial optimizations.

  Parameters:
    --duration: Scan duration in milliseconds.
    --filter: Optional filter function to apply to discovered devices.
    --active: Whether to request scan responses from scannable devices.
    --interval-ms: Optional scan interval in milliseconds.
    --window-ms: Optional scan window in milliseconds.
    --onSeen: Optional callback invoked for each device that passes the filter.

  Returns: The number of devices emitted to $onSeen.
  */
  scan --stream --duration/int --filter/Lambda?=null --active/bool=false --interval-ms/int=0 --window-ms/int=0 --onSeen/Lambda?=null -> int:
    if duration <= 0:
      logger_.warn "Scan duration must be positive, got: $duration"
      return 0

    logger_.debug "Starting BLE scan with duration: $duration ms"

    scan-duration := Duration --ms=duration
    central := adapter_.central
    emitted-count := 0
    interval := scan-units-from-ms_ interval-ms
    window := scan-units-from-ms_ window-ms

    e := catch:
      central.scan --duration=scan-duration --interval=interval --window=window --active=active: | device/ble.RemoteScannedDevice |
        scan-result := BLEScanResult.from-device device

        // Apply filter if provided
        should-emit := true
        if filter:
          should-emit = filter.call scan-result

        if should-emit:
          emitted-count++
          if onSeen:
            onSeen.call scan-result

    if e:
      logger_.error "BLE scan failed: $e"
      return 0

    logger_.debug "BLE scan completed, found $(emitted-count) devices"
    return emitted-count

  /**
  Performs a BLE scan asynchronously.
  
  This method performs the scan in a separate task and calls the provided
  callback with the results.
  
  Parameters:
    --duration: Scan duration in milliseconds.
    --filter: Optional filter function to apply to discovered devices.
    --active: Whether to request scan responses from scannable devices.
    --interval-ms: Optional scan interval in milliseconds.
    --window-ms: Optional scan window in milliseconds.
    --onSeen: Optional callback to call for each discovered device while the
      scan is still running.
    --onComplete: Callback to call when scan completes (receives List of results).
    --onError: Optional callback to call if scan fails.

  If you only need streaming side effects and not the final list, prefer
    $scan --stream to avoid list accumulation. If you need early visibility of
    discoveries but still want the final list, use $scan with --onSeen.
  */
  scan --async --duration/int --filter/Lambda?=null --active/bool=false --interval-ms/int=0 --window-ms/int=0 --onSeen/Lambda?=null --onComplete/Lambda?=null --onError/Lambda?=null:
    if duration <= 0:
      logger_.warn "Scan duration must be positive, got: $duration"
      if onError:
        onError.call "Invalid duration: $duration"
      return

    task::
      e := catch:
        results := scan --duration=duration --filter=filter --active=active --interval-ms=interval-ms --window-ms=window-ms --onSeen=onSeen
        if onComplete:
          onComplete.call results
      
      if e:
        logger_.error "Async BLE scan failed: $e"
        if onError:
          onError.call e.stringify

  scan-units-from-ms_ ms/int -> int:
    if ms <= 0:
      return 0
    return max 4 ((ms * 1000 + 312) / 625)

  /**
  Starts BLE advertising with the provided advertisement data.

  Parameters:
    data: The advertisement data to broadcast. Use ble.Advertisement to construct.

  Returns: true if advertising started successfully, false otherwise.
  */
  start-advertise data/ble.Advertisement -> bool:
    if advertising_:
      logger_.warn "Already advertising, stop first before starting a new advertisement"
      return false

    logger_.debug "Starting BLE advertisement"

    e := catch:
      if not peripheral_:
        peripheral_ = adapter_.peripheral
      peripheral_.start-advertise data
      advertising_ = true

    if e:
      logger_.error "Failed to start BLE advertisement: $e"
      return false

    logger_.info "BLE advertisement started"
    return true

  /**
  Stops BLE advertising.

  Returns: true if advertising stopped successfully, false otherwise.
  */
  stop-advertise -> bool:
    if not advertising_:
      logger_.warn "Not currently advertising"
      return false

    logger_.debug "Stopping BLE advertisement"

    e := catch:
      if peripheral_:
        peripheral_.stop-advertise
      advertising_ = false

    if e:
      logger_.error "Failed to stop BLE advertisement: $e"
      return false

    logger_.info "BLE advertisement stopped"
    return true

  /**
  Returns whether BLE advertising is currently active.
  */
  is-advertising -> bool:
    return advertising_


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
