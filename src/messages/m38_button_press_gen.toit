import ..protocol as protocol

// Auto generated class for protocol message
class ButtonPress extends protocol.Data:

  static MT := 38
  static MT_NAME := "ButtonPress"

  static BUTTON-ID := 1
  static BUTTON-ID_ACTION := 0
  static BUTTON-ID_LEFT-UP := 1
  static BUTTON-ID_RIGHT-DOWN := 2

  static BUTTON-ID_STRINGS := {
    0: "Action",
    1: "Left Up",
    2: "Right Down",
  }

  static button-id-from-int value/int -> string:
    return BUTTON-ID_STRINGS.get value --if-absent=(: "unknown")

  static DURATION := 2

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  /**
   * Creates a protocol.Data object with all available fields for this message type.
   *
   * This is a comprehensive helper that accepts all possible fields.
   * For method-specific usage, consider using the dedicated request/response methods.
   *
   * Returns: A protocol.Data object with the specified field values
   */
  static data --button-id/int?=null --duration/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if button-id != null: data.add-data-uint BUTTON-ID button-id
    if duration != null: data.add-data-uint DURATION duration
    return data

  // Subscribe to a message with an optional interval in milliseconds
  static subscribe-msg --interval/int?=null --duration/int?=null --timeout/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    // Subscription header options - only add when provided
    if interval != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL interval
    if duration != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-DURATION duration
    if timeout != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-TIMEOUT timeout
    return msg

  /**
   * Creates a UNSUBSCRIBE Request message for Button Press.
   */
  
  /**
   * Returns: A Message ready to be sent
   */
  static unsubscribe-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-UNSUBSCRIBE base-data

  /**
   * ID of the button, 0 indexed. Check device spec for button numbering
   *
   * Valid values:
   * - BUTTON-ID_ACTION (0): Action button. RH2 Middle button.
   * - BUTTON-ID_LEFT-UP (1): Left / Up button. RH2 Left button.
   * - BUTTON-ID_RIGHT-DOWN (2): Right / Down button. RH2 Right button.
   */
  button-id -> int:
    return get-data-uint BUTTON-ID

  /**
   * Duration of the button press in ms
   */
  duration -> int:
    return get-data-uint DURATION

  stringify -> string:
    return {
      "Button ID": button-id,
      "Duration": duration,
    }.stringify
