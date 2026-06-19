import io.byte-order show LITTLE-ENDIAN
import .data show *

/**
Deprecated for new hot-path code. Prefer Message.header-* helpers for header
field reads/writes; parsed messages can answer those without allocating this
Header view. This class remains for compatibility and explicit materialized
header access.
*/
class Header:
  // Header data types
  static TYPE_MESSAGE_ID := 1             // ID that can be used by receiver to ACK, and client to track for various responses, or re-sends
  static TYPE_CLIENT_ID := 2              // ID of the client sending the message
  static TYPE_RESPONSE_TO_MESSAGE_ID := 3 // ID of the message that is being responded to
  static TYPE_MESSAGE_STATUS := 4         // Status of the message. If omitted, assume OK?
  static TYPE_MESSAGE_METHOD := 5         // Request a service to be perform an action
  static TYPE_SUBSCRIPTION_INTERVAL := 6  // Interval in ms for a subscription to be sent
  static TYPE_SUBSCRIPTION_DURATION := 7
  static TYPE_SUBSCRIPTION_TIMEOUT := 8
  static TYPE_FORWARDED_FOR_TYPE := 9
  static TYPE_FORWARDED_FOR := 10         // ID of the client sending the original message that is being forwarded
  static TYPE_FORWARDED_RSSI := 11        // RSSI of forwarded message
  static TYPE_FORWARDED_SNR := 12         // SNR of forwarded message
  static TYPE_FORWARD_TO_TYPE := 13       // Type of forwarded message
  static TYPE_FORWARD_TO := 14
  static TYPE_STORAGE_LEVEL := 15
  static TYPE_MESSAGE_LEVEL := 16

  // For use with TYPE_MESSAGE_STATUS
  static STATUS_OK /int ::= 0
  static STATUS_GENERIC_ERROR /int ::= 1
  static STATUS_MISSING_PARAMETER /int ::= 2
  static STATUS_METHOD_NOT_SUPPORTED /int ::= 3
  static STATUS_INVALID_PARAMETER /int ::= 4
  static STATUS_INVALID_STATE /int ::= 5
  static STATUS_NO_DATA /int ::= 6
  static STATUS_NOT_SUPPORTED /int ::= 7
  static STATUS_FAILED_WILL_RETRY /int ::= 8
  static STATUS_FAILED_PERMANENTLY /int ::= 9
  static STATUS_ABANDONED /int ::= 10
  static STATUS_EXPIRED /int ::= 11

  static STATUS_MAP /Map := {
    // null: "null", // TODO ask toit to fix this, as null cannot be .geted
    STATUS_OK: "OK",
    STATUS_GENERIC_ERROR: "Generic error",
    STATUS_MISSING_PARAMETER: "Missing parameter",
    STATUS_METHOD_NOT_SUPPORTED: "Method not supported",
    STATUS_INVALID_PARAMETER: "Invalid parameter",
    STATUS_INVALID_STATE: "Invalid state",
    STATUS_NO_DATA: "No data",
    STATUS_NOT_SUPPORTED: "Not supported",
    STATUS_FAILED_WILL_RETRY: "Failed, will retry",
    STATUS_FAILED_PERMANENTLY: "Failed permanently",
    STATUS_ABANDONED: "Abandoned",
    STATUS_EXPIRED: "Expired"
  }

  // For use with TYPE_MESSAGE_METHOD
  static METHOD_SET /int ::= 1
  static METHOD_GET /int ::= 2
  static METHOD_SUBSCRIBE /int ::= 3
  static METHOD_DO /int ::= 4
  static METHOD_UNSUBSCRIBE /int ::= 5

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

  constructor.from-bytes bytes/ByteArray:
    this.parse-into bytes 0

  constructor.from-bytes-at bytes/ByteArray offset/int:
    this.parse-into bytes offset

  parse-into bytes/ByteArray offset/int -> none:
    messageLength_ = LITTLE-ENDIAN.uint16 bytes offset
    messageType_ = LITTLE-ENDIAN.uint16 bytes (offset + 2)
    data_.parse-into bytes (offset + 4) // data

  stringify -> string:
    return "messageLength: " + messageLength_.stringify + ", messageType: " + messageType_.stringify + ", header data: " + data_.stringify

  message-type -> int:
    return messageType_

  size -> int:
    // length is uint16, type is uint16
    return 2 + 2  + data_.size

  data -> Data:
    return data_
  
  bytes-for-protocol -> ByteArray:
    b := ByteArray this.size
    write-bytes-for-protocol-into b 0
    return b

  write-bytes-for-protocol-into target/ByteArray offset/int -> int:
    LITTLE-ENDIAN.put-uint16 target offset messageLength_
    LITTLE-ENDIAN.put-uint16 target (offset + 2) messageType_
    return data_.write-bytes-for-protocol-into target (offset + 4) // data
