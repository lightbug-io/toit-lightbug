import ..protocol as protocol

// Auto generated class for protocol message
class TransmitNow extends protocol.Data:

  static MT := 30
  static MT_NAME := "TransmitNow"

  static SEARCH-GPS := 1
  static DATA := 2
  static RETRIES := 3
  static PRIORITY := 4

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // DO
  static do-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  search-gps -> int:
    return get-data-uint SEARCH-GPS

  data -> int:
    return get-data-uint DATA

  retries -> int:
    return get-data-uint RETRIES

  priority -> int:
    return get-data-uint PRIORITY

  stringify -> string:
    return {
      "Search GPS": search-gps,
      "Data": data,
      "Retries": retries,
      "Priority": priority,
    }.stringify
