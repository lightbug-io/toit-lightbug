import crypto.crc
import io
import log
import .header show *
import .data show *
import ..util.docs

class Message:
 protocol-version_ /int := 3
 header_ /Header := Header
 data_ /Data := Data
 checksum_ /int := 0

 constructor messageType/int:
  header_.messageType_ = messageType

 constructor.with-data messageType/int data/Data:
  header_.messageType_ = messageType
  data_ = data

 constructor.from-list bytes/List:
  header_ = Header.from-list bytes[1..] // skip protocol version
  data_ = Data.from-list bytes[1 + header_.size..]
  checksum_ = (bytes[bytes.size - 1] << 8) + bytes[bytes.size - 2]

 constructor.from-message msg/Message:
    header_ = Header.fromHeader msg.header
    data_ = Data.from-data msg.data
    checksum_ = msg.checksum_

 with-random-msg-id -> Message:
  randomUint32 := ( random 4_294_967_295) +1
  header.data.add-data-uint32 Header.TYPE_MESSAGE_ID randomUint32
  return this

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

 msg-status-id status/int -> bool:
  return header.data.has-data Header.TYPE_MESSAGE_STATUS and (header.data.get-data-intn Header.TYPE_MESSAGE_STATUS) == status

 was-forwarded -> bool:
  return header_.data.has-data Header.TYPE_FORWARDED_FOR or header_.data.has-data Header.TYPE_FORWARDED_FOR_TYPE

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
    s += " bytes: $stringify-all-bytes"
    s += " link: $(message-to-docs-url this)"
  return s

 stringify-all-bytes -> string:
  buffer := io.Buffer
  is-first := true
  bytes.do:
    if is-first: is-first = false
    else: buffer.write ", "
    buffer.write "$(%02x it)"
  return buffer.to-string

 size -> int:
  // protocol, header, data, checksum
  return 1 + header_.size + data_.size +2

 // TODO remove this duplicate method...
 bytes -> ByteArray:
  return bytes-for-protocol

 bytes-for-protocol -> ByteArray:
  // first prep the message to be rendered as bytes
  // set the message length in the header
  header_.messageLength_ = size

  // set the checksum in the message
  checksum_ = checksum-calc

  // now render the message with the checksum
  return bytes-early_

 checksum-calc -> int:
  pre-csum := bytes-early_
  // Calculate CRC16 XMODEM over the bytes (without the last 2 which will be checksum)
  checksum := crc.crc16-xmodem (pre-csum.byte-slice 0 (pre-csum.byte-size - 2))
  return checksum

 // byteListEarly_ is a byteList, without length of checksum calculated
 bytes-early_ -> ByteArray:
  bHeader := header_.bytes-for-protocol
  bData := data_.bytes-for-protocol

  b := ByteArray 1 + bHeader.size + bData.size + 2
  // first byte is protocol version
  b[0] = protocol-version_
  // then header
  b.replace 1 bHeader 0 bHeader.size
  // then main data
  b.replace 1 + bHeader.size bData 0 bData.size
  // add checksum which is uint16 LE
  b.replace b.size - 2 #[checksum_ & 0xFF, checksum_ >> 8] 0 2
  return b