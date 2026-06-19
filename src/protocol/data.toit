import io.byte-order show LITTLE-ENDIAN
import log
import coordinate show Coordinate

class Data:
  dataTypes_ /ByteArray := ?
  data_ /ByteArray := ?
  fields_ /int := 0
  data-size_ /int := 0
  serialized-size_ /int := 2

  constructor:
    dataTypes_ = #[]
    data_ = #[]
    fields_ = 0
    data-size_ = 0
    serialized-size_ = 2
  
  constructor.from-data data/Data:
    dataTypes_ = data.dataTypes_
    data_ = data.data_
    fields_ = data.fields_
    data-size_ = data.data-size_
    serialized-size_ = data.serialized-size_
  
  constructor.from-bytes bytes/ByteArray:
    dataTypes_ = #[]
    data_ = #[]
    fields_ = 0
    data-size_ = 0
    serialized-size_ = 2
    this.parse-into bytes 0

  constructor.from-bytes-at bytes/ByteArray offset/int:
    dataTypes_ = #[]
    data_ = #[]
    fields_ = 0
    data-size_ = 0
    serialized-size_ = 2
    this.parse-into bytes offset

  parse-into bytes/ByteArray offset/int -> none:
    if bytes.size < offset + 2:
      throw "V3 OOB: For fields, expected $(offset + 2) got $bytes.size"
    fields := LITTLE-ENDIAN.uint16 bytes offset
    if bytes.size < offset + 2 + fields:
      throw "V3 OOB: For data types, expected $(offset + 2 + fields) got $bytes.size"
    dataTypes_ = bytes[offset + 2..offset + 2 + fields]
    // read data (each is a uint8 length, then that number of bytes)
    index := offset + 2 + fields
    for i := 0; i < fields; i++:
      if index >= bytes.size:
        throw "V3 OOB: For data length, expected $index got $bytes.size"
      length := bytes[index]
      index += 1
      if index + length > bytes.size:
        throw "V3 OOB: For data, expected $(index + length) got $bytes.size"
      index += length
    data-start := offset + 2 + fields
    data_ = bytes[data-start..index]
    fields_ = fields
    data-size_ = data_.size
    serialized-size_ = 2 + fields + data-size_

  stringify -> string:
    s := ""
    for i := 0; i < fields_; i++:
      s += dataTypes_[i].stringify + ": " + (field-data_ i).stringify + ", "
    return s
  
  add-data-string dataType/int data/string -> none:
    add-data-ascii dataType data

  add-data-ascii dataType/int data/string -> none:
    add-data dataType data.to-byte-array

  add-data-uint8 dataType/int data/int -> none:
    add-data dataType #[data]

  add-data-uint16 dataType/int data/int -> none:
    add-data dataType #[data & 0xFF, data >> 8]

  add-data-uint32 dataType/int data/int -> none:
    b := #[0,0,0,0]
    LITTLE-ENDIAN.put-uint32 b 0 data
    add-data dataType b

  add-data-int8 dataType/int data/int -> none:
    add-data dataType #[data]

  add-data-int32 dataType/int data/int -> none:
    b := #[0,0,0,0]
    LITTLE-ENDIAN.put-int32 b 0 data
    add-data dataType b

  add-data-uint64 dataType/int data/int -> none:
    b := #[0,0,0,0,0,0,0,0]
    LITTLE-ENDIAN.put-uint b 8 0 data
    add-data dataType b
  
  add-data-uint dataType/int data/int -> none:
    if data < 256:
      add-data-uint8 dataType data
    else if data < 65536:
      add-data-uint16 dataType data
    else if data < 16777216:
      add-data-uint32 dataType data
    else if data < 4294967296:
      add-data-uint32 dataType data
    else if data < 1099511627776:
      add-data-uint64 dataType data
    else:
      log.error "Data too large for uintn: $(data)"

  add-data-float dataType/int data/float -> none:
    add-data-float32 dataType data

  add-data-float32 dataType/int data/float -> none:
    b := #[0,0,0,0]
    LITTLE-ENDIAN.put-float32 b 0 data
    add-data dataType b

  add-data dataType/int data/ByteArray -> none:
    if data.size > 255:
      throw "V3 protocol can't have data field of over 255 bytes"
    ensure-data-types-capacity_ fields_ + 1
    dataTypes_[fields_] = dataType
    ensure-data-capacity_ data-size_ + 1 + data.size
    data_[data-size_] = data.size
    data_.replace (data-size_ + 1) data 0 data.size
    fields_ += 1
    data-size_ += 1 + data.size
    serialized-size_ += 2 + data.size

  add-data-bool dataType/int data/bool -> none:
    if data:
      add-data-uint8 dataType 1
    else:
      add-data-uint8 dataType 0

  get-data-bool dataType/int -> bool:
    return (get-data-uint8 dataType) == 1

  has-data dataType/int -> bool:
    e := catch:
      for i := 0; i < fields_; i++:
        if dataTypes_[i] == dataType:
          return true
      return false
    if e:
      log.warn "Failed to check for data: $(e)"
    return false

  remove-data dataType/int -> none:
    e := catch:
      for i := 0; i < fields_; i++:
        if dataTypes_[i] == dataType:
          field-start := field-start_ i
          field-size := data_[field-start]
          field-end := field-start + 1 + field-size

          new-data-types := ByteArray fields_ - 1
          new-data-types.replace 0 dataTypes_ 0 i
          new-data-types.replace i dataTypes_ (i + 1) (fields_ - i - 1)
          dataTypes_ = new-data-types

          new-data-size := data-size_ - (1 + field-size)
          new-data := ByteArray new-data-size
          new-data.replace 0 data_ 0 field-start
          new-data.replace field-start data_ field-end (data-size_ - field-end)
          data_ = new-data

          fields_ -= 1
          data-size_ = new-data-size
          serialized-size_ -= 2 + field-size
          return
    if e:
      log.warn "Failed to remove data: $(e)"

  // returns the data for the type, or an empty list if not found
  // will never throw an error
  get-data dataType/int -> ByteArray:
    e := catch:
      for i := 0; i < fields_; i++:
        if dataTypes_[i] == dataType:
          return field-data_ i
      return #[]
    if e:
      log.warn "Failed to get data: $(e)"
    return #[]

  get-data-ascii dataType/int -> string:
    data := get-data dataType
    return data.to-string

  get-data-uint8 dataType/int -> int:
    // TODO use LITTLE-ENDIAN? (When we have a byte array not a list?)
    data := get-data dataType
    if data.size == 0:
      log.warn "No data for datatype $(dataType)"
      return 0
    return data[0]

  get-data-uint16 dataType/int -> int:
    return LITTLE-ENDIAN.uint16 (get-data dataType) 0

  get-data-uint32 dataType/int -> int:
    return LITTLE-ENDIAN.uint32 (get-data dataType) 0

  get-data-int32 dataType/int -> int:
    return LITTLE-ENDIAN.int32 (get-data dataType) 0

  get-data-uint64 dataType/int -> int:
    data := get-data dataType
    if data.size < 8:
      log.warn "No data for datatype $(dataType)"
      return 0
    return (data[7] << 56) + (data[6] << 48) + (data[5] << 40) + (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]

  add-data-list-uint16 dataType/int data/List -> none:
    b := ByteArray data.size * 2
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-uint16 b (i * 2) data[i]
    add-data dataType b

  get-data-list-uint16 dataType/int -> List:
    data := get-data dataType
    if data.size % 2 != 0:
      log.error "Data size not a multiple of 2 for datatype $(dataType)"
      return []
    l := []
    for i := 0; i < data.size; i += 2:
      l.add (LITTLE-ENDIAN.uint16 data i)
    return l
  
  add-data-list-uint32 dataType/int data/List -> none:
    b := ByteArray data.size * 4
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-uint32 b (i * 4) data[i]
    add-data dataType b
  
  add-data-list-float32 dataType/int data/List -> none:
    b := ByteArray data.size * 4
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-float32 b (i * 4) data[i]
    add-data dataType b
  
  get-data-list-uint32 dataType/int -> List:
    data := get-data dataType
    if data.size % 4 != 0:
      log.error "Data size not a multiple of 4 for datatype $(dataType)"
      return []
    l := []
    for i := 0; i < data.size; i += 4:
      l.add (LITTLE-ENDIAN.uint32 data i)
    return l
  
  add-data-list-int32-pairs dataType/int data/List -> none:
    b := ByteArray data.size * 8
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-int32 b (i * 8) data[i][0]
      LITTLE-ENDIAN.put-int32 b ((i * 8) + 4) data[i][1]
    add-data dataType b
  
  get-data-list-int32-pairs dataType/int -> List:
    data := get-data dataType
    if data.size % 8 != 0:
      log.error "Data size not a multiple of 8 for datatype $(dataType)"
      return []
    l := []
    for i := 0; i < data.size; i += 8:
      l.add [LITTLE-ENDIAN.int32 data i, LITTLE-ENDIAN.int32 data (i + 4)]
    return l

  get-data-coordinate dataType/int -> Coordinate:
    data := get-data dataType
    if data.size != 8:
      log.error "Data size not 8 for datatype $(dataType)"
      return Coordinate 0.0 0.0 // TOOD consider all gets returning null on error, not a 0 value...
    return Coordinate ((LITTLE-ENDIAN.int32 data 0) / 1e7) ((LITTLE-ENDIAN.int32 data 4) / 1e7)

  get-data-list-coordinates dataType/int -> List:
    data := get-data dataType
    if data.size % 8 != 0:
      log.error "Data size not a multiple of 8 for datatype $(dataType)"
      return []
    l := []
    for i := 0; i < data.size; i += 8:
      l.add (Coordinate ((LITTLE-ENDIAN.int32 data i) / 1e7) ((LITTLE-ENDIAN.int32 data (i + 4)) / 1e7))
    return l

  get-data-float dataType/int -> float:
    return get-data-float32 dataType

  get-data-float32 dataType/int -> float:
    d := get-data dataType
    return LITTLE-ENDIAN.float32 d 0

  get-data-uint dataType/int -> int:
    // TODO use LITTLE-ENDIAN more consistently
    // read the data for the type, and decide which size it fits in
    // ie 1 bytes is unint8
    // 2 bytes is uint16
    // 3 bytes should be 32, as should 4 bytes
    // etc
    data := get-data dataType
    if data.size == 0:
      log.warn "No data for datatype $(dataType)"
      return 0
    if data.size == 1:
      return LITTLE-ENDIAN.uint8 data 0
    if data.size == 2:
      return LITTLE-ENDIAN.uint16 data 0
    if data.size == 3:
        return (data[2] << 16) + (data[1] << 8) + data[0]
    if data.size == 4:
      return LITTLE-ENDIAN.uint32 data 0
    if data.size == 5:
        return (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]
    if data.size == 6:
        return (data[5] << 40) + (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]
    if data.size == 7:
        return (data[6] << 48) + (data[5] << 40) + (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]
    if data.size == 8:
        // toit doesnt actually support uint64, so this will always be represented as int64
        return (data[7] << 56) + (data[6] << 48) + (data[5] << 40) + (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]
    log.error "Data size too large for uintn: $(data.size)"
    return 0

  get-data-int dataType/int -> int:
    return get-data-intn dataType

  get-data-intn dataType/int -> int:
    // read the data for the type, and decide which size it fits in
    // ie 1 byte is int8
    // 2 bytes is int16
    // 3 bytes should be 32, as should 4 bytes
    // etc
    data := get-data dataType
    if data.size == 0:
        log.warn "No data for datatype $(dataType)"
        return 0
    if data.size == 1:
        return LITTLE-ENDIAN.int8 data 0
    if data.size == 2:
        return LITTLE-ENDIAN.int16 data 0
    if data.size == 3:
            return (data[2] << 16) + (data[1] << 8) + data[0]
    if data.size == 4:
        return LITTLE-ENDIAN.int32 data 0
    if data.size == 5:
            return (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]
    if data.size == 6:
            return (data[5] << 40) + (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]
    if data.size == 7:
            return (data[6] << 48) + (data[5] << 40) + (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]
    if data.size == 8:
            // toit doesnt actually support int64, so this will always be represented as int64
            return (data[7] << 56) + (data[6] << 48) + (data[5] << 40) + (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]
    log.error "Data size too large for intn: $(data.size)"
    return 0

  size -> int:
    return serialized-size_
  
  data-field-count -> int:
    return fields_
  
  bytes-for-protocol -> ByteArray:
    b := ByteArray serialized-size_
    write-bytes-for-protocol-into b 0
    return b

  write-bytes-for-protocol-into target/ByteArray offset/int -> int:
    dfc := fields_

    // first, datafield count uint16 LE
    target[offset] = dfc & 0xFF
    target[offset + 1] = dfc >> 8
    // then data types
    bi := offset + 2
    target.replace bi dataTypes_ 0 dfc
    bi += dfc
    // then data
    target.replace bi data_ 0 data-size_
    bi += data-size_
    return bi

  ensure-data-types-capacity_ required/int -> none:
    if dataTypes_.size >= required: return
    new-size := dataTypes_.size * 2
    if new-size < 8: new-size = 8
    if new-size < required: new-size = required
    new-data-types := ByteArray new-size
    new-data-types.replace 0 dataTypes_ 0 fields_
    dataTypes_ = new-data-types

  ensure-data-capacity_ required/int -> none:
    if data_.size >= required: return
    new-size := required + 16
    new-data := ByteArray new-size
    new-data.replace 0 data_ 0 data-size_
    data_ = new-data

  field-start_ index/int -> int:
    offset := 0
    index.repeat:
      offset += 1 + data_[offset]
    return offset

  field-data_ index/int -> ByteArray:
    start := field-start_ index
    size := data_[start]
    return data_[start + 1..start + 1 + size]

list-to-byte-array l/List -> ByteArray:
  b := ByteArray l.size
  for i := 0; i < l.size; i++:
    b[i] = l[i]
  return b
