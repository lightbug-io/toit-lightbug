import .Data show *

class Header:
  messageLength_ /int := 0
  messageType_ /int := 0
  data_ /Data := Data

  constructor messageLength/int=0 messageType/int=0 data/Data=Data:
    messageLength_ = messageLength
    messageType_ = messageType
    data_ = data

  constructor.fromHeader header/Header:
    messageLength_ = header.messageLength_
    messageType_ = header.messageType_
    data_ = header.data_

  constructor.fromList bytes/List:
    // First is uint16 LE message length
    messageLength_ = bytes[0] + (bytes[1] << 8)
    // Second is uint16 LE message type
    messageType_ = bytes[2] + (bytes[3] << 8)
    // Third is data
    data_ = Data.fromList bytes[4..]

  stringify -> string:
    return "messageLength: " + messageLength_.stringify + ", messageType: " + messageType_.stringify + ", header data: " + data_.stringify

  messageType -> int:
    return messageType_

  size -> int:
    // length is uint16, type is uint16
    return 2 + 2  + data_.size

  data -> Data:
    return data_
  
  bytesForProtocol -> ByteArray:
    bData := data_.bytesForProtocol

    b := ByteArray 4 + bData.size
    // length is uint16 LE
    b[0] = messageLength_ & 0xFF
    b[1] = messageLength_ >> 8
    // type is uint 16 LE
    b[2] = messageType_ & 0xFF
    b[3] = messageType_ >> 8
    // data
    b.replace 4 bData 0 bData.size
    return b