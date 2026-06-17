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
 header_ /Header := Header
 data_ /Data := Data
 checksum_ /int := 0

 constructor messageType/int:
  header_.messageType_ = messageType

 constructor.with-data messageType/int data/Data?:
  header_.messageType_ = messageType
  if data == null:
    data = Data
  data_ = data

 static from-bytes bytes/ByteArray -> Message:
  // Create a message using with-data so constructors are satisfied.
  m := Message.with-data 0 (Data)
  m.parse-into bytes
  return m

 parse-into bytes/ByteArray -> none:
  // header starts at offset 1
  header_.parse-into bytes 1
  data_.parse-into bytes (1 + header_.size)
  checksum_ = (bytes[bytes.size - 1] << 8) + bytes[bytes.size - 2]

 constructor.from-message msg/Message:
  header_ = Header.fromHeader msg.header
  data_ = Data.from-data msg.data
  checksum_ = msg.checksum_

 static with-method messageType/int method/int data/Data?=Data -> Message:
  msg := Message.with-data messageType data
  msg.header.data.add-data-uint8 Header.TYPE-MESSAGE-METHOD method
  return msg

 msgId -> int?:
  if header.data.has-data Header.TYPE_MESSAGE_ID: return header.data.get-data-uint Header.TYPE_MESSAGE_ID
  return null

 response-to -> int?:
  if header.data.has-data Header.TYPE-RESPONSE-TO-MESSAGE-ID: return header.data.get-data-uint Header.TYPE-RESPONSE-TO-MESSAGE-ID
  return null

 msgType -> int:
  return header_.messageType_

 msg-status -> int?:
  if header.data.has-data Header.TYPE_MESSAGE_STATUS: return header.data.get-data-intn Header.TYPE_MESSAGE_STATUS
  return null

 msg-ok -> bool:
  return not (header.data.has-data Header.TYPE_MESSAGE_STATUS) or (header.data.get-data-intn Header.TYPE_MESSAGE_STATUS) <= Header.STATUS_OK

 msg-status-id status/int -> bool:
  return header.data.has-data Header.TYPE_MESSAGE_STATUS and (header.data.get-data-intn Header.TYPE_MESSAGE_STATUS) == status

 was-forwarded -> bool:
  return header_.data.has-data Header.TYPE_FORWARDED_FOR or header_.data.has-data Header.TYPE_FORWARDED_FOR_TYPE

 forwarded-for -> int?:
  if header_.data.has-data Header.TYPE_FORWARDED_FOR:
    return header_.data.get-data-uint Header.TYPE_FORWARDED_FOR
  return null

 header -> Header:
  return header_  

 type -> int:
  return header_.messageType_

 data -> Data:
  return data_

 stringify -> string:
  s := "Message type: $header_.messageType_ length: $header_.messageLength_"
  if this.msgId:
    s += " id: $this.msgId"
  if this.response-to:
    s += " response-to: $this.response-to"
  log.default.with-level log.DEBUG-LEVEL:
    s += " bytes: $(stringify-all-bytes bytes-for-protocol)"
  return s

 size -> int:
  // protocol, header, data, checksum
  return 1 + 2 + 2 + header_.data_.size + data_.size + 2

 // TODO remove this duplicate method...
 bytes -> ByteArray:
  return bytes-for-protocol

 bytes-for-protocol -> ByteArray:
  // first prep the message to be rendered as bytes
  // set the message length in the header
  header-size := 2 + 2 + header_.data_.size
  message-size := 1 + header-size + data_.size + 2
  header_.messageLength_ = message-size

  b := ByteArray message-size
  // first byte is protocol version
  b[0] = protocol-version_
  // then header and main data
  write-offset := header_.write-bytes-for-protocol-into b 1
  data_.write-bytes-for-protocol-into b write-offset

  // Calculate CRC16 XMODEM over the bytes (without the last 2 which will be checksum)
  checksum_ = checksum-calc-bytes_ b
  // add checksum which is uint16 LE
  b[b.size - 2] = checksum_ & 0xFF
  b[b.size - 1] = checksum_ >> 8
  return b

 checksum-calc -> int:
  pre-csum := bytes-early_
  // Calculate CRC16 XMODEM over the bytes (without the last 2 which will be checksum)
  return checksum-calc-bytes_ pre-csum

 checksum-calc-bytes_ bytes/ByteArray -> int:
  checksum := crc.Crc16Xmodem
  checksum.add bytes 0 (bytes.byte-size - 2)
  return checksum.get-as-int

 // byteListEarly_ is a byteList, without length of checksum calculated
 bytes-early_ -> ByteArray:
  header-size := 2 + 2 + header_.data_.size
  message-size := 1 + header-size + data_.size + 2
  header_.messageLength_ = message-size

  b := ByteArray message-size
  // first byte is protocol version
  b[0] = protocol-version_
  // then header and main data
  write-offset := header_.write-bytes-for-protocol-into b 1
  data_.write-bytes-for-protocol-into b write-offset
  // add checksum which is uint16 LE
  b.replace b.size - 2 #[checksum_ & 0xFF, checksum_ >> 8] 0 2
  return b