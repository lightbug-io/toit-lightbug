import lightbug.modules.wifi.handler show WiFiHandler
import lightbug.messages show WiFiScan
import lightbug.protocol as protocol
import log

class FakeAP:
  ssid_/string
  bssid_/ByteArray
  rssi_/int
  channel_/int
  constructor ssid/string bssid/ByteArray rssi/int channel/int:
    ssid_ = ssid
    bssid_ = bssid
    rssi_ = rssi
    channel_ = channel
  ssid -> string: return ssid_
  bssid -> ByteArray: return bssid_
  rssi -> int: return rssi_
  channel -> int: return channel_

class FakeWiFi:
  scan --duration/int --channels/ByteArray?=null --passive/bool=false --filter/Lambda?=null -> List:
    return [ FakeAP "Office" #[0x01,0x02,0x03,0x04,0x05,0x06] -50 1 ]

class FakeDevice:
  wifi_/FakeWiFi
  constructor: wifi_ = FakeWiFi
  wifi -> FakeWiFi: return wifi_

class FakeComms:
  send msg/protocol.Message --now/bool=false:
    print "Would send: $(msg.stringify)"
    return true

main:
  device := FakeDevice
  comms := FakeComms
  handler := WiFiHandler device comms

  req := WiFiScan.subscribe-msg --duration=1500
  req.with-random-msg-id
  print "Request: $(req.stringify)"
  handler.handle-message req
  sleep --ms=200
