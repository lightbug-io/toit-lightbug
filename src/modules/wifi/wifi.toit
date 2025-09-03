import net.wifi
import monitor
import log

ALL-CHANNELS := #[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

class WiFi:
  logger_/log.Logger

  constructor --logger/log.Logger:
    logger_ = logger

  scan --duration/int --channels/ByteArray=ALL-CHANNELS --passive/bool=false --filter/Lambda?=null -> List:
    if duration <= 0:
      logger_.warn "Scan duration must be positive, got: $duration"
      return []

    logger_.debug "Starting WiFi scan with duration: $duration ms"
    
    results := []
    scan-duration := Duration --ms=duration
    per-channel-duration := duration / channels.size
    
    e := catch:
      scan-result := wifi.scan channels --passive=passive --period-per-channel-ms=per-channel-duration
      // wifi.scan returns a List of access points; add each entry and apply filter if provided
      scan-result.do: |ap|
        if filter:
          if filter.call ap:
            results.add ap
        else:
          results.add ap
    
    if e:
      logger_.error "WiFi scan failed: $e"
      return []
    
    logger_.debug "WiFi scan completed, found $(results.size) access points"
    return results

  // TODO allow the async one to scan each channel separately over time
  // And then can call a callback with incremental results (maybe?)

  scan --async --duration/int --channels/ByteArray=ALL-CHANNELS --passive/bool=false --filter/Lambda?=null --onComplete/Lambda?=null --onError/Lambda?=null:
    if duration <= 0:
      logger_.warn "Scan duration must be positive, got: $duration"
      if onError:
        onError.call "Invalid duration: $duration"
      return

    logger_.debug "Starting async WiFi scan with duration: $duration ms"

    task::
      results := []
      scan-duration := Duration --ms=duration
      per-channel-duration := duration / channels.size

      e := catch:
        scan-result := wifi.scan channels --passive=passive --period-per-channel-ms=per-channel-duration
        // wifi.scan returns a List of access points; add each entry and apply filter if provided
        scan-result.do: |ap|
          if filter:
            if filter.call ap:
              results.add ap
          else:
            results.add ap

      if e:
        logger_.error "Async WiFi scan failed: $e"
        if onError:
          onError.call e.stringify
      else:
        logger_.debug "Async WiFi scan completed, found $(results.size) access points"
        if onComplete:
          onComplete.call results

