import ..protocol as protocol

class TxNow extends protocol.Data:
  static MT := 30
  static SEARCH-GPS := 1
  static DATA := 2
  static RETRIES := 3
  static PRIORITY := 4

  static doMsg --searchGps/int?=null --data/ByteArray?=null --retries/int?=null --priority/int?=null -> protocol.Message:
    msg := protocol.Message MT
    if searchGps:
      msg.data.add-data-uint8 SEARCH-GPS searchGps
    if data:
      msg.data.add-data DATA data
    if retries:
      msg.data.add-data-uint8 RETRIES retries
    if priority:
      msg.data.add-data-uint8 PRIORITY priority
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  searchGps -> int:
    return get-data-uint8 SEARCH-GPS

  data -> ByteArray:
    return get-data DATA

  retries -> int:
    return get-data-uint8 RETRIES

  priority -> int:
    return get-data-uint8 PRIORITY

  stringify -> string:
    return {
      "Search GPS": searchGps,
      "Data": data,
      "Retries": retries,
      "Priority": priority,
    }.stringify
