import net.wifi
import monitor
import log
import ...util.bytes as bytes

ALL-CHANNELS := #[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

class WiFi:
  logger_/log.Logger

  constructor --logger/log.Logger:
    logger_ = logger

  /**
  Performs a synchronous WiFi scan and returns the full result set.

  This uses a single full-band scan call. On current Lightbug hardware this has
    shown a comparatively small fixed tail beyond the requested duration. In a
    3 second benchmark on current hardware this completed in roughly
    3.55 to 3.68 seconds. For lower-latency partial delivery or tighter channel
    control, prefer $scan --stream.

  For a reproducible local comparison, see
    `examples/util/wifi-chunk-latency-benchmark.toit`.

  Parameters:
    --duration: Scan duration in milliseconds.
    --channels: Channels to scan.
    --passive: Whether to use passive scanning.
    --filter: Optional filter function to apply to discovered access points.

  Returns: The access points found during the scan.
  */
  scan --duration/int --channels/ByteArray=ALL-CHANNELS --passive/bool=false --filter/Lambda?=null -> List:
    if duration <= 0:
      logger_.warn "Scan duration must be positive, got: $duration"
      return []

    logger_.debug "Starting WiFi scan with duration: $duration ms"
    
    results := []
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

  /**
  Performs a WiFi scan in smaller channel chunks and emits partial results.

  This is useful when you want earlier first results instead of waiting for a
    full-band scan to finish. Results are deduplicated by BSSID before being
    emitted to $onSeen.

  Chunking does add overhead because each chunk is a separate lower-level scan
    call. In a 3 second benchmark on current hardware, full-band scans finished
    in about 3.55 to 3.68 seconds, while chunked scans first emitted results in
    about 1.60 to 1.98 seconds but finished later overall:
    channels-per-chunk=4 took about 3.96 to 3.97 seconds,
    channels-per-chunk=2 took about 4.19 to 4.20 seconds, and
    channels-per-chunk=1 took about 4.76 to 4.78 seconds.

  Use smaller chunk sizes when time-to-first-result matters more than total
    completion time. Use larger chunk sizes, or $scan, when total elapsed time
    matters more than streaming responsiveness.

  For a reproducible local comparison, see
    `examples/util/wifi-chunk-latency-benchmark.toit`.

  Parameters:
    --duration: Total scan duration budget in milliseconds.
    --channels: Channels to scan.
    --channels-per-chunk: Number of channels to scan in each lower-level call.
    --passive: Whether to use passive scanning.
    --filter: Optional filter function to apply to discovered access points.
    --onSeen: Optional callback invoked for each newly discovered access point.

  Returns: The deduplicated access points found across all chunks.
  */
  scan --stream --duration/int --channels/ByteArray=ALL-CHANNELS --channels-per-chunk/int=1 --passive/bool=false --filter/Lambda?=null --onSeen/Lambda?=null -> List:
    if duration <= 0:
      logger_.warn "Scan duration must be positive, got: $duration"
      return []

    if channels-per-chunk <= 0:
      logger_.warn "channels-per-chunk must be positive, got: $channels-per-chunk"
      return []

    logger_.debug "Starting chunked WiFi scan with duration: $duration ms, channels-per-chunk: $channels-per-chunk"

    results := []
    seen-bssids := {}
    per-channel-duration := duration / channels.size
    if per-channel-duration <= 0:
      per-channel-duration = 1

    e := catch:
      channel-start := 0
      while channel-start < channels.size:
        channel-end := min (channel-start + channels-per-chunk) channels.size
        chunk-channels := channels[channel-start..channel-end]

        scan-result := wifi.scan chunk-channels --passive=passive --period-per-channel-ms=per-channel-duration
        scan-result.do: | ap |
          should-emit := true
          if filter:
            should-emit = filter.call ap

          if should-emit:
            bssid-key := wifi-ap-key_ ap
            if not seen-bssids.contains bssid-key:
              seen-bssids.add bssid-key
              results.add ap
              if onSeen:
                onSeen.call ap

        channel-start = channel-end

    if e:
      logger_.error "Chunked WiFi scan failed: $e"
      return []

    logger_.debug "Chunked WiFi scan completed, found $(results.size) access points"
    return results

  /**
  Performs a WiFi scan asynchronously.

  When $onSeen is provided, or when $channels-per-chunk is set, the scan uses
    the chunked streaming implementation so callbacks can fire before the full
    scan budget has elapsed. This improves first-result latency, but it can
    increase total elapsed time compared with a single full-band scan.

  Parameters:
    --duration: Scan duration in milliseconds.
    --channels: Channels to scan.
    --passive: Whether to use passive scanning.
    --filter: Optional filter function to apply to discovered access points.
    --channels-per-chunk: Optional number of channels per lower-level scan call.
    --onSeen: Optional callback invoked for each newly discovered access point.
    --onComplete: Optional callback invoked with the final result list.
    --onError: Optional callback invoked if the scan fails.
  */
  scan --async --duration/int --channels/ByteArray=ALL-CHANNELS --passive/bool=false --filter/Lambda?=null --channels-per-chunk/int?=null --onSeen/Lambda?=null --onComplete/Lambda?=null --onError/Lambda?=null:
    if duration <= 0:
      logger_.warn "Scan duration must be positive, got: $duration"
      if onError:
        onError.call "Invalid duration: $duration"
      return

    logger_.debug "Starting async WiFi scan with duration: $duration ms"

    task::
      results := []
      e := catch:
        if onSeen or channels-per-chunk != null:
          chunk-size := channels-per-chunk or 1
          results = scan --stream --duration=duration --channels=channels --channels-per-chunk=chunk-size --passive=passive --filter=filter --onSeen=onSeen
        else:
          results = scan --duration=duration --channels=channels --passive=passive --filter=filter

      if e:
        logger_.error "Async WiFi scan failed: $e"
        if onError:
          onError.call e.stringify
      else:
        logger_.debug "Async WiFi scan completed, found $(results.size) access points"
        if onComplete:
          onComplete.call results

  wifi-ap-key_ ap -> string:
    if ap.bssid:
      return bytes.format-mac ap.bssid

    ssid := ap.ssid or ""
    channel := ap.channel or 0
    return "$ssid/$channel"

