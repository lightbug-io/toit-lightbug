import .data show *

class Header:
  // Header data types.
  static TYPE-MESSAGE-ID := 1             // ID that can be used by receiver to ACK, and client to track for various responses, or re-sends.
  static TYPE-CLIENT-ID := 2              // ID of the client sending the message.
  static TYPE-RESPONSE-TO-MESSAGE-ID := 3 // ID of the message that is being responded to.
  static TYPE-MESSAGE-STATUS := 4         // Status of the message. If omitted, assume OK?
  static TYPE-MESSAGE-METHOD := 5         // Request a service to be perform an action.
  static TYPE-SUBSCRIPTION-INTERVAL := 6  // Interval in ms for a subscription to be sent.
  static TYPE-FORWARDED-FOR-TYPE := 9
  static TYPE-FORWARDED-FOR := 10         // ID of the client sending the original message that is being forwarded.
  static TYPE-FORWARDED-RSSI := 11        // RSSI of forwarded message.
  static TYPE-FORWARDED-SNR := 12         // SNR of forwarded message.
  static TYPE-FORWARD-TO-TYPE := 13       // Type of forwarded message.
  static TYPE-FORWARD-TO := 14

  // For use with TYPE_MESSAGE_STATUS.
  static STATUS-GENERIC-ERROR /int ::= 1
  static STATUS-MISSING-PARAMETER /int ::= 2
  static STATUS-METHOD-NOT-SUPPORTED /int ::= 3
  static STATUS-INVALID-PARAMETER /int ::= 4
  static STATUS-INVALID-STATE /int ::= 5
  static STATUS-NO-DATA /int ::= 6
  static STATUS-NOT-SUPPORTED /int ::= 7
  static STATUS-FAILED-WILL-RETRY /int ::= 8
  static STATUS-FAILED-PERMANENTLY /int ::= 9
  static STATUS-UNKNOWN-MESSAGE /int ::= 10

  // For use with TYPE_MESSAGE_METHOD.
  static METHOD-SET /int ::= 1
  static METHOD-GET /int ::= 2
  static METHOD-SUBSCRIBE /int ::= 3
  static METHOD-DO /int ::= 4

  message-length_ /int := 0
  message-type_ /int := 0
  data_ /Data := Data

  constructor message-length/int=0 message-type/int=0 data/Data=Data:
    message-length_ = message-length
    message-type_ = message-type
    data_ = data

  constructor.from-header header/Header:
    message-length_ = header.message-length_
    message-type_ = header.message-type_
    data_ = header.data_

  constructor.from-list bytes/List:
    // First is uint16 LE message length
    message-length_ = bytes[0] + (bytes[1] << 8)
    // Second is uint16 LE message type
    message-type_ = bytes[2] + (bytes[3] << 8)
    // Third is data
    data_ = Data.from-list bytes[4..]

  stringify -> string:
    return "message-length: $message-length_, message-type: $message-type_, header data: $data"

  message-type -> int:
    return message-type_

  size -> int:
    // length is uint16, type is uint16
    return 2 + 2  + data_.size

  data -> Data:
    return data_

  bytes-for-protocol -> ByteArray:
    bytes-data := data_.bytes-for-protocol

    b := ByteArray 4 + bytes-data.size
    // length is uint16 LE
    b[0] = message-length_ & 0xFF
    b[1] = message-length_ >> 8
    // type is uint 16 LE
    b[2] = message-type_ & 0xFF
    b[3] = message-type_ >> 8
    // data
    b.replace 4 bytes-data 0 bytes-data.size
    return b
