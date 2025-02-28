import .Data show *

class Header:
  // Header data types
  static TYPE_MESSAGE_ID := 1             // ID that can be used by receiver to ACK, and client to track for various responses, or re-sends
  static TYPE_CLIENT_ID := 2              // ID of the client sending the message
  static TYPE_RESPONSE_TO_MESSAGE_ID := 3 // ID of the message that is being responded to
  static TYPE_MESSAGE_STATUS := 4         // Status of the message. If omitted, assume OK?
  static TYPE_MESSAGE_METHOD := 5         // Request a service to be perform an action
  static TYPE_SUBSCRIPTION_INTERVAL := 6  // Interval in ms for a subscription to be sent
  static TYPE_FORWARDED_FOR_TYPE := 9
  static TYPE_FORWARDED_FOR := 10         // ID of the client sending the original message that is being forwarded
  static TYPE_FORWARDED_RSSI := 11        // RSSI of forwarded message
  static TYPE_FORWARDED_SNR := 12         // SNR of forwarded message
  static TYPE_FORWARD_TO_TYPE := 13       // Type of forwarded message
  static TYPE_FORWARD_TO := 14

  // For use with TYPE_MESSAGE_STATUS
  static STATUS_GENERIC_ERROR /int ::= 1
  static STATUS_MISSING_PARAMETER /int ::= 2
  static STATUS_METHOD_NOT_SUPPORTED /int ::= 3
  static STATUS_INVALID_PARAMETER /int ::= 4
  static STATUS_INVALID_STATE /int ::= 5
  static STATUS_NO_DATA /int ::= 6
  static STATUS_NOT_SUPPORTED /int ::= 7
  static STATUS_FAILED_WILL_RETRY /int ::= 8
  static STATUS_FAILED_PERMANENTLY /int ::= 9
  static STATUS_UNKNOWN_MESSAGE /int ::= 10

  static STATUS_MAP /Map := {
    STATUS_GENERIC_ERROR: "Generic error",
    STATUS_MISSING_PARAMETER: "Missing parameter",
    STATUS_METHOD_NOT_SUPPORTED: "Method not supported",
    STATUS_INVALID_PARAMETER: "Invalid parameter",
    STATUS_INVALID_STATE: "Invalid state",
    STATUS_NO_DATA: "No data",
    STATUS_NOT_SUPPORTED: "Not supported",
    STATUS_FAILED_WILL_RETRY: "Failed, will retry",
    STATUS_FAILED_PERMANENTLY: "Failed permanently",
    STATUS_UNKNOWN_MESSAGE: "Unknown message",
  }

  // For use with TYPE_MESSAGE_METHOD
  static METHOD_SET /int ::= 1
  static METHOD_GET /int ::= 2
  static METHOD_SUBSCRIBE /int ::= 3
  static METHOD_DO /int ::= 4

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