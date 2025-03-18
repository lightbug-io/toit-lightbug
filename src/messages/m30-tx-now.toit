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
      msg.data.addDataUint8 SEARCH-GPS searchGps
    if data:
      msg.data.addData DATA data
    if retries:
      msg.data.addDataUint8 RETRIES retries
    if priority:
      msg.data.addDataUint8 PRIORITY priority
    msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  searchGps -> int:
    return getDataUint8 SEARCH-GPS

  data -> ByteArray:
    return getData DATA

  retries -> int:
    return getDataUint8 RETRIES

  priority -> int:
    return getDataUint8 PRIORITY

  stringify -> string:
    return {
      "Search GPS": searchGps,
      "Data": data,
      "Retries": retries,
      "Priority": priority,
    }.stringify
