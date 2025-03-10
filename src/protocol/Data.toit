import io.byte-order show LITTLE-ENDIAN
import log
import coordinate show Coordinate
import .DataField show *

class Data:
  dataTypes_ /List := []
  data_ /List := []

  constructor:
    dataTypes_ = []
    data_ = []
  
  constructor.fromData data/Data:
    dataTypes_ = data.dataTypes_
    data_ = data.data_

  constructor.fromList bytes/List:
    if bytes.size < 2:
      throw "V3 OUT_OF_BOUNDS: Not enough bytes to read fields, expected 2 bytes but only have " + bytes.size.stringify
    fields := (bytes[1] << 8) + bytes[0]
    // log.debug "Data fields: " + fields.stringify
    if bytes.size < 2 + fields:
      throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data types, expected " + (2 + fields).stringify + " bytes but only have " + bytes.size.stringify
    // read data types
    for i := 0; i < fields; i++:
      dataType := bytes[2 + i]
      dataTypes_.add dataType
      // log.debug "Data data type: " + dataType.stringify
    // read data (each is a uint8 length, then that number of bytes)
    index := 2 + fields
    for i := 0; i < fields; i++:
      if index >= bytes.size:
        throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data length, expected " + index.stringify + " bytes but only have " + bytes.size.stringify
      length := bytes[index]
      // log.debug "Data data length: " + length.stringify
      index += 1
      if index + length > bytes.size:
        throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data, expected " + (index + length).stringify + " bytes but only have " + bytes.size.stringify
      index += length
      // log.debug "Data data bytes: " + bytes[index - length..index].stringify
      dataField := DataField (listToByteArray bytes[index - length..index])
      data_.add dataField
      // log.debug "Data data: " + dataField.stringify
  
  constructor.fromBytes bytes/ByteArray:
    if bytes.size < 2:
      throw "V3 OUT_OF_BOUNDS: Not enough bytes to read fields, expected 2 bytes but only have " + bytes.size.stringify
    fields := LITTLE-ENDIAN.uint16 bytes 0
    // log.debug "Data fields: " + fields.stringify
    if bytes.size < 2 + fields:
      throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data types, expected " + (2 + fields).stringify + " bytes but only have " + bytes.size.stringify
    // read data types
    for i := 0; i < fields; i++:
      dataType := bytes[2 + i]
      dataTypes_.add dataType
      // log.debug "Data data type: " + dataType.stringify
    // read data (each is a uint8 length, then that number of bytes)
    index := 2 + fields
    for i := 0; i < fields; i++:
      if index >= bytes.size:
        throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data length, expected " + index.stringify + " bytes but only have " + bytes.size.stringify
      length := bytes[index]
      // log.debug "Data data length: " + length.stringify
      index += 1
      if index + length > bytes.size:
        throw "V3 OUT_OF_BOUNDS: Not enough bytes to read data, expected " + (index + length).stringify + " bytes but only have " + bytes.size.stringify
      index += length
      // log.debug "Data data bytes: " + bytes[index - length..index].stringify
      dataField := DataField (bytes[index - length..index])
      data_.add dataField
      // log.debug "Data data: " + dataField.stringify

  stringify -> string:
    s := ""
    for i := 0; i < dataTypes_.size; i++:
      s += dataTypes_[i].stringify + ": " + data_[i].stringify + ", "
    return s

  addDataAscii dataType/int data/string -> none:
    addData dataType data.to-byte-array

  addDataUint8 dataType/int data/int -> none:
    addData dataType #[data]

  addDataUint16 dataType/int data/int -> none:
    addData dataType #[data & 0xFF, data >> 8]

  addDataUint32 dataType/int data/int -> none:
    b := #[0,0,0,0]
    LITTLE-ENDIAN.put-uint32 b 0 data
    addData dataType b

  addDataInt32 dataType/int data/int -> none:
    b := #[0,0,0,0]
    LITTLE-ENDIAN.put-int32 b 0 data
    addData dataType b

  addDataUint64 dataType/int data/int -> none:
    b := #[0,0,0,0,0,0,0,0]
    LITTLE-ENDIAN.put-uint b 8 0 data
    addData dataType b
  
  addDataUint dataType/int data/int -> none:
    if data < 256:
      addDataUint8 dataType data
    else if data < 65536:
      addDataUint16 dataType data
    else if data < 16777216:
      addDataUint32 dataType data
    else if data < 4294967296:
      addDataUint32 dataType data
    else if data < 1099511627776:
      addDataUint64 dataType data
    else:
      log.error "Data too large for uintn: " + data.stringify

  addDataFloat32 dataType/int data/float -> none:
    b := #[0,0,0,0]
    LITTLE-ENDIAN.put-float32 b 0 data
    addData dataType b

  addData dataType/int data/ByteArray -> none:
    data_.add (DataField data)
    dataTypes_.add dataType

  // TODO kill this method
  addDataList dataType/int data/List -> none:
    addData dataType (listToByteArray data)

  hasData dataType/int -> bool:
    e := catch:
      for i := 0; i < dataTypes_.size; i++:
        if dataTypes_[i] == dataType:
          return true
      return false
    if e:
      log.warn "Failed to check for data: " + e.stringify
    return false

  removeData dataType/int -> none:
    e := catch:
      for i := 0; i < dataTypes_.size; i++:
        if dataTypes_[i] == dataType:
          dataTypes_.remove --at=i
          data_.remove --at=i
          return
    if e:
      log.warn "Failed to remove data: " + e.stringify

  // returns the data for the type, or an empty list if not found
  // will never throw an error
  getData dataType/int -> ByteArray:
    e := catch:
      for i := 0; i < dataTypes_.size; i++:
        if dataTypes_[i] == dataType:
          return data_[i].dataBytes_
      return #[]
    if e:
      log.warn "Failed to get data: " + e.stringify
    return #[]

  getDataAscii dataType/int -> string:
    data := getData dataType
    return data.to-string

  getAsciiData dataType/int -> string:
    data := getData dataType
    e := catch:
      return (_trimBadAsciiRightAndLog data).to-string
    if e:
      log.error "Failed to convert data to ascii: " + e.stringify + ": " + data.stringify
    return ""

  _trimBadAsciiRightAndLog data/ByteArray -> ByteArray:
    lastGoodIndex := 0
    i := 0
    data.do: | element |
      i++
      if element < 32 or element > 126:
        log.warn "Invalid ascii data, skipping index " + i.stringify + ": " + element.stringify
      lastGoodIndex = i - 1
    return data[0..lastGoodIndex]

  getDataUint8 dataType/int -> int:
    // TODO use LITTLE-ENDIAN? (When we have a byte array not a list?)
    data := getData dataType
    if data.size == 0:
      log.warn "No data for datatype " + dataType.stringify
      return 0
    return data[0]

  getDataUint16 dataType/int -> int:
    return LITTLE-ENDIAN.uint16 (getData dataType) 0

  getDataUint32 dataType/int -> int:
    return LITTLE-ENDIAN.uint32 (getData dataType) 0

  getDataInt32 dataType/int -> int:
    return LITTLE-ENDIAN.int32 (getData dataType) 0

  getDataUint64 dataType/int -> int:
    data := getData dataType
    if data.size < 8:
      log.warn "No data for datatype " + dataType.stringify
      return 0
    return (data[7] << 56) + (data[6] << 48) + (data[5] << 40) + (data[4] << 32) + (data[3] << 24) + (data[2] << 16) + (data[1] << 8) + data[0]

  addDataListUint16 dataType/int data/List -> none:
    b := ByteArray data.size * 2
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-uint16 b (i * 2) data[i]
    addData dataType b

  getDataListUint16 dataType/int -> List:
    data := getData dataType
    if data.size % 2 != 0:
      log.error "Data size not a multiple of 2 for datatype " + dataType.stringify
      return []
    l := []
    for i := 0; i < data.size; i += 2:
      l.add (LITTLE-ENDIAN.uint16 data i)
    return l
  
  addDataListUint32 dataType/int data/List -> none:
    b := ByteArray data.size * 4
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-uint32 b (i * 4) data[i]
    addData dataType b
  
  addDataListFloat32 dataType/int data/List -> none:
    b := ByteArray data.size * 4
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-float32 b (i * 4) data[i]
    addData dataType b
  
  getDataListUint32 dataType/int -> List:
    data := getData dataType
    if data.size % 4 != 0:
      log.error "Data size not a multiple of 4 for datatype " + dataType.stringify
      return []
    l := []
    for i := 0; i < data.size; i += 4:
      l.add (LITTLE-ENDIAN.uint32 data i)
    return l
  
  addDataListInt32Pairs dataType/int data/List -> none:
    b := ByteArray data.size * 8
    for i := 0; i < data.size; i++:
      LITTLE-ENDIAN.put-int32 b (i * 8) data[i][0]
      LITTLE-ENDIAN.put-int32 b ((i * 8) + 4) data[i][1]
    addData dataType b
  
  getDataListInt32Pairs dataType/int -> List:
    data := getData dataType
    if data.size % 8 != 0:
      log.error "Data size not a multiple of 8 for datatype " + dataType.stringify
      return []
    l := []
    for i := 0; i < data.size; i += 8:
      l.add [LITTLE-ENDIAN.int32 data i, LITTLE-ENDIAN.int32 data (i + 4)]
    return l

  getDataListCoordinates dataType/int -> List:
    data := getData dataType
    if data.size % 8 != 0:
      log.error "Data size not a multiple of 8 for datatype " + dataType.stringify
      return []
    l := []
    for i := 0; i < data.size; i += 8:
      l.add (Coordinate ((LITTLE-ENDIAN.int32 data i) / 1e7) ((LITTLE-ENDIAN.int32 data (i + 4)) / 1e7))
    return l

  getDataFloat32 dataType/int -> float:
    d := getData dataType
    return LITTLE-ENDIAN.float32 d 0

  getDataUint dataType/int -> int:
    // TODO use LITTLE-ENDIAN more consistently
    // read the data for the type, and decide which size it fits in
    // ie 1 bytes is unint8
    // 2 bytes is uint16
    // 3 bytes should be 32, as should 4 bytes
    // etc
    data := getData dataType
    if data.size == 0:
      log.warn "No data for datatype " + dataType.stringify
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

  getDataIntn dataType/int -> int:
    // read the data for the type, and decide which size it fits in
    // ie 1 byte is int8
    // 2 bytes is int16
    // 3 bytes should be 32, as should 4 bytes
    // etc
    data := getData dataType
    if data.size == 0:
        log.warn "No data for datatype " + dataType.stringify
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
    log.error "Data size too large for intn: " + data.size.stringify
    return 0

  size -> int:
    return bytesForProtocol.size
  
  dataFieldCount -> int:
    return dataTypes_.size
  
  bytesForProtocol -> ByteArray:
    dataLength := 0
    for i := 0; i < dataFieldCount; i++:
      dataLength += 1 + data_[i].dataBytes_.size
    bLen := 2 + dataFieldCount + dataLength

    b := ByteArray bLen

    // first, datafield count uint16 LE
    dfc := dataFieldCount
    b[0] = dfc & 0xFF
    b[1] = dfc >> 8
    // then data types
    bi := 2
    for i := 0; i < dataFieldCount; i++:
      b[bi] = dataTypes_[i]
      bi += 1
    // then data
    for i := 0; i < dataFieldCount; i++:
      b.replace bi data_[i].bytesForProtocol 0 (1 + data_[i].dataBytes_.size)
      bi += (1 + data_[i].dataBytes_.size)
    return b

listToByteArray l/List -> ByteArray:
  b := ByteArray l.size
  for i := 0; i < l.size; i++:
    b[i] = l[i]
  return b