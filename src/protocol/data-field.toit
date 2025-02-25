class DataField:
  data-bytes_ /ByteArray := #[]

  constructor data/ByteArray=#[]:
    if data.size > 255:
      throw "V3 protocol can't have data field of over 255 bytes"
    data-bytes_ = data

  stringify -> string:
    return data-bytes_.stringify

  bytes-for-protocol -> ByteArray:
      b := ByteArray data-bytes_.size + 1
      b[0] = data-bytes_.size
      b.replace 1 data-bytes_ 0 data-bytes_.size
      return b
