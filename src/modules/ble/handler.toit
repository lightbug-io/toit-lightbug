import ...protocol as protocol
import ...messages as messages
import ...devices as devices
import ..comms.message-handler show MessageHandler
import ...util.bytes as bytes
import log

/**
 * Handler for BLE scan request messages.
 * 
 * This handler responds to BLE scan requests (message type 56) by:
 * 1. Extracting the scan duration from header field 7
 * 2. Performing a BLE scan using the device's BLE module
 * 3. Sending back BLE device seen responses for each discovered device
 */
class BLEHandler implements MessageHandler:
  logger_/log.Logger
  device_/devices.Device
  scan-generation_/int := 0
  scan-task_/Task? := null
  report-task_/Task? := null
  pending-results_/Map := Map
  
  constructor device/devices.Device --logger/log.Logger:
    logger_ = logger
    device_ = device
  
  /**
   * Handle a BLE scan request message.
   * 
   * Returns true if the message was handled, false otherwise.
   */
  handle-message msg/protocol.Message -> bool:
    // Only handle BLE messages
    if msg.type != messages.BLEScan.MT:
      return false
    
    // Check if this is a GET request (scan request)
    if not msg.header-has-data protocol.Header.TYPE-MESSAGE-METHOD:
      logger_.warn "BLE message missing method type"
      return false
    
    method := msg.header-get-data-uint protocol.Header.TYPE-MESSAGE-METHOD
    if method == protocol.Header.METHOD_UNSUBSCRIBE:
      logger_.info "Stopping BLE scan subscription"
      stop-subscription_
      acknowledge-request msg.msgId
      return true

    if method != protocol.Header.METHOD_SUBSCRIBE:
      logger_.debug "BLE message with non-SUBSCRUBE method: $method"
      return false
    
    logger_.info "Handling BLE scan request"
    
    stop-subscription_
    generation := scan-generation_
    duration := extract-scan-duration msg
    reporting-interval := extract-reporting-interval msg
    active := extract-active-scan-request msg
    scan-interval := extract-scan-interval msg
    scan-window := extract-scan-window msg
    request-msg-id := msg.msgId

    // Returning true suppresses Comms' generic ACK policy. P1 treats an OK
    // ACK for MID_BLE_SCAN as "scan started" and otherwise retries the request
    // after its ACK timeout, so acknowledge before launching the async work.
    acknowledge-request request-msg-id
    
    // If the msg was forwarded, extract the msg source too, so we can forward responses correctly
    forwarded-for := null
    if msg.was-forwarded:
      forwarded-for = msg.forwarded-for
    
    start-report-task_ generation reporting-interval request-msg-id forwarded-for

    // Perform BLE scan asynchronously. A newer subscription or UNSUBSCRIBE
    // cancels this task and invalidates its callbacks using $generation.
    scan-task_ = task --background=true::
      perform-ble-scan generation duration active scan-interval scan-window reporting-interval request-msg-id forwarded-for
    
    return true

  acknowledge-request request-msg-id/int?:
    if request-msg-id == null: return
    ack-msg := messages.ACK.msg --data=null
    ack-msg.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
    ack-msg.header-add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS-OK
    // Match Comms' generic ACK path: make this control traffic immediate.
    device_.comms.send ack-msg --now=true
  
  /**
   * Extract scan duration from message header field 7.
   * Missing or zero duration means an unbounded subscription.
   */
  extract-scan-duration msg/protocol.Message -> int?:
    if msg.header-has-data protocol.Header.TYPE-SUBSCRIPTION-DURATION:
      duration := msg.header-get-data-uint protocol.Header.TYPE-SUBSCRIPTION-DURATION
      logger_.debug "BLE scan duration from header: $(duration)ms"
      if duration > 0: return duration
    logger_.debug "BLE scan duration is infinite"
    return null

  extract-reporting-interval msg/protocol.Message -> int:
    if msg.header-has-data protocol.Header.TYPE-SUBSCRIPTION-INTERVAL:
      interval := msg.header-get-data-uint protocol.Header.TYPE-SUBSCRIPTION-INTERVAL
      logger_.debug "BLE reporting interval from header: $(interval)ms"
      return interval
    return 0

  extract-active-scan-request msg/protocol.Message -> bool:
    ble-scan := messages.BLEScan.from-data msg.data
    if ble-scan.has-data messages.BLEScan.ACTIVE-SCAN-REQUEST:
      active := ble-scan.active-scan-request
      logger_.debug "BLE active scan requested: $active"
      return active
    return false

  // These are raw Central.scan controller units (0.625 ms), not milliseconds.
  // Zero is the SDK default, and preserves legacy requests that omit the field.
  extract-scan-interval msg/protocol.Message -> int:
    ble-scan := messages.BLEScan.from-data msg.data
    if ble-scan.has-data messages.BLEScan.SCAN-INTERVAL:
      interval := ble-scan.scan-interval
      logger_.debug "BLE scan interval from data: $(interval) controller units"
      return interval
    return 0

  extract-scan-window msg/protocol.Message -> int:
    ble-scan := messages.BLEScan.from-data msg.data
    if ble-scan.has-data messages.BLEScan.SCAN-WINDOW:
      window := ble-scan.scan-window
      logger_.debug "BLE scan window from data: $(window) controller units"
      return window
    return 0
  
  /**
   * Perform the actual BLE scan and send responses.
   */
  perform-ble-scan generation/int duration/int? active/bool scan-interval/int scan-window/int reporting-interval/int request-msg-id/int? request-msg-forwarded-for/int?:
    if duration == null:
      logger_.info "Starting infinite BLE scan (active=$(active), interval=$(scan-interval), window=$(scan-window))"
    else:
      logger_.info "Starting BLE scan for $(duration)ms (active=$(active), interval=$(scan-interval), window=$(scan-window))"
    
    e := catch --trace:
      responses-sent := device_.ble.scan --stream --duration=duration --active=active --interval-units=scan-interval --window-units=scan-window --onSeen=(:: | result |
        record-or-send-result_ generation reporting-interval result request-msg-id request-msg-forwarded-for
      )
      
      if generation != scan-generation_: return
      logger_.info "BLE scan completed, found $(responses-sent) devices"
      flush-pending-results_ generation request-msg-id request-msg-forwarded-for
      finish-subscription_ generation request-msg-id request-msg-forwarded-for
    
    if e and generation == scan-generation_:
      error-msg := protocol.Message.with-data messages.BLEScan.MT messages.BLEScan.data
      error-msg.header-add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS_GENERIC_ERROR
      if request-msg-id != null:
        error-msg.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
      if request-msg-forwarded-for != null:
        error-msg.header-add-data-uint8 protocol.Header.TYPE-FORWARD-TO request-msg-forwarded-for
      device_.comms.send error-msg
      logger_.error "Error during BLE scan: $e"
      finish-subscription_ generation null null
  
  /**
   * Send a BLE device seen response for a discovered device.
   */
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

  record-or-send-result_ generation/int reporting-interval/int result request-msg-id/int? request-msg-forwarded-for/int?:
    if generation != scan-generation_: return
    if reporting-interval <= 0:
      send-device-response result request-msg-id request-msg-forwarded-for
      return
    pending-results_[bytes.format-mac result.device-address] = result

  flush-pending-results_ generation/int request-msg-id/int? request-msg-forwarded-for/int?:
    if generation != scan-generation_: return
    batch := pending-results_
    pending-results_ = Map
    batch.do: | _ result |
      if generation == scan-generation_:
        send-device-response result request-msg-id request-msg-forwarded-for

  finish-subscription_ generation/int request-msg-id/int? request-msg-forwarded-for/int?:
    if generation != scan-generation_: return
    if report-task_:
      report-task_.cancel
      report-task_ = null
    scan-task_ = null
    pending-results_ = Map
    expired-msg := protocol.Message.with-data messages.BLEScan.MT messages.BLEScan.data
    expired-msg.header-add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS-EXPIRED
    if request-msg-id != null:
      expired-msg.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
    if request-msg-forwarded-for != null:
      expired-msg.header-add-data-uint8 protocol.Header.TYPE-FORWARD-TO request-msg-forwarded-for
    device_.comms.send expired-msg

  send-device-response result request-msg-id/int? request-msg-forwarded-for/int?:
    mac-ba := result.device-address  // ByteArray
    rssi := result.rssi
    advertising := result.raw or #[]

    response-data := messages.BLEScan.data
      --advertising-data=advertising
      --mac=mac-ba
      --rssi=rssi

    // Construct a protocol message and set response-to header so it ties back to the request.
    response-msg := protocol.Message.with-data messages.BLEScan.MT response-data
    if request-msg-id != null:
      response-msg.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
    if request-msg-forwarded-for != null:
      response-msg.header-add-data-uint8 protocol.Header.TYPE-FORWARD-TO request-msg-forwarded-for

    // Send the response
    device_.comms.send response-msg

    logger_.with-level log.TRACE-LEVEL:
      logger_.trace "Sent BLE scan response for $(bytes.format-mac mac-ba) (RSSI: $(rssi)dBm)"
