import crypto.crc
import io
import io.byte-order show LITTLE-ENDIAN
import log
import .header show *
import .data show *
import ..util.docs
import ..util.bytes show stringify-all-bytes

class Message:
 protocol-version_ /int := 3
 data_ /Data? := null
 bytes_ /ByteArray? := null
 message-length_ /int := 0
 message-type_ /int := 0
 checksum_ /int := 0

 // Deprecated for new hot-path code. Prefer Message.header-* helpers for header
 // field reads/writes; parsed messages can answer those without allocating this
 // Header view. This class remains for compatibility and explicit materialized
 // header access.
 // Scheduled for removal in the 2nd half of 2026.
 header_ /Header? := null 

 constructor messageType/int:
  message-type_ = messageType
  header_ = Header 0 messageType Data
  data_ = Data

 constructor.with-data messageType/int data/Data?:
  if data == null:
    data = Data
  message-type_ = messageType
  header_ = Header 0 messageType Data
  data_ = data

 constructor.raw_:

 static from-bytes bytes/ByteArray -> Message:
  m := Message.raw_
  m.parse-into bytes
  return m

 parse-into bytes/ByteArray -> none:
  protocol-version_ = bytes[0]
  message-length_ = LITTLE-ENDIAN.uint16 bytes 1
  message-type_ = LITTLE-ENDIAN.uint16 bytes 3
  checksum_ = LITTLE-ENDIAN.uint16 bytes (bytes.size - 2)
  bytes_ = bytes
  header_ = null
  data_ = null

 constructor.from-message msg/Message:
  if msg.raw-bytes-valid_:
    bytes_ = msg.bytes_
    protocol-version_ = msg.protocol-version_
    message-length_ = msg.message-length_
    message-type_ = msg.message-type_
  else:
    header_ = Header.fromHeader msg.header
    data_ = Data.from-data msg.data
    message-type_ = msg.type
  checksum_ = msg.checksum_

 static with-method messageType/int method/int data/Data?=Data -> Message:
  msg := Message.with-data messageType data
  msg.header-add-data-uint8 Header.TYPE-MESSAGE-METHOD method
  return msg

 msgId -> int?:
  if header-has-data Header.TYPE_MESSAGE_ID: return header-get-data-uint Header.TYPE_MESSAGE_ID
  return null

 response-to -> int?:
  if header-has-data Header.TYPE-RESPONSE-TO-MESSAGE-ID: return header-get-data-uint Header.TYPE-RESPONSE-TO-MESSAGE-ID
  return null

 msgType -> int:
  return type

 msg-status -> int?:
  if header-has-data Header.TYPE_MESSAGE_STATUS: return header-get-data-int Header.TYPE_MESSAGE_STATUS
  return null

 msg-ok -> bool:
  return not (header-has-data Header.TYPE_MESSAGE_STATUS) or (header-get-data-int Header.TYPE_MESSAGE_STATUS) <= Header.STATUS_OK

 msg-status-id status/int -> bool:
  return (header-has-data Header.TYPE_MESSAGE_STATUS) and (header-get-data-int Header.TYPE_MESSAGE_STATUS) == status

 was-forwarded -> bool:
  return (header-has-data Header.TYPE_FORWARDED_FOR) or (header-has-data Header.TYPE_FORWARDED_FOR_TYPE)

 forwarded-for -> int?:
  if header-has-data Header.TYPE_FORWARDED_FOR:
    return header-get-data-uint Header.TYPE_FORWARDED_FOR
  return null

 header-has-data dataType/int -> bool:
  return header-data-has_ dataType

 header-get-data dataType/int -> ByteArray:
  return materialize-header_.data.get-data dataType

 header-get-data-ascii dataType/int -> string:
  return materialize-header_.data.get-data-ascii dataType

 header-get-data-uint8 dataType/int -> int:
  if raw-bytes-valid_: return header-data-uint_ dataType
  return materialize-header_.data.get-data-uint8 dataType

 header-get-data-uint16 dataType/int -> int:
  if raw-bytes-valid_: return header-data-uint_ dataType
  return materialize-header_.data.get-data-uint16 dataType

 header-get-data-uint32 dataType/int -> int:
  if raw-bytes-valid_: return header-data-uint_ dataType
  return materialize-header_.data.get-data-uint32 dataType

 header-get-data-uint dataType/int -> int:
  return header-data-uint_ dataType

 header-get-data-int dataType/int -> int:
  return header-data-int_ dataType

 header-get-data-intn dataType/int -> int:
  return header-get-data-int dataType

 header-add-data-string dataType/int data/string -> none:
  materialize-header_.data.add-data-string dataType data

 header-add-data-ascii dataType/int data/string -> none:
  materialize-header_.data.add-data-ascii dataType data

 header-add-data-uint8 dataType/int data/int -> none:
  materialize-header_.data.add-data-uint8 dataType data

 header-add-data-uint16 dataType/int data/int -> none:
  materialize-header_.data.add-data-uint16 dataType data

 header-add-data-uint32 dataType/int data/int -> none:
  materialize-header_.data.add-data-uint32 dataType data

 header-add-data-int8 dataType/int data/int -> none:
  materialize-header_.data.add-data-int8 dataType data

 header-add-data-int32 dataType/int data/int -> none:
  materialize-header_.data.add-data-int32 dataType data

 header-add-data-uint64 dataType/int data/int -> none:
  materialize-header_.data.add-data-uint64 dataType data

 header-add-data-uint dataType/int data/int -> none:
  materialize-header_.data.add-data-uint dataType data

 header-add-data-float dataType/int data/float -> none:
  materialize-header_.data.add-data-float dataType data

 header-add-data-float32 dataType/int data/float -> none:
  materialize-header_.data.add-data-float32 dataType data

 header-add-data dataType/int data/ByteArray -> none:
  materialize-header_.data.add-data dataType data

 header-add-data-bool dataType/int data/bool -> none:
  materialize-header_.data.add-data-bool dataType data

 header-remove-data dataType/int -> none:
  materialize-header_.data.remove-data dataType

 header -> Header:
  return materialize-header_  

 type -> int:
  return message-type_

 data -> Data:
  return materialize-data_

 stringify -> string:
  s := "Message type: $message-type_ length: $size"
  if this.msgId:
    s += " id: $this.msgId"
  if this.response-to:
    s += " response-to: $this.response-to"
  log.default.with-level log.DEBUG-LEVEL:
    s += " bytes: $(stringify-all-bytes bytes-for-protocol)"
  return s

 size -> int:
  if raw-bytes-valid_: return message-length_
  // protocol, header, data, checksum
  return 1 + 2 + 2 + materialize-header_.data_.size + materialize-data_.size + 2

 // TODO remove this duplicate method...
 bytes -> ByteArray:
  return bytes-for-protocol

 bytes-for-protocol -> ByteArray:
  if raw-bytes-valid_: return bytes_
  message-size := size
  b := ByteArray message-size
  write-bytes-for-protocol-into b 0
  return b

 write-bytes-for-protocol-into target/ByteArray offset/int -> int:
  if raw-bytes-valid_:
    target.replace offset bytes_ 0 message-length_
    return offset + message-length_

  message-size := size
  materialize-header_.messageLength_ = message-size

  target[offset] = protocol-version_
  write-offset := materialize-header_.write-bytes-for-protocol-into target (offset + 1)
  write-offset = materialize-data_.write-bytes-for-protocol-into target write-offset

  checksum_ = checksum-calc-range_ target offset message-size
  LITTLE-ENDIAN.put-uint16 target (offset + message-size - 2) checksum_
  return offset + message-size

 checksum-calc -> int:
  if raw-bytes-valid_:
    return checksum-calc-range_ bytes_ 0 message-length_
  pre-csum := bytes-early_
  // Calculate CRC16 XMODEM over the bytes (without the last 2 which will be checksum)
  return checksum-calc-bytes_ pre-csum

 checksum-calc-bytes_ bytes/ByteArray -> int:
  return checksum-calc-range_ bytes 0 bytes.byte-size

 checksum-calc-range_ bytes/ByteArray offset/int size/int -> int:
  checksum := crc.Crc16Xmodem
  checksum.add bytes offset (size - 2)
  return checksum.get-as-int

 // byteListEarly_ is a byteList, without length of checksum calculated
 bytes-early_ -> ByteArray:
  if raw-bytes-valid_: return bytes_
  header-size := 2 + 2 + materialize-header_.data_.size
  message-size := 1 + header-size + materialize-data_.size + 2
  materialize-header_.messageLength_ = message-size

  b := ByteArray message-size
  // first byte is protocol version
  b[0] = protocol-version_
  // then header and main data
  write-offset := materialize-header_.write-bytes-for-protocol-into b 1
  materialize-data_.write-bytes-for-protocol-into b write-offset
  // add checksum which is uint16 LE
  LITTLE-ENDIAN.put-uint16 b (b.size - 2) checksum_
  return b

 raw-bytes-valid_ -> bool:
  if not header-bytes-valid_: return false
  if data_ != null and data_.is-dirty_: return false
  return true

 header-bytes-valid_ -> bool:
  if bytes_ == null: return false
  if header_ != null:
    if header_.messageLength_ != message-length_: return false
    if header_.messageType_ != message-type_: return false
    if header_.data.is-dirty_: return false
  return true

 materialize-header_ -> Header:
  if header_ == null:
    header-data := Data.from-bytes-at bytes_ 5
    header_ = Header message-length_ message-type_ header-data
  return header_

 materialize-data_ -> Data:
  if data_ == null:
    data-offset := 1 + raw-header-size_
    data_ = Data.from-bytes-at bytes_ data-offset
  return data_

 header-size_ -> int:
  if header_ != null: return header_.size
  return raw-header-size_

 raw-header-size_ -> int:
  return 4 + (serialized-size-at bytes_ 5)

 header-data-has_ dataType/int -> bool:
  if header-bytes-valid_: return data-has-at_ bytes_ 5 dataType
  return materialize-header_.data.has-data dataType

 header-data-uint_ dataType/int -> int:
  if header-bytes-valid_: return data-uint-at_ bytes_ 5 dataType
  return materialize-header_.data.get-data-uint dataType

 header-data-int_ dataType/int -> int:
  if header-bytes-valid_: return data-int-at_ bytes_ 5 dataType
  return materialize-header_.data.get-data-intn dataType

 data-field-start-at_ bytes/ByteArray offset/int dataType/int -> int:
  fields := LITTLE-ENDIAN.uint16 bytes offset
  data-index := offset + 2 + fields
  for i := 0; i < fields; i++:
    length := bytes[data-index]
    if bytes[offset + 2 + i] == dataType:
      return data-index
    data-index += 1 + length
  return -1

 data-has-at_ bytes/ByteArray offset/int dataType/int -> bool:
  return (data-field-start-at_ bytes offset dataType) >= 0

 data-uint-at_ bytes/ByteArray offset/int dataType/int -> int:
  start := data-field-start-at_ bytes offset dataType
  if start < 0: return 0
  size := bytes[start]
  return LITTLE-ENDIAN.read-uint bytes size (start + 1)

 data-int-at_ bytes/ByteArray offset/int dataType/int -> int:
  start := data-field-start-at_ bytes offset dataType
  if start < 0: return 0
  size := bytes[start]
  return LITTLE-ENDIAN.read-int bytes size (start + 1)
