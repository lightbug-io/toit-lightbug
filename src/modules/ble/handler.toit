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
    if not msg.header.data.has-data protocol.Header.TYPE-MESSAGE-METHOD:
      logger_.warn "BLE message missing method type"
      return false
    
    method := msg.header.data.get-data-uint protocol.Header.TYPE-MESSAGE-METHOD
    if method != protocol.Header.METHOD_SUBSCRIBE:
      logger_.debug "BLE message with non-SUBSCRUBE method: $method"
      return false
    
    logger_.info "Handling BLE scan request"
    
    duration := extract-scan-duration msg
    request-msg-id := msg.msgId
    
    // If the msg was forwarded, extract the msg source too, so we can forward responses correctly
    forwarded-for := null
    if msg.was-forwarded:
      forwarded-for = msg.forwarded-for
    
    // Perform BLE scan asynchronously
    task --background=true::
      perform-ble-scan duration request-msg-id forwarded-for
    
    return true
  
  /**
   * Extract scan duration from message header field 7.
   * Returns default duration if not specified.
   */
  extract-scan-duration msg/protocol.Message -> int:
    if msg.header.data.has-data protocol.Header.TYPE-SUBSCRIPTION-DURATION:
      duration := msg.header.data.get-data-uint protocol.Header.TYPE-SUBSCRIPTION-DURATION
      logger_.debug "BLE scan duration from header: $(duration)ms"
      return duration
    else:
      default-duration := 3000  // 3 seconds default
      logger_.debug "BLE scan duration not specified, using default: $(default-duration)ms"
      return default-duration
  
  /**
   * Perform the actual BLE scan and send responses.
   */
  perform-ble-scan duration/int request-msg-id/int? request-msg-forwarded-for/int?:
    logger_.info "Starting BLE scan for $(duration)ms"
    
    e := catch --trace:
      scan-results := device_.ble.scan --duration=duration
      
      logger_.info "BLE scan completed, found $(scan-results.size) devices"
      
      // Send a response for each device found
      scan-results.do: | result |
        send-device-response result request-msg-id request-msg-forwarded-for

      expired-msg := protocol.Message.with-data messages.BLEScan.MT messages.BLEScan.data
      expired-msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS-EXPIRED
      if request-msg-id != null:
        expired-msg.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
      if request-msg-forwarded-for != null:
        expired-msg.header.data.add-data-uint8 protocol.Header.TYPE-FORWARD-TO request-msg-forwarded-for
      device_.comms.send expired-msg
      
      logger_.debug "All BLE device responses sent"
    
    if e:
      error-msg := protocol.Message.with-data messages.BLEScan.MT messages.BLEScan.data
      error-msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS_GENERIC_ERROR
      if request-msg-id != null:
        error-msg.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
      if request-msg-forwarded-for != null:
        error-msg.header.data.add-data-uint8 protocol.Header.TYPE-FORWARD-TO request-msg-forwarded-for
      device_.comms.send error-msg
      logger_.error "Error during BLE scan: $e"
  
  /**
   * Send a BLE device seen response for a discovered device.
   */
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
      response-msg.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
    if request-msg-forwarded-for != null:
      response-msg.header.data.add-data-uint8 protocol.Header.TYPE-FORWARD-TO request-msg-forwarded-for

    // Send the response
    device_.comms.send response-msg

    logger_.debug "Sent BLE scan response for $(bytes.format-mac mac-ba) (RSSI: $(rssi)dBm)"
