import ..protocol as protocol

class WiFiAP extends protocol.Data:

  static MT := 57
  static MT_NAME := "WiFiAP"

  static SSID := 1
  static BSSID := 2
  static RSSI := 3
  static CHANNEL := 4

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  static data --ssid/string?=null --bssid/string?=null --rssi/int?=null --channel/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if ssid != null: data.add-data-ascii SSID ssid
    if bssid != null: data.add-data-ascii BSSID bssid
    if rssi != null: data.add-data-int32 RSSI rssi
    if channel != null: data.add-data-uint CHANNEL channel
    return data

  static get-msg --duration/int=3000 --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-method MT protocol.Header.METHOD-GET base-data
    msg.header.data.add-data-uint32 7 duration
    return msg

  static response-msg --response-to-id/int --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT base-data
    msg.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID response-to-id
    return msg

  ssid -> string:
    return get-data-ascii SSID

  bssid -> string:
    return get-data-ascii BSSID

  rssi -> int:
    return get-data-int RSSI

  channel -> int:
    return get-data-uint CHANNEL

  stringify -> string:
    return {
      "SSID": ssid,
      "BSSID": bssid,
      "RSSI": rssi,
      "Channel": channel,
    }.stringify
