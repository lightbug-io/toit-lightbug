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
  static MESSAGE-TYPE := 56
  static DURATION-HEADER-FIELD := 7
  
  logger_/log.Logger
  device_/devices.Device
  comms_/any  // Reference to the comms instance for sending responses
  
  constructor device/devices.Device comms/any --logger/log.Logger=(log.default.with-name "lb-ble-handler"):
    logger_ = logger
    device_ = device
    comms_ = comms
  
  /**
   * Handle a BLE scan request message.
   * 
   * Returns true if the message was handled, false otherwise.
   */
  handle-message msg/protocol.Message -> bool:
    // Only handle BLE messages
    if msg.type != MESSAGE-TYPE:
      return false
    
    // Check if this is a GET request (scan request)
    if not msg.header.data.has-data protocol.Header.TYPE-MESSAGE-METHOD:
      logger_.warn "BLE message missing method type"
      return false
    
    method := msg.header.data.get-data-uint protocol.Header.TYPE-MESSAGE-METHOD
    if method != protocol.Header.METHOD-GET:
      logger_.debug "BLE message with non-GET method: $method"
      return false
    
    logger_.info "Handling BLE scan request"
    
    // Extract scan duration from header field 7
    duration := extract-scan-duration msg
    
    // Extract request message ID for responses
    request-msg-id := msg.msgId
    if not request-msg-id:
      logger_.warn "BLE scan request missing message ID - cannot send responses"
      return true  // We handled it, but can't respond
    
    // Perform BLE scan asynchronously
    task --background=true::
      perform-ble-scan duration request-msg-id
    
    return true
  
  /**
   * Extract scan duration from message header field 7.
   * Returns default duration if not specified.
   */
  extract-scan-duration msg/protocol.Message -> int:
    if msg.header.data.has-data DURATION-HEADER-FIELD:
      duration := msg.header.data.get-data-uint DURATION-HEADER-FIELD
      logger_.debug "BLE scan duration from header: $(duration)ms"
      return duration
    else:
      default-duration := 3000  // 3 seconds default
      logger_.debug "BLE scan duration not specified, using default: $(default-duration)ms"
      return default-duration
  
  /**
   * Perform the actual BLE scan and send responses.
   */
  perform-ble-scan duration/int request-msg-id/int:
    logger_.info "Starting BLE scan for $(duration)ms"
    
    e := catch --trace:
      scan-results := device_.ble.scan --duration=duration
      
      logger_.info "BLE scan completed, found $(scan-results.size) devices"
      
      // Send a response for each device found
      scan-results.do: | result |
        send-device-response result request-msg-id
      
      logger_.debug "All BLE device responses sent"
    
    if e:
      logger_.error "Error during BLE scan: $e"
  
  /**
   * Send a BLE device seen response for a discovered device.
   */
  send-device-response result request-msg-id/int:
    // Extract device information
    mac := result.formatted-address
    rssi := result.rssi
    device-name := result.device-name or ""
    is-ibeacon := result.ibeacon-info != null
    
    // iBeacon specific data
    major := 0
    minor := 0
    tx-power := 0
    if is-ibeacon:
      ibeacon := result.ibeacon-info
      major = ibeacon["major"]
      minor = ibeacon["minor"] 
      tx-power = ibeacon["tx-power"]
    
    // Count services as sensor count
    sensor-count := result.service-classes ? result.service-classes.size : 0
    
    // Create the response data
    response-data := messages.BLEDevice.data 
        --mac-address=mac
        --rssi=rssi
        --is-ibeacon=is-ibeacon
        --device-name=device-name
        --ibeacon-major=major
        --ibeacon-minor=minor
        --ibeacon-tx-power=tx-power
        --sensor-count=sensor-count
    
    // Create response message
    response-msg := messages.BLEDevice.response-msg 
        --response-to-id=request-msg-id
        --base-data=response-data
    
    // Send the response
    comms_.send response-msg --now=true
    
    logger_.debug "Sent BLE device response for $(mac) (RSSI: $(rssi)dBm)"
