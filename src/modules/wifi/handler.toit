import ...protocol as protocol
import ...messages as messages
import ...devices as devices
import ..comms.message-handler show MessageHandler
import log
import ...util.bytes as bytes

/**
 * Handler for WiFi scan request messages.
 *
 * This handler responds to WiFi scan requests by extracting the
 * scan duration from header field 7, performing a WiFi scan using
 * the device's WiFi module, and sending back WiFi access point
 * responses for each discovered access point.
 */
class WiFiHandler implements MessageHandler:
  static MESSAGE-TYPE := messages.WiFiScan.MT
  static DURATION-HEADER-FIELD := protocol.Header.TYPE-SUBSCRIPTION-DURATION

  logger_/log.Logger
  device_/any

  constructor device/any --logger/log.Logger:
    logger_ = logger
    device_ = device

  handle-message msg/protocol.Message -> bool:
    if msg.type != MESSAGE-TYPE:
      return false

    if not msg.header.data.has-data protocol.Header.TYPE-MESSAGE-METHOD:
      logger_.warn "WiFi message missing method type"
      return false

    method := msg.header.data.get-data-uint protocol.Header.TYPE-MESSAGE-METHOD
    if method != protocol.Header.METHOD-SUBSCRIBE:
      logger_.debug "WiFi message with non-SUBSCRIBE method: $method"
      return false

    logger_.info "Handling WiFi scan subscription"

    duration := extract-scan-duration msg

    request-msg-id := msg.msgId
    if not request-msg-id:
      logger_.warn "WiFi scan request missing message ID - cannot send responses"
      return true

    task --background=true::
      perform-wifi-scan duration request-msg-id

    return true

  extract-scan-duration msg/protocol.Message -> int:
    if msg.header.data.has-data DURATION-HEADER-FIELD:
      duration := msg.header.data.get-data-uint DURATION-HEADER-FIELD
      logger_.debug "WiFi scan duration from header: $(duration)ms"
      return duration
    else:
      default-duration := 3000
      logger_.debug "WiFi scan duration not specified, using default: $(default-duration)ms"
      return default-duration

  perform-wifi-scan duration/int request-msg-id/int:
    logger_.info "Starting WiFi scan for $(duration)ms"

    e := catch --trace:
      scan-results := device_.wifi.scan --duration=duration

      logger_.info "WiFi scan completed, found $(scan-results.size) access points"

      scan-results.do: | ap |
        send-ap-response ap request-msg-id
      
      expired-msg := protocol.Message.with-data messages.WiFiScan.MT messages.WiFiScan.data
      expired-msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS-EXPIRED
      expired-msg.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
      device_.comms.send expired-msg

      logger_.debug "All WiFi AP responses sent"

    if e:
      error-msg := protocol.Message.with-data messages.WiFiScan.MT messages.WiFiScan.data
      error-msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS protocol.Header.STATUS_GENERIC_ERROR
      error-msg.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id
      device_.comms.send error-msg
      logger_.error "Error during WiFi scan: $e"

  send-ap-response ap request-msg-id/int:
    ssid := ap.ssid
    if not ssid: ssid = ""

    bssid := null
    if ap.bssid: bssid = ap.bssid

    rssi := 0
    if ap.rssi: rssi = ap.rssi

    channel := 0
    if ap.channel: channel = ap.channel

    response-data := messages.WiFiScan.data
        --ssid=ssid
        --mac=bssid
        --rssi=rssi
        --channel=channel

    response-msg := protocol.Message.with-data messages.WiFiScan.MT response-data
    response-msg.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request-msg-id

    device_.comms.send response-msg

    mac := bytes.format-mac bssid
    logger_.debug "Sent WiFi AP response for $(ssid) (BSSID: $(mac) RSSI: $(rssi)dBm)"
