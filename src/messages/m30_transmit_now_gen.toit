import ..protocol as protocol

// Auto generated class for protocol message
class TransmitNow extends protocol.Data:

  static MT := 30
  static MT_NAME := "TransmitNow"

  static GPS-SEARCH := 1
  static PAYLOAD := 2
  static RETRIES := 3
  static PRIORITY := 4

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --gps-search/bool?=null --payload/ByteArray?=null --retries/int?=null --priority/int?=null -> protocol.Data:
    data := protocol.Data
    if gps-search != null: data.add-data-bool GPS-SEARCH gps-search
    if payload != null: data.add-data PAYLOAD payload
    if retries != null: data.add-data-uint RETRIES retries
    if priority != null: data.add-data-uint PRIORITY priority
    return data

  // DO
  static do-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  gps-search -> bool:
    return get-data-bool GPS-SEARCH

  payload -> ByteArray:
    return get-data PAYLOAD

  retries -> int:
    return get-data-uint RETRIES

  priority -> int:
    return get-data-uint PRIORITY

  stringify -> string:
    return {
      "GPS Search": gps-search,
      "Payload": payload,
      "Retries": retries,
      "Priority": priority,
    }.stringify
