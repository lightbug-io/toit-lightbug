import ...protocol as protocol
import ...messages as messages
import ...devices as devices
import ..comms.message-handler show MessageHandler
import log
import ...util.bytes as bytes

/** Handles WiFi scan subscriptions (MT55). */
class WiFiHandler implements MessageHandler:
  static MESSAGE-TYPE := messages.WiFiScan.MT
  static DURATION-HEADER-FIELD := protocol.Header.TYPE-SUBSCRIPTION-DURATION
  static CONTINUOUS-SCAN-DURATION-MS := 3000

  logger_/log.Logger
  device_/any
  scan-generation_/int := 0
  scan-task_/Task? := null
  report-task_/Task? := null
  pending-results_/Map := Map

  constructor device/any --logger/log.Logger:
    logger_ = logger
    device_ = device

  handle-message msg/protocol.Message -> bool:
    if msg.type != MESSAGE-TYPE: return false
    if not msg.header-has-data protocol.Header.TYPE-MESSAGE-METHOD:
      logger_.warn "WiFi message missing method type"
      return false

    method := msg.header-get-data-uint protocol.Header.TYPE-MESSAGE-METHOD
    if method == protocol.Header.METHOD_UNSUBSCRIBE:
      logger_.info "Stopping WiFi scan subscription"
      stop-subscription_
      acknowledge-request msg.msgId
      return true
    if method != protocol.Header.METHOD_SUBSCRIBE:
      logger_.debug "WiFi message with unsupported method: $method"
      return false

    // One scan subscription per radio. A new request supersedes the previous
    // one, including an unbounded subscription.
    stop-subscription_
    generation := scan-generation_
    duration := extract-scan-duration msg
    reporting-interval := extract-reporting-interval msg
    request-msg-id := msg.msgId

    acknowledge-request request-msg-id
    forwarded-for := msg.was-forwarded ? msg.forwarded-for : null
    start-report-task_ generation reporting-interval request-msg-id forwarded-for
    scan-task_ = task --background=true::
      perform-wifi-scan generation duration reporting-interval request-msg-id forwarded-for
    return true

  acknowledge-request request-msg-id/int?:
    if request-msg-id == null: return
    ack-msg := messages.ACK.msg --data=null
    ack-msg.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
    ack-msg.header-add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS-OK
    device_.comms.send ack-msg --now=true

  // Missing or zero duration means an unbounded subscription.
  extract-scan-duration msg/protocol.Message -> int?:
    if msg.header-has-data DURATION-HEADER-FIELD:
      duration := msg.header-get-data-uint DURATION-HEADER-FIELD
      logger_.debug "WiFi scan duration from header: $(duration)ms"
      if duration > 0: return duration
    logger_.debug "WiFi scan duration is infinite"
    return null

  // A non-zero subscription interval is a reporting period in milliseconds.
  extract-reporting-interval msg/protocol.Message -> int:
    if msg.header-has-data protocol.Header.TYPE-SUBSCRIPTION-INTERVAL:
      interval := msg.header-get-data-uint protocol.Header.TYPE-SUBSCRIPTION-INTERVAL
      logger_.debug "WiFi reporting interval from header: $(interval)ms"
      return interval
    return 0

  perform-wifi-scan generation/int duration/int? reporting-interval/int request-msg-id/int? request-msg-forwarded-for/int?:
    if duration == null:
      logger_.info "Starting infinite WiFi scan subscription (reporting interval=$(reporting-interval)ms)"
    else:
      logger_.info "Starting WiFi scan for $(duration)ms (reporting interval=$(reporting-interval)ms)"
    e := catch --trace:
      if duration == null:
        // There is no native infinite WiFi scan. Repeat full-band scan passes.
        // When batching is requested, its period is also the pass budget.
        pass-duration := reporting-interval > 0 ? reporting-interval : CONTINUOUS-SCAN-DURATION-MS
        while generation == scan-generation_:
          device_.wifi.scan --stream --duration=pass-duration --onSeen=(:: | ap |
            record-or-send-ap_ generation reporting-interval ap request-msg-id request-msg-forwarded-for
          )
      else if reporting-interval > 0:
        // Chunked scans make APs available throughout the finite scan, while
        // the reporting task determines when they leave the ESP.
        device_.wifi.scan --stream --duration=duration --onSeen=(:: | ap |
          record-or-send-ap_ generation reporting-interval ap request-msg-id request-msg-forwarded-for
        )
      else:
        // Preserve legacy finite/no-interval behaviour.
        scan-results := device_.wifi.scan --duration=duration
        scan-results.do: | ap |
          record-or-send-ap_ generation reporting-interval ap request-msg-id request-msg-forwarded-for

      if generation != scan-generation_: return
      if duration != null:
        flush-pending-results_ generation request-msg-id request-msg-forwarded-for
        finish-subscription_ generation request-msg-id request-msg-forwarded-for

    if e and generation == scan-generation_:
      error-msg := protocol.Message.with-data messages.WiFiScan.MT messages.WiFiScan.data
      error-msg.header-add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS_GENERIC_ERROR
      if request-msg-id != null:
        error-msg.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
      if request-msg-forwarded-for != null:
        error-msg.header-add-data-uint8 protocol.Header.TYPE-FORWARD-TO request-msg-forwarded-for
      device_.comms.send error-msg
      logger_.error "Error during WiFi scan: $e"
      finish-subscription_ generation null null

  stop-subscription_:
    scan-generation_ += 1
    if scan-task_:
      scan-task_.cancel
      scan-task_ = null
    if report-task_:
      report-task_.cancel
      report-task_ = null
    pending-results_ = Map

  start-report-task_ generation/int reporting-interval/int request-msg-id/int? request-msg-forwarded-for/int?:
    if reporting-interval <= 0: return
    report-task_ = task --background=true::
      while generation == scan-generation_:
        sleep --ms=reporting-interval
        if generation == scan-generation_:
          flush-pending-results_ generation request-msg-id request-msg-forwarded-for

  record-or-send-ap_ generation/int reporting-interval/int ap request-msg-id/int? request-msg-forwarded-for/int?:
    if generation != scan-generation_: return
    if reporting-interval <= 0:
      send-ap-response ap request-msg-id request-msg-forwarded-for
      return
    pending-results_[wifi-ap-key_ ap] = ap

  flush-pending-results_ generation/int request-msg-id/int? request-msg-forwarded-for/int?:
    if generation != scan-generation_: return
    batch := pending-results_
    pending-results_ = Map
    batch.do: | _ ap |
      if generation == scan-generation_:
        send-ap-response ap request-msg-id request-msg-forwarded-for

  finish-subscription_ generation/int request-msg-id/int? request-msg-forwarded-for/int?:
    if generation != scan-generation_: return
    if report-task_:
      report-task_.cancel
      report-task_ = null
    scan-task_ = null
    pending-results_ = Map
    expired-msg := protocol.Message.with-data messages.WiFiScan.MT messages.WiFiScan.data
    expired-msg.header-add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS-EXPIRED
    if request-msg-id != null:
      expired-msg.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
    if request-msg-forwarded-for != null:
      expired-msg.header-add-data-uint8 protocol.Header.TYPE-FORWARD-TO request-msg-forwarded-for
    device_.comms.send expired-msg

  wifi-ap-key_ ap -> string:
    if ap.bssid: return bytes.format-mac ap.bssid
    ssid := ap.ssid or ""
    channel := ap.channel or 0
    return "$ssid/$channel"

  send-ap-response ap request-msg-id/int? request-msg-forwarded-for/int?:
    ssid := ap.ssid or ""
    bssid := ap.bssid
    rssi := ap.rssi or 0
    channel := ap.channel or 0
    response-data := messages.WiFiScan.data --ssid=ssid --mac=bssid --rssi=rssi --channel=channel
    response-msg := protocol.Message.with-data messages.WiFiScan.MT response-data
    if request-msg-id != null:
      response-msg.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
    if request-msg-forwarded-for != null:
      response-msg.header-add-data-uint8 protocol.Header.TYPE-FORWARD-TO request-msg-forwarded-for
    device_.comms.send response-msg
