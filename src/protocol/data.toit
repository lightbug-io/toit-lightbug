import io show LITTLE-ENDIAN  // Works as well. Both are fine.
import log
import coordinate show Coordinate
import .data-field show *

class Data:
  data-types_ /List := []
  data_ /List := []

  constructor:
    data-types_ = []
    data_ = []

  constructor.from-data data/Data:
    data-types_ = data.data-types_
    data_ = data.data_

  constructor.from-list bytes/List:
    if bytes.size < 2:
      throw "V3 OUT_OF_BOUNDS: Not enough bytes to read fields, expected 2 bytes but only have $bytes.size"
    fields := (bytes[1] << 8) + bytes[0]
    // log.debug "Data fields: " + fields.stringify
    if bytes.size < 2 + fields:
      throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data types, expected $(2 + fields) bytes but only have $bytes.size"
    // read data types
    fields.repeat: | i |
      data-type := bytes[2 + i]
      data-types_.add data-type
      // log.debug "Data data type: " + data-type.stringify
    // read data (each is a uint8 length, then that number of bytes)
    index := 2 + fields
    fields.repeat: | i |
      if index >= bytes.size:
        throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data length, expected $index bytes but only have $bytes.size"
      length := bytes[index]
      // log.debug "Data data length: " + length.stringify
      index += 1
      if index + length > bytes.size:
        throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data, expected $(index + length) bytes but only have $bytes.size"
      index += length
      // log.debug "Data data bytes: " + bytes[index - length..index].stringify
      dataField := DataField (list-to-byte-array bytes[index - length..index])
      data_.add dataField
      // log.debug "Data data: " + dataField.stringify

  constructor.from-bytes bytes/ByteArray:
    // You could also store the bytes in an io.Reader and read it from there.
    // Something like
    //   reader := io.Reader bytes
    //   fields := reader.little-endian.read-uint16
    //   fields.repeat: | i |
    //     data-type := reader.read-byte
    //     ...
    if bytes.size < 2:
      throw "V3 OUT_OF_BOUNDS: Not enough bytes to read fields, expected 2 bytes but only have $bytes.size"
    fields := LITTLE-ENDIAN.uint16 bytes 0
    // log.debug "Data fields: " + fields.stringify
    if bytes.size < 2 + fields:
      throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data types, expected $(2 + fields) bytes but only have $bytes.size"
    // read data types
    fields.repeat: | i |
      data-type := bytes[2 + i]
      data-types_.add data-type
      // log.debug "Data data type: " + data-type.stringify
    // read data (each is a uint8 length, then that number of bytes)
    index := 2 + fields
    fields.repeat: | i |
      if index >= bytes.size:
        throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data length, expected $index bytes but only have $bytes.size"
      length := bytes[index]
      // log.debug "Data data length: " + length.stringify
      index += 1
      if index + length > bytes.size:
        throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data, expected $(index + length) bytes but only have $bytes.size"
      index += length
      // log.debug "Data data bytes: " + bytes[index - length..index].stringify
      dataField := DataField (bytes[index - length..index])
      data_.add dataField
      // log.debug "Data data: " + dataField.stringify

  stringify -> string:
    result := ""
    data-types_.size.repeat: | i |
      if i != 0: result += ", "
      result += "$data-types_[i]: $data_[i]"
    return result

  add-data-s data-type/int data/string -> none:
    add-data data-type data.to-byte-array

  add-data-uint8 data-type/int data/int -> none:
    add-data data-type #[data]

  add-data-uint16 data-type/int data/int -> none:
    add-data data-type #[data & 0xFF, data >> 8]

  add-data-uint32 data-type/int data/int -> none:
    b := #[0,0,0,0]
    LITTLE-ENDIAN.put-uint32 b 0 data
    add-data data-type b

  add-data-int32 data-type/int data/int -> none:
    b := #[0,0,0,0]
    LITTLE-ENDIAN.put-int32 b 0 data
    add-data data-type b

  add-data-uint64 data-type/int data/int -> none:
    b := #[0,0,0,0,0,0,0,0]
    LITTLE-ENDIAN.put-uint b 8 0 data
    add-data data-type b

  add-data-uintn data-type/int data/int -> none:
    if data < 256:
      add-data-uint8 data-type data
    else if data < 65536:
      add-data-uint16 data-type data
    else if data < 16777216:
      add-data-uint32 data-type data
    else if data < 4294967296:
      add-data-uint32 data-type data
    else if data < 1099511627776:
      add-data-uint64 data-type data
    else:
      log.error "Data too large for uintn: " + data.stringify

  add-data-float data-type/int data/float -> none:
    b := #[0,0,0,0]
    LITTLE-ENDIAN.put-float32 b 0 data
    add-data data-type b

  add-data data-type/int data/ByteArray -> none:
    data_.add (DataField data)
    data-types_.add data-type

  // TODO kill this method
  add-data-list data-type/int data/List -> none:
    add-data data-type (list-to-byte-array data)

  has-data data-type/int -> bool:
    e := catch:
      for i := 0; i < data-types_.size; i++:
        if data-types_[i] == data-type:
          return true
      return false
    if e:
      // Typically we have the logging message as a constant and then add
      // variable data as tags.
      log.warn "failed to check for data" --tags={"exception": e}
    return false

  remove-data data-type/int -> none:
    e := catch:
      for i := 0; i < data-types_.size; i++:
        if data-types_[i] == data-type:
          data-types_.remove --at=i
          data_.remove --at=i
          return
    if e:
      log.warn "failed to remove data" --tags={"exception": e}

  // Returns the data for the type, or an empty byte-array if not found.
  // Never throws an error.
  get-data data-type/int -> ByteArray:
    e := catch:  // Why do you need the catch?
      data-types_.size.repeat: | i |
        if data-types_[i] == data-type:
          return data_[i].data-bytes_
      return #[]
    if e:
      log.warn "Failed to get data: " + e.stringify
    return #[]

  get-data-s data-type/int -> string:
    data := get-data data-type
    return data.to-string

  get-ascii-data data-type/int -> string:
    data := get-data data-type
    e := catch:
      return (_trim-bad-ascii-right-and-log data).to-string
    if e:
      log.error "Failed to convert data to ascii: " + e.stringify + ": " + data.stringify
    return ""

  _trim-bad-ascii-right-and-log data/ByteArray -> ByteArray:
    last-good-index := 0
    i := 0
    data.do: | element |
      i++
      if element < 32 or element > 126:
        log.warn "Invalid ascii data, skipping index " + i.stringify + ": " + element.stringify
      last-good-index = i - 1
    return data[..last-good-index]

  get-data-uint8 data-type/int -> int:
    // TODO use LITTLE-ENDIAN? (When we have a byte array not a list?)
    data := get-data data-type
    if data.size == 0:
      log.warn "No data for datatype " + data-type.stringify
      return 0
    return data[0]

  get-data-uint16 data-type/int -> int:
    return LITTLE-ENDIAN.uint16 (get-data data-type) 0

  get-data-uint32 data-type/int -> int:
    return LITTLE-ENDIAN.uint32 (get-data data-type) 0

  get-data-int32 data-type/int -> int:
    return LITTLE-ENDIAN.int32 (get-data data-type) 0

  get-data-uint64 data-type/int -> int:
    data := get-data data-type
    if data.size < 8:
      log.warn "No data for datatype " + data-type.stringify
      return 0
    return LITTLE-ENDIAN.int64 data 0

  add-data-list-uint16 data-type/int data/List -> none:
    b := ByteArray data.size * 2
    data.size.repeat: | i |
      LITTLE-ENDIAN.put-uint16 b (i * 2) data[i]
    add-data data-type b

  get-data-list-uint16 data-type/int -> List:
    data := get-data data-type
    if data.size % 2 != 0:
      log.error "Data size not a multiple of 2 for datatype " + data-type.stringify
      return []
    l := []
    for i := 0; i < data.size; i += 2:
      l.add (LITTLE-ENDIAN.uint16 data i)
    return l

  add-data-list-uint32 data-type/int data/List -> none:
    b := ByteArray data.size * 4
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-uint32 b (i * 4) data[i]
    add-data data-type b

  get-data-list-uint32 data-type/int -> List:
    data := get-data data-type
    if data.size % 4 != 0:
      log.error "Data size not a multiple of 4 for datatype " + data-type.stringify
      return []
    l := []
    for i := 0; i < data.size; i += 4:
      l.add (LITTLE-ENDIAN.uint32 data i)
    return l

  add-data-list-int32-pairs data-type/int data/List -> none:
    b := ByteArray data.size * 8
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-int32 b (i * 8) data[i][0]
      LITTLE-ENDIAN.put-int32 b ((i * 8) + 4) data[i][1]
    add-data data-type b

  get-data-list-int32-pairs data-type/int -> List:
    data := get-data data-type
    if data.size % 8 != 0:
      log.error "Data size not a multiple of 8 for datatype " + data-type.stringify
      return []
    l := []
    for i := 0; i < data.size; i += 8:
      l.add [LITTLE-ENDIAN.int32 data i, LITTLE-ENDIAN.int32 data (i + 4)]
    return l

  get-data-list-coordinates data-type/int -> List:
    data := get-data data-type
    if data.size % 8 != 0:
      log.error "Data size not a multiple of 8 for datatype " + data-type.stringify
      return []
    l := []
    for i := 0; i < data.size; i += 8:
      l.add (Coordinate ((LITTLE-ENDIAN.int32 data i) / 1e7) ((LITTLE-ENDIAN.int32 data (i + 4)) / 1e7))
    return l

  get-data-float data-type/int -> float:
    d := get-data data-type
    return LITTLE-ENDIAN.float32 d 0

  get-data-uintn data-type/int -> int:
    // TODO use LITTLE-ENDIAN more consistently
    // read the data for the type, and decide which size it fits in
    // ie 1 bytes is unint8
    // 2 bytes is uint16
    // 3 bytes should be 32, as should 4 bytes
    // etc
    data := get-data data-type
    if data.size == 0:
      log.warn "No data for datatype " + data-type.stringify
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
    log.error "Data size too large for uintn: " + data.size.stringify
    return 0

  get-data-intn data-type/int -> int:
    // read the data for the type, and decide which size it fits in
    // ie 1 byte is int8
    // 2 bytes is int16
    // 3 bytes should be 32, as should 4 bytes
    // etc
    data := get-data data-type
    if data.size == 0:
      log.warn "No data for datatype " + data-type.stringify
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
      return LITTLE-ENDIAN.int64 data 0
    log.error "Data size too large for intn: " + data.size.stringify
    return 0

  size -> int:
    return bytes-for-protocol.size

  data-field-count -> int:
    return data-types_.size

  bytes-for-protocol -> ByteArray:
    data-length := 0
    for i := 0; i < data-field-count; i++:
      data-length += 1 + data_[i].data-bytes_.size
    bytes-size := 2 + data-field-count + data-length

    b := ByteArray bytes-size

    // first, datafield count uint16 LE
    dfc := data-field-count
    b[0] = dfc & 0xFF
    b[1] = dfc >> 8
    // then data types
    bi := 2
    for i := 0; i < data-field-count; i++:
      b[bi] = data-types_[i]
      bi += 1
    // then data
    for i := 0; i < data-field-count; i++:
      b.replace bi data_[i].bytes-for-protocol 0 (1 + data_[i].data-bytes_.size)
      bi += (1 + data_[i].data-bytes_.size)
    return b

list-to-byte-array l/List -> ByteArray:
  return ByteArray l.size: l[it]
