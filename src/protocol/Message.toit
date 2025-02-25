import crypto.crc
import io
import .Header show *
import .Data show *

class Message:
 protocolVersion_ /int := 3
 header_ /Header := Header
 data_ /Data := Data
 checksum_ /int := 0

 constructor messageType/int:
  header_.messageType_ = messageType

 constructor.withData messageType/int data/Data:
  header_.messageType_ = messageType
  data_ = data

 constructor.fromList bytes/List:
  header_ = Header.fromList bytes[1..] // skip protocol version
  data_ = Data.fromList bytes[1 + header_.size..]
  checksum_ = (bytes[bytes.size - 1] << 8) + bytes[bytes.size - 2]

 constructor.fromMessage msg/Message:
    header_ = Header.fromHeader msg.header
    data_ = Data.fromData msg.data
    checksum_ = msg.checksum_

 withRandomMsgId -> Message:
  randomUint32 := ( random 4_294_967_295) +1
  header.data.addDataUint32 Header.TYPE_MESSAGE_ID randomUint32
  return this

 msgId -> int?:
  if header.data.hasData Header.TYPE_MESSAGE_ID: return header.data.getDataUintn Header.TYPE_MESSAGE_ID
  return null

 msgType -> int:
  return header_.messageType_

 msgStatus -> int?:
  if header.data.hasData Header.TYPE_MESSAGE_STATUS: return header.data.getDataIntn Header.TYPE_MESSAGE_STATUS
  return null

 msgStatusIs status/int -> bool:
  return header.data.hasData Header.TYPE_MESSAGE_STATUS and (header.data.getDataIntn Header.TYPE_MESSAGE_STATUS) == status

 wasForwarded -> bool:
  return header_.data.hasData Header.TYPE_FORWARDED_FOR or header_.data.hasData Header.TYPE_FORWARDED_FOR_TYPE

 header -> Header:
  return header_  

 type -> int:
  return header_.messageType_

 data -> Data:
  return data_

 stringify -> string:
  // TODO make a much nicer stringify, including docs link, and stringified data?
  return stringifyAllBytes

 stringifyAllBytes -> string:
  buffer := io.Buffer
  is-first := true
  bytes.do:
    if is-first: is-first = false
    else: buffer.write ", "
    buffer.write "0x$(%02x it)"
  return buffer.to-string

 size -> int:
  // protocol, header, data, checksum
  return 1 + header_.size + data_.size +2

 // TODO remove this duplicate method...
 bytes -> ByteArray:
  return bytesForProtocol

 bytesForProtocol -> ByteArray:
  // first prep the message to be rendered as bytes
  // set the message length in the header
  header_.messageLength_ = size

  // set the checksum in the message
  checksum_ = checksumCalc

  // now render the message with the checksum
  return bytesEarly_

 checksumCalc -> int:
  preChcksumByteArray := bytesEarly_
  // Calculate CRC16 XMODEM over the bytes (without the last 2 which will be checksum)
  checksum := crc.crc16-xmodem (preChcksumByteArray.byte-slice 0 (preChcksumByteArray.byte-size - 2))
  return checksum

 // byteListEarly_ is a byteList, without length of checksum calculated
 bytesEarly_ -> ByteArray:
  bHeader := header_.bytesForProtocol
  bData := data_.bytesForProtocol

  b := ByteArray 1 + bHeader.size + bData.size + 2
  // first byte is protocol version
  b[0] = protocolVersion_
  // then header
  b.replace 1 bHeader 0 bHeader.size
  // then main data
  b.replace 1 + bHeader.size bData 0 bData.size
  // add checksum which is uint16 LE
  b.replace b.size - 2 #[checksum_ & 0xFF, checksum_ >> 8] 0 2
  return b