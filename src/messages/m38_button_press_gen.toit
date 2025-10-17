import ..protocol as protocol

// Auto generated class for protocol message
class ButtonPress extends protocol.Data:

  static MT := 38
  static MT_NAME := "ButtonPress"

  static BUTTON-ID := 1
  static BUTTON-ID_ACTION := 0
  static BUTTON-ID_UP_LEFT := 1
  static BUTTON-ID_DOWN_RIGHT := 2

  static BUTTON-ID_STRINGS := {
    0: "Action",
    1: "Up_Left",
    2: "Down_Right",
  }

  static button-id-from-int value/int -> string:
    return BUTTON-ID_STRINGS.get value --if-absent=(: "unknown")

  static DURATION := 2
  static PAGE-ID := 3
  static MENU-ITEM := 4

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
  static data --button-id/int?=null --duration/int?=null --page-id/int?=null --menu-item/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if button-id != null: data.add-data-uint BUTTON-ID button-id
    if duration != null: data.add-data-uint DURATION duration
    if page-id != null: data.add-data-uint PAGE-ID page-id
    if menu-item != null: data.add-data-uint MENU-ITEM menu-item
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
   *
   * Returns: A Message ready to be sent
   */
  static unsubscribe-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-UNSUBSCRIBE base-data

  /**
   * ID of the button.
   * Zero indexed.
   *
   * Devices may have buttons in different locations, however the following is a common layout:
   * 0 = Action button (usually center)
   * 1 = Left / Up button
   * 2 = Right / Down button
   *
   *
   * Valid values:
   * - BUTTON-ID_ACTION (0): Action
   * - BUTTON-ID_UP_LEFT (1): Up_Left
   * - BUTTON-ID_DOWN_RIGHT (2): Down_Right
   */
  button-id -> int:
    return get-data-uint BUTTON-ID

  /**
   * Duration of the button press in ms
   */
  duration -> int:
    return get-data-uint DURATION

  /**
   * ID of the page the button was on when pressed, if the device has a screen.
   */
  page-id -> int:
    return get-data-uint PAGE-ID

  /**
   * ID of the menu item the button was on when pressed, if the device has a screen and a menu was showing.
   * Zero indexed.
   */
  menu-item -> int:
    return get-data-uint MENU-ITEM

  stringify -> string:
    return {
      "Button ID": button-id,
      "Duration": duration,
      "Page ID": page-id,
      "Menu Item": menu-item,
    }.stringify
