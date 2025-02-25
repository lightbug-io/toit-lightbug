import crypto.crc
import io
import .header show *
import .data show *

class Message:
  protocolVersion_ /int := 3
  header_ /Header := Header
  data_ /Data := Data
  checksum_ /int := 0

  constructor message-type/int:
    header_.message-type_ = message-type

  constructor.with-data message-type/int data/Data:
    header_.message-type_ = message-type
    data_ = data

  constructor.from-list bytes/List:
    header_ = Header.from-list bytes[1..] // Skip protocol version.
    data_ = Data.from-list bytes[1 + header_.size..]
    checksum_ = (bytes[bytes.size - 1] << 8) + bytes[bytes.size - 2]

  constructor.from-message msg/Message:
    header_ = Header.from-header msg.header
    data_ = Data.from-data msg.data
    checksum_ = msg.checksum_

  with-random-msg-id -> Message:
    randomUint32 := ( random 4_294_967_295) +1
    header.data.add-data-uint32 Header.TYPE-MESSAGE-ID randomUint32
    return this

  msg-id -> int?:
    if header.data.has-data Header.TYPE-MESSAGE-ID: return header.data.get-data-uintn Header.TYPE-MESSAGE-ID
    return null

  msg-type -> int:
    return header_.message-type_

  msg-status -> int?:
    if header.data.has-data Header.TYPE-MESSAGE-STATUS: return header.data.get-data-intn Header.TYPE-MESSAGE-STATUS
    return null

  msg-status-is status/int -> bool:
    return header.data.has-data Header.TYPE-MESSAGE-STATUS and (header.data.get-data-intn Header.TYPE-MESSAGE-STATUS) == status

  was-forwarded -> bool:
    return header_.data.has-data Header.TYPE-FORWARDED-FOR or header_.data.has-data Header.TYPE-FORWARDED-FOR-TYPE

  header -> Header:
    return header_

  type -> int:
    return header_.message-type_

  data -> Data:
    return data_

  stringify -> string:
    // TODO make a much nicer stringify, including docs link, and stringified data?
    return stringify-all-bytes

  stringify-all-bytes -> string:
    buffer := io.Buffer
    is-first := true
    bytes.do:
      if is-first: is-first = false
      else: buffer.write ", "
      buffer.write "0x$(%02x it)"
    return buffer.to-string

  size -> int:
    // Protocol, header, data, checksum.
    return 1 + header_.size + data_.size +2

  // TODO remove this duplicate method...
  bytes -> ByteArray:
    return bytes-for-protocol

  bytes-for-protocol -> ByteArray:
    // First prep the message to be rendered as bytes.
    // Set the message length in the header.
    header_.message-length_ = size

    // Set the checksum in the message.
    checksum_ = checksum-calc

    // Now render the message with the checksum.
    return bytes-early_

  checksum-calc -> int:
    pre-checksum-byte-array := bytes-early_
    // Calculate CRC16 XMODEM over the bytes (without the last 2 which will be checksum).
    // No need to make a copy. A view is more efficient.
    checksum := crc.crc16-xmodem pre-checksum-byte-array[..pre-checksum-byte-array.size - 2]
    return checksum

  // byteListEarly_ is a byteList, without length of checksum calculated
  bytes-early_ -> ByteArray:
    bytes-header := header_.bytes-for-protocol
    bytes-data := data_.bytes-for-protocol

    b := ByteArray 1 + bytes-header.size + bytes-data.size + 2
    // First byte is protocol version.
    b[0] = protocolVersion_
    // Then header.
    b.replace 1 bytes-header
    // Then main data.
    b.replace 1 + bytes-header.size bytes-data
    // Add checksum which is uint16 LE.
    b.replace b.size - 2 #[checksum_ & 0xFF, checksum_ >> 8]
    return b
