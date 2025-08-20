import ..protocol as protocol

// Auto generated class for protocol message
class ButtonPress extends protocol.Data:

  static MT := 38
  static MT_NAME := "ButtonPress"

  static BUTTON-ID := 1
  static DURATION := 2

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  /**
  Creates a protocol.Data object with all available fields for this message type.
  
  This is a comprehensive helper that accepts all possible fields.
  For method-specific usage, consider using the dedicated request/response methods.
  
  Returns: A protocol.Data object with the specified field values
  */
  static data --button-id/int?=null --duration/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if button-id != null: data.add-data-uint BUTTON-ID button-id
    if duration != null: data.add-data-uint DURATION duration
    return data

  // Subscribe to a message with an optional interval in milliseconds
  static subscribe-msg --ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    if ms != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL ms
    return msg

  // UNSUBSCRIBE
  static unsubscribe-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  /**
    ID of the button, 0 indexed. Check device spec for button numbering
  */
  button-id -> int:
    return get-data-uint BUTTON-ID

  /**
    Duration of the button press in ms
  */
  duration -> int:
    return get-data-uint DURATION

  stringify -> string:
    return {
      "Button ID": button-id,
      "Duration": duration,
    }.stringify
