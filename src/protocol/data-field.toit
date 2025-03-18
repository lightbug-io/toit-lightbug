class DataField:
  dataBytes_ /ByteArray := #[]

  constructor data/ByteArray=#[]:
    if data.size > 255:
      throw "V3 protocol can't have data field of over 255 bytes"
    dataBytes_ = data

  stringify -> string:
    return dataBytes_.stringify

  bytes-for-protocol -> ByteArray:
      b := ByteArray dataBytes_.size + 1
      b[0] = dataBytes_.size
      b.replace 1 dataBytes_ 0 dataBytes_.size
      return b